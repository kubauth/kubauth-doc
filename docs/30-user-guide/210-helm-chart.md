# Helm Chart Reference

This chapter is a guided reference of the **important values** exposed by the main `kubauth` Helm chart, plus a short presentation of the companion charts (`kubauth-users` and `kubauth-upstream-providers`).

It is not an exhaustive list of every knob — image overrides, resource limits, custom Kubernetes resource names, security contexts and similar operational settings are documented inline in the chart's `values.yaml` file. See:

[https://github.com/kubauth/kubauth/blob/main/helm/kubauth/values.yaml](https://github.com/kubauth/kubauth/blob/main/helm/kubauth/values.yaml){:target="_blank"}

## Overview

The `kubauth` chart packages the full Kubauth platform. It is structured as **one Deployment** running several co-located processes (modules), each one toggleable through its top-level Helm value:

| Helm key   | Module                  | Default  | Role                                                                         |
|------------|-------------------------|----------|------------------------------------------------------------------------------|
| `oidc`     | OIDC server             | enabled  | OAuth2/OIDC endpoints, login UI, SSO, OidcClient/UpstreamProvider controllers |
| `ucrd`     | User CRD controller     | enabled  | Watches `User`/`Group`/`GroupBinding` resources and acts as the local identity provider |
| `audit`    | Audit module            | enabled  | Records `LoginAttempt` resources for every authentication                    |
| `merger`   | Identity merger         | disabled | Combines multiple internal identity providers into a single identity         |
| `ldap`     | LDAP connector          | disabled | Internal identity provider backed by an LDAP/AD directory                    |

Each module is enabled by toggling `<module>.enabled: true|false`. The combinations covered by the rest of the user guide ([SSO](140-sso.md), [LDAP](170-ldap-connector.md), [Multiple Identity Providers](180-several-id-providers.md), [Identity Merging](190-identity-merging.md), [Upstream Providers](200-upstream-providers.md)) lay out which modules to activate for each scenario.

## Installing the Chart

See the [Installation](../20-installation.md) chapter for the full procedure. In a nutshell:

```bash
helm upgrade --install --create-namespace -n kubauth \
  kubauth oci://quay.io/kubauth/charts/kubauth \
  --version 0.3.0 \
  --values values.yaml
```

The remainder of this chapter walks through the values you are most likely to override in `values.yaml`.

## Top-Level Values

### `baseNameOverride`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

Base name used as prefix for all Kubernetes resources created by the chart (Deployment, Service, ConfigMap, etc.). Defaults to `<release-name>` (e.g. `kubauth`). Override when you want to deploy several Kubauth instances side by side or simply rename resources.

<hr class="api-field-separator">

### `deployInControlPlane`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

When `true`, applies a built-in `nodeSelector` and `tolerations` combination so the pod is scheduled on a control-plane node. Convenient on vanilla self-managed clusters where the API server can only reach pods on the control-plane network.

<hr class="api-field-separator">

### `nodeSelector`, `tolerations`, `affinity`

<p class="api-meta">
<span class="api-badge api-type">object</span>
<span class="api-badge api-optional">optional</span>
</p>

Standard Kubernetes scheduling knobs. `nodeSelector` and `tolerations` are ignored when `deployInControlPlane: true`.

<hr class="api-field-separator">

### `networkPolicies.enabled`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

When `false`, the chart does not create any NetworkPolicy. Use on clusters that do not run a NetworkPolicy controller.

<hr class="api-field-separator">

### `networkPolicies.forWebhooks` / `networkPolicies.ipBlock`

<p class="api-meta">
<span class="api-badge api-type">bool</span> / <span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

Controls the NetworkPolicy that allows the API server to reach the validating/mutating webhooks served by Kubauth. On multi-node clusters the API-server-to-pod traffic typically originates from the node network, so a CIDR must be supplied via `ipBlock` (e.g. `172.18.0.0/16` for KIND).

## OIDC Module (`oidc.*`)

This is the core module: it serves the OIDC endpoints (`/.well-known/openid-configuration`, `/oauth2/auth`, `/oauth2/token`, …), the login UI and the SSO session, and runs the `OidcClient` and `UpstreamProvider` controllers.

### `oidc.enabled`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

Activates the OIDC module. Disable only in very specific multi-Deployment topologies.

<hr class="api-field-separator">

### `oidc.issuer`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required</span>
</p>

Public OIDC issuer URL of this Kubauth deployment. Must match the hostname configured on the ingress and appear as the `iss` claim in every issued token.

```yaml
oidc:
  issuer: https://kubauth.mycluster.mycompany.com
```

<hr class="api-field-separator">

### `oidc.postLogoutURL`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

Default URL the user is redirected to after a logout. Can be overridden per-client via [`OidcClient.spec.postLogoutURL`](../60-references/110-oidcclient.md#postlogouturl), or per-request through the `post_logout_redirect_uri` query parameter.

<hr class="api-field-separator">

### `oidc.defaultStyle`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>dark</code></span>
</p>

Default CSS theme applied to the login, index and logout pages. Overridable per client through [`OidcClient.spec.style`](../60-references/110-oidcclient.md#style). Built-in values: `dark`, `light`.

<hr class="api-field-separator">

### `oidc.defaultLoginLabel`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>Welcome</code></span>
</p>

Label displayed above the login form when no `UpstreamProvider` is defined. Replaced by the `displayName` of the `internal` provider when one is configured.

<hr class="api-field-separator">

### `oidc.allowPasswordGrant`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Enables the Resource Owner Password Credentials (ROPC) flow globally. Individual clients must additionally list `password` in their `spec.grantTypes`. See [Password Grant (ROPC)](160-password-grant.md).

<hr class="api-field-separator">

### `oidc.enforcePKCE`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

When `true`, every authorization-code flow must use PKCE. Recommended for public-client deployments.

<hr class="api-field-separator">

### `oidc.jwtAccessToken`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

When `true`, access tokens are issued as JWTs (self-validating). When `false` (default), access tokens are opaque and must be validated via the `/oauth2/introspect` endpoint. See [Tokens and Claims](120-tokens-and-claims.md) for the trade-offs.

<hr class="api-field-separator">

### `oidc.clientPrivilegedNamespace`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: release namespace</span>
</p>

`OidcClient` resources created in this namespace get a bare `client_id` (no namespace prefix). Resources in any other namespace are prefixed with `<namespace>-`. Used for multi-tenant scenarios — see [OIDC Clients Configuration](115-oidc-clients-configuration.md).

<hr class="api-field-separator">

### `oidc.upstreamProviderNamespace`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: release namespace</span>
</p>

The single namespace watched by the OIDC controller for `UpstreamProvider` resources. Resources created elsewhere are silently ignored. See [Upstream Providers](200-upstream-providers.md).

### Server / Certificate (`oidc.server.*`)

#### `oidc.server.tls`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

Whether the OIDC server uses TLS. The default `true` should be kept in production: an OIDC server **must** be served over HTTPS.

<hr class="api-field-separator">

#### `oidc.server.certificateIssuer`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required when <code>tls: true</code></span>
</p>

Name of the cert-manager `Issuer` or `ClusterIssuer` used to issue the OIDC server certificate. The kind is selected with `oidc.server.issuerKind` below.

<hr class="api-field-separator">

#### `oidc.server.issuerKind`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>ClusterIssuer</code></span>
</p>

One of `ClusterIssuer`, `Issuer`. Selects whether `oidc.server.certificateIssuer` refers to a cluster-scoped or namespace-scoped issuer.

### Ingress (`oidc.ingress.*`)

#### `oidc.ingress.enabled`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

Whether the chart creates an `Ingress` resource for the OIDC server. Set to `false` when you manage ingress externally — see [Installation › Ingress Configuration](../20-installation.md#ingress-configuration).

<hr class="api-field-separator">

#### `oidc.ingress.class`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>nginx</code></span>
</p>

Value of `ingressClassName` set on the Ingress resource. Common alternatives: `haproxy`, `traefik`, etc.

<hr class="api-field-separator">

#### `oidc.ingress.host`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required when <code>ingress.enabled: true</code></span>
</p>

Hostname for the ingress rule. Must match the host portion of [`oidc.issuer`](#oidcissuer).

<hr class="api-field-separator">

#### `oidc.ingress.passthrough`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

When `true`, the ingress controller passes the raw TLS traffic to Kubauth (SSL passthrough). When `false`, the ingress controller terminates TLS itself and re-encrypts to the OIDC pod. See [Installation › Ingress Configuration](../20-installation.md#ingress-configuration) for details.

### SSO Session (`oidc.sso.*`)

See [SSO Session](140-sso.md) for the conceptual chapter.

#### `oidc.sso.mode`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>onDemand</code></span>
</p>

SSO session behavior. One of `onDemand` (user opts in via a checkbox), `always` (silent SSO), `never` (SSO disabled).

<hr class="api-field-separator">

#### `oidc.sso.sticky`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

When `true`, the SSO session is extended each time it is used (sliding window). When `false`, the session expires `lifeTime` after first sign-in regardless of activity.

<hr class="api-field-separator">

#### `oidc.sso.lifeTime`

<p class="api-meta">
<span class="api-badge api-type">duration</span>
<span class="api-badge api-default">default: <code>8h</code></span>
</p>

Maximum lifetime of an SSO session.

<hr class="api-field-separator">

#### `oidc.sso.cleanupPeriod`

<p class="api-meta">
<span class="api-badge api-type">duration</span>
<span class="api-badge api-default">default: <code>5m</code></span>
</p>

How often Kubauth scans for and deletes expired `SsoSession` resources.

### Logging & Debugging (`oidc.logger.*`, `oidc.dumpExchanges`)

#### `oidc.logger.mode`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>json</code></span>
</p>

Log format. One of `text`, `json`. Same convention is used for every other module (`audit.logger`, `merger.logger`, `ldap.logger`, `ucrd.logger`).

<hr class="api-field-separator">

#### `oidc.logger.level`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>info</code></span>
</p>

Log verbosity. One of `debug`, `info`, `warn`, `error`.

<hr class="api-field-separator">

#### `oidc.dumpExchanges`

<p class="api-meta">
<span class="api-badge api-type">int</span>
<span class="api-badge api-default">default: <code>0</code></span>
</p>

Dump every HTTP exchange handled by the OIDC server. One of `0` (off), `1` (short), `2` (full info), `3` (full JSON dump). Debugging only.

## UCRD Module (`ucrd.*`)

The UCRD module is the local identity provider backed by `User`/`Group`/`GroupBinding` custom resources. See [Users Configuration](110-users-configuration.md).

### `ucrd.enabled`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

Activates the UCRD module. Required when using `User` resources for identity (most deployments).

<hr class="api-field-separator">

### `ucrd.namespace`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>kubauth-users</code></span>
</p>

Namespace that holds the `User`, `Group` and `GroupBinding` resources.

<hr class="api-field-separator">

### `ucrd.createNamespace`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

When `true`, the chart creates `ucrd.namespace` if it does not exist already.

## Audit Module (`audit.*`)

See [Audit](130-audit.md) for the conceptual chapter.

### `audit.enabled`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

Activates the audit module. When disabled, no `LoginAttempt` resources are created.

<hr class="api-field-separator">

### `audit.namespace`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>kubauth-audit</code></span>
</p>

Namespace that holds the `LoginAttempt` resources.

<hr class="api-field-separator">

### `audit.createNamespace`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

When `true`, the chart creates `audit.namespace` if it does not exist already.

<hr class="api-field-separator">

### `audit.cleaner.recordLifetime`

<p class="api-meta">
<span class="api-badge api-type">duration</span>
<span class="api-badge api-default">default: <code>8h</code></span>
</p>

How long `LoginAttempt` resources are kept before being automatically deleted.

<hr class="api-field-separator">

### `audit.cleaner.cleanupPeriod`

<p class="api-meta">
<span class="api-badge api-type">duration</span>
<span class="api-badge api-default">default: <code>5m</code></span>
</p>

How often the cleaner scans for expired `LoginAttempt` resources.

## LDAP Connector (`ldap.*`)

The LDAP connector exposes an internal identity provider backed by an LDAP/AD directory. The values map one-to-one to the LDAP search and bind parameters. See [LDAP Connector](170-ldap-connector.md) for a full walkthrough.

### `ldap.enabled`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Activates the LDAP connector.

<hr class="api-field-separator">

### `ldap.ldap.host` / `ldap.ldap.port`

<p class="api-meta">
<span class="api-badge api-type">string</span> / <span class="api-badge api-type">int</span>
<span class="api-badge api-required">required when enabled</span>
</p>

LDAP server hostname and port. `port` defaults to `389` (plain/StartTLS) or `636` (LDAPS) based on the TLS configuration.

<hr class="api-field-separator">

### `ldap.ldap.bindDN` / `ldap.ldap.bindPW`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

Service account credentials used by the connector to search the directory. Omit for anonymous bind.

<hr class="api-field-separator">

### `ldap.ldap.insecureNoSSL`, `insecureSkipVerify`, `startTLS`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-optional">optional</span>
</p>

TLS handling for the LDAP connection:

- `insecureNoSSL: true` — plain LDAP over port 389. Use only for development.
- `startTLS: true` — connect plain, then upgrade to TLS via StartTLS.
- `insecureSkipVerify: true` — disable TLS server-certificate verification. Development only.

<hr class="api-field-separator">

### `ldap.ldap.rootCa{Data,Path,Secret}`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

Three mutually-exclusive ways to provide the LDAP server's CA bundle. `rootCaSecret` references a Kubernetes Secret (typically managed by [trust-manager](https://cert-manager.io/docs/trust/trust-manager/){:target="_blank"}) at key `rootCaSecretPath` (default `ca.crt`).

<hr class="api-field-separator">

### `ldap.ldap.userSearch.*` / `ldap.ldap.groupSearch.*`

<p class="api-meta">
<span class="api-badge api-type">object</span>
<span class="api-badge api-required">required when enabled</span>
</p>

LDAP search definitions for users and groups (base DN, filter, attribute mappings). See [LDAP Connector](170-ldap-connector.md) for a real-world example.

## Identity Merger (`merger.*`)

The merger combines several internal identity providers (typically `ucrd` + `ldap`) into a single identity. See [Identity Merging](190-identity-merging.md).

### `merger.enabled`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Activates the merger module. Required when both `ucrd` and `ldap` are enabled and you want their identities merged.

<hr class="api-field-separator">

### `merger.idProviders[]`

<p class="api-meta">
<span class="api-badge api-type">[]object</span>
<span class="api-badge api-required">required when enabled</span>
</p>

Ordered list of identity providers to merge, with per-provider authority weights and merge rules. Each entry has:

- `name` — provider name (`ucrd`, `ldap`, …).
- `httpConfig.baseURL` — internal URL of the provider.
- `credentialAuthority` — whether this provider is allowed to validate passwords.
- `groupAuthority` / `claimAuthority` / `nameAuthority` / `emailAuthority` — whether this provider contributes groups / claims / name / emails.
- `critical: true` — the user must exist on this provider, otherwise authentication fails.
- `groupPattern` / `claimPattern` — pattern applied to prefix group/claim names from this provider.

The full set of fields is documented in [Identity Merging](190-identity-merging.md).

## Companion Charts

The Kubauth platform ships two thin companion charts that simply wrap user-facing resources behind plain YAML. They are independent of the main `kubauth` chart and can be installed in any order.

### `kubauth-users`

Helm chart that creates `User`, `Group`, `GroupBinding`, `RoleBinding` and `ClusterRoleBinding` resources from plain Helm values. Convenient for bootstrapping a small static user base or for templating user definitions across environments.

```bash
helm upgrade --install --create-namespace -n kubauth-users \
  kubauth-users oci://quay.io/kubauth/charts/kubauth-users \
  --version 0.3.0 \
  --values values-users.yaml
```

Important values:

- `users[]` — list of `User` resources (`login`, `spec.passwordHash`, `spec.claims`, …).
- `groups[]` — list of `Group` resources.
- `groupBindings[]` — list of `GroupBinding` resources.
- `roleBindings[]` / `clusterRoleBindings[]` — Kubernetes RBAC bindings referencing users and groups.

See [Users Configuration › Helm Companion Chart](110-users-configuration.md#helm-companion-chart).

### `kubauth-upstream-providers`

Helm chart that creates `UpstreamProvider` resources from plain Helm values. Useful when you provision external IDPs (Keycloak, Okta, …) declaratively alongside the rest of the platform.

```bash
helm upgrade --install --create-namespace -n kubauth \
  kubauth-upstream-providers oci://quay.io/kubauth/charts/kubauth-upstream-providers \
  --version 0.3.0 \
  --values values-upstream.yaml
```

Important values:

- `upstreamProviders[]` — list of `UpstreamProvider` resources. Each entry mirrors the [`UpstreamProvider`](../60-references/150-upstreamprovider.md) CRD spec, with one extra convenience: `clientSecret` (clear-text) is accepted directly in addition to `clientSecretRef`.

See [Upstream Providers › Helm Companion Chart](200-upstream-providers.md#helm-companion-chart).

## Minimal `values.yaml`

A bare-bones production-ready installation needs only the issuer hostname, an ingress host and a TLS certificate issuer:

```yaml
oidc:
  issuer: https://kubauth.mycluster.mycompany.com
  ingress:
    host: kubauth.mycluster.mycompany.com
  server:
    certificateIssuer: letsencrypt
```

Everything else inherits sensible defaults.

## Annotated `values.yaml`

A more representative example for a multi-IdP deployment with ROPC enabled and JWT access tokens:

```yaml
oidc:
  issuer: https://kubauth.mycluster.mycompany.com

  # Allow ROPC globally; per-client opt-in still required via OidcClient.spec.grantTypes
  allowPasswordGrant: true

  # Self-validating access tokens
  jwtAccessToken: true

  # PKCE mandatory for every authorization-code flow
  enforcePKCE: true

  # Per-client styling default
  defaultStyle: light

  ingress:
    host: kubauth.mycluster.mycompany.com
    class: haproxy
    passthrough: false   # TLS terminated at the ingress controller

  server:
    certificateIssuer: letsencrypt

  sso:
    mode: onDemand
    lifeTime: 12h
    sticky: true

ucrd:
  enabled: true
  namespace: kubauth-users

audit:
  enabled: true
  cleaner:
    recordLifetime: 72h

ldap:
  enabled: true
  ldap:
    host: ldap.corp.example.com
    bindDN: cn=kubauth,ou=services,dc=corp,dc=example,dc=com
    bindPW: ${LDAP_BIND_PW}
    rootCaSecret: corp-ldap-ca
    userSearch:
      baseDN: ou=Users,dc=corp,dc=example,dc=com
      filter: (objectClass=inetOrgPerson)
      loginAttr: uid
      cnAttr: cn
      emailAttr: mail
      scope: sub
    groupSearch:
      baseDN: ou=Groups,dc=corp,dc=example,dc=com
      filter: (objectClass=groupOfNames)
      linkGroupAttr: member
      linkUserAttr: DN
      nameAttr: cn
      scope: sub

merger:
  enabled: true
  idProviders:
    - name: ucrd
      httpConfig:
        baseURL: http://localhost:6802
      credentialAuthority: true
      groupAuthority: true
      groupPattern: "%s"
      claimAuthority: true
      claimPattern: "%s"
      nameAuthority: true
      emailAuthority: true
      critical: false
    - name: ldap
      httpConfig:
        baseURL: http://localhost:6803
      credentialAuthority: true
      groupAuthority: true
      groupPattern: "ldap:%s"
      nameAuthority: true
      emailAuthority: true
      critical: false
```

## See Also

- [Installation](../20-installation.md) — Installation prerequisites and step-by-step procedure
- [Users Configuration](110-users-configuration.md) — `User`/`Group`/`GroupBinding` resources and the `kubauth-users` companion chart
- [OIDC Clients Configuration](115-oidc-clients-configuration.md) — `OidcClient` resources, privileged namespace, multi-tenancy
- [Tokens and Claims](120-tokens-and-claims.md) — JWT vs opaque access tokens, claim composition
- [Audit](130-audit.md) — `LoginAttempt` resources and retention
- [SSO Session](140-sso.md) — SSO modes and session lifecycle
- [LDAP Connector](170-ldap-connector.md) — Full LDAP setup
- [Identity Merging](190-identity-merging.md) — Combining multiple internal providers
- [Upstream Providers](200-upstream-providers.md) — External OIDC IdPs and the `kubauth-upstream-providers` chart
