# UpstreamProvider Reference

## Overview

An `UpstreamProvider` represents an external identity provider that Kubauth can delegate user authentication to. Each resource describes either:

- an **OIDC** provider (`type: oidc`) reachable through the standard authorization-code flow (Keycloak, Okta, Google Workspace, Microsoft Entra ID, …), or
- the **internal** login form (`type: internal`), which delegates authentication to the configured chain of internal identity providers (`ucrd`, `ldap`, `merger`).

When at least one `UpstreamProvider` exists, the Kubauth login page becomes a *provider chooser*. When none is defined, Kubauth falls back to an implicit `internal` provider.

See the [Upstream Providers](../30-user-guide/200-upstream-providers.md) chapter for end-to-end usage.

| Property      | Value                                                                                              |
|---------------|----------------------------------------------------------------------------------------------------|
| API Group     | `kubauth.kubotal.io`                                                                               |
| API Version   | `v1alpha1`                                                                                         |
| Kind          | `UpstreamProvider`                                                                                 |
| Scope         | Namespaced — only the namespace pointed at by `oidc.upstreamProviderNamespace` is watched          |
| Short names   | `upstreams`                                                                                        |

## Example

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: upstream-keycloak
  namespace: kubauth
type: Opaque
stringData:
  clientSecret: "aGoodSecret"

---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: UpstreamProvider
metadata:
  name: keycloak
  namespace: kubauth
spec:
  enabled: true
  type: oidc
  displayName: "Sign in with Keycloak"
  issuerURL: "https://keycloak.mycompany.com/realms/default"
  certificateAuthority:
    secret:
      name: certs-bundle
      key: ca.crt
  redirectURL: "https://kubauth.mycluster.mycompany.com/upstream/callback"
  clientId: kubauth-downstream
  clientSecret:
    name: upstream-keycloak
    key: clientSecret
  scopes:
    - openid
    - profile
    - groups
    - email
  useUserInfo: false
  claimRenamings:
    - oldName: preferred_username
      newName: sub
      operation: copy
  claimRemovals:
    - email_verified
  localEnrichment: true
```

## Spec Fields

### `enabled`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

Whether the provider is active. When set to `false`, the provider is hidden from the login page and rejected by the upstream callback. The resource appears in `OFF` status.

<hr class="api-field-separator">

### `type`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required</span>
</p>

Provider type. One of:

- `oidc` — external OIDC server, fully described by `issuerURL`, `clientId`, `clientSecret` and friends.
- `internal` — the built-in login form, backed by the configured internal identity providers (`ucrd`, `ldap`, `merger`).

<hr class="api-field-separator">

### `displayName`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

Label shown to the user on the login page. For `oidc` providers, this appears on the provider button (*"Sign in with ..."*) and is required in practice. For `internal` providers, this overrides the default form label (which otherwise comes from the Helm value `oidc.defaultLoginLabel`).

<hr class="api-field-separator">

### `clientSpecific`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

When `true`, the provider does not appear on the default login page. Only `OidcClient` resources that explicitly list it in [`spec.upstreamProviders`](110-oidcclient.md#upstreamproviders) will offer it to their users.

<hr class="api-field-separator">

### `issuerURL`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required for <code>oidc</code></span>
</p>

OIDC issuer URL. Kubauth performs the standard OIDC discovery on `${issuerURL}/.well-known/openid-configuration` unless `explicitConfig` is provided.

```yaml
issuerURL: "https://keycloak.mycompany.com/realms/default"
```

<hr class="api-field-separator">

### `certificateAuthority`

<p class="api-meta">
<span class="api-badge api-type">object</span>
<span class="api-badge api-optional">optional</span>
</p>

PEM-encoded CA bundle used to verify TLS to the upstream issuer. Must reference a `ConfigMap` or `Secret` in the **same namespace** as the UpstreamProvider. Exactly one of `configMap` or `secret` must be set.

#### `certificateAuthority.configMap.name` / `.key`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required when <code>configMap</code> is used</span>
</p>

Name of the `ConfigMap` and the key inside it holding the PEM bundle.

#### `certificateAuthority.secret.name` / `.key`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required when <code>secret</code> is used</span>
</p>

Name of the `Secret` and the key inside it holding the PEM bundle.

```yaml
certificateAuthority:
  secret:
    name: certs-bundle
    key: ca.crt
```

<hr class="api-field-separator">

### `insecureSkipVerify`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Skips TLS verification for the upstream issuer. For development environments only.

<hr class="api-field-separator">

### `redirectURL`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required for <code>oidc</code></span>
</p>

URL the upstream provider must redirect back to once the user has authenticated. Must match the redirect URI registered on the upstream side and is typically:

```
https://<kubauth-host>/upstream/callback
```

<hr class="api-field-separator">

### `clientId`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required for <code>oidc</code></span>
</p>

`client_id` registered on the upstream OIDC server for Kubauth.

<hr class="api-field-separator">

### `clientSecret`

<p class="api-meta">
<span class="api-badge api-type">secretRef</span>
<span class="api-badge api-required">required for non-public <code>oidc</code></span>
</p>

Reference to a Kubernetes `Secret` in the same namespace, holding the upstream client secret.

#### `clientSecret.name`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required</span>
</p>

Name of the `Secret`.

#### `clientSecret.key`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required</span>
</p>

Key inside the `Secret`.

```yaml
clientSecret:
  name: upstream-keycloak
  key: clientSecret
```

<hr class="api-field-separator">

### `scopes`

<p class="api-meta">
<span class="api-badge api-type">[]string</span>
<span class="api-badge api-optional">optional</span>
</p>

OIDC scopes requested when sending the user to the upstream provider.

```yaml
scopes:
  - openid
  - profile
  - groups
  - email
```

<hr class="api-field-separator">

### `useUserInfo`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

When `true`, Kubauth calls the upstream `userinfo` endpoint after the token exchange and merges its claims with the ID token claims. Useful for providers that put extra claims in `userinfo` rather than in the ID token (Keycloak with certain mappers, for example).

<hr class="api-field-separator">

### `claimRenamings`

<p class="api-meta">
<span class="api-badge api-type">[]ClaimRenamingSpec</span>
<span class="api-badge api-optional">optional</span>
</p>

List of claim rename/copy operations applied to the upstream payload.

#### `claimRenamings[].oldName`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required</span>
</p>

Source claim name.

#### `claimRenamings[].newName`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required</span>
</p>

Target claim name.

#### `claimRenamings[].operation`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>rename</code></span>
</p>

One of:

- `rename` — remove `oldName` and write the value under `newName`.
- `copy` — keep `oldName` *and* write the value under `newName`. Useful to derive a stable `sub` from `preferred_username`, for instance.

```yaml
claimRenamings:
  - oldName: preferred_username
    newName: sub
    operation: copy
  - oldName: realm_roles
    newName: roles
```

<hr class="api-field-separator">

### `claimRemovals`

<p class="api-meta">
<span class="api-badge api-type">[]string</span>
<span class="api-badge api-optional">optional</span>
</p>

List of upstream claim names to drop before merging.

In addition, Kubauth always strips the "technical" OIDC ID-Token claims (`iss`, `aud`, `exp`, `iat`, `auth_time`, `nonce`, `acr`, `amr`, `azp`, `at_hash`, `c_hash`) from the upstream payload. The `sub` claim is preserved as the user identifier.

```yaml
claimRemovals:
  - email_verified
  - session_state
```

<hr class="api-field-separator">

### `localEnrichment`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

When `true`, Kubauth matches the upstream `sub` claim against a local `User` resource and merges any extra information found there (groups, emails, claims, ...). Set to `false` to suppress local enrichment for this provider.

<hr class="api-field-separator">

### `explicitConfig`

<p class="api-meta">
<span class="api-badge api-type">UpstreamProviderConfig</span>
<span class="api-badge api-optional">optional</span>
</p>

When set, OIDC discovery is **disabled** for this provider and the values below are used instead. Useful for providers with broken discovery documents or for environments where the discovery endpoint is not reachable.

All fields are individually optional but the block is "all or nothing": if `explicitConfig` is set, no discovery is attempted.

| Field                                    | Description                                           |
|------------------------------------------|-------------------------------------------------------|
| `authorization_endpoint`                 | Authorization URL                                     |
| `token_endpoint`                         | Token URL                                             |
| `device_authorization_endpoint`          | Device authorization URL                              |
| `userinfo_endpoint`                      | UserInfo URL                                          |
| `jwks_uri`                               | JWKS URL                                              |
| `id_token_signing_alg_values_supported`  | List of supported ID token signing algorithms         |
| `introspection_endpoint`                 | Introspection URL                                     |
| `end_session_endpoint`                   | End-session URL (RP-initiated logout)                 |

```yaml
explicitConfig:
  authorization_endpoint: https://keycloak.mycompany.com/realms/master/protocol/openid-connect/auth
  token_endpoint:         https://keycloak.mycompany.com/realms/master/protocol/openid-connect/token
  userinfo_endpoint:      https://keycloak.mycompany.com/realms/master/protocol/openid-connect/userinfo
  jwks_uri:               https://keycloak.mycompany.com/realms/master/protocol/openid-connect/certs
  end_session_endpoint:   https://keycloak.mycompany.com/realms/master/protocol/openid-connect/logout
  id_token_signing_alg_values_supported:
    - RS256
```

<hr class="api-field-separator">

### `dumpExchanges`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

When `true`, every HTTP exchange between Kubauth and this upstream is dumped to the controller logs. Intended for debugging only.

## Status Fields

The controller maintains a status block exposing the result of the discovery / load process.

### `phase`

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Lifecycle phase. One of:

| Phase   | Meaning                                                                              |
|---------|--------------------------------------------------------------------------------------|
| `READY` | The provider is loaded and ready to serve authentication requests.                   |
| `OFF`   | The provider is disabled (`spec.enabled: false`).                                    |
| `ERROR` | The provider could not be loaded (e.g. unreachable issuer, invalid secret).          |

<hr class="api-field-separator">

### `message`

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Human-readable explanation for the current phase (`OK` when ready, otherwise an error string).

<hr class="api-field-separator">

### `effectiveConfig`

<p class="api-meta">
<span class="api-badge api-type">UpstreamProviderConfig</span>
</p>

The resulting endpoint configuration, either as discovered through `${issuerURL}/.well-known/openid-configuration` or as supplied via `spec.explicitConfig`. Convenient when troubleshooting upstream discovery.

## Usage Notes

### Where Upstream Providers Live

The OIDC controller watches `UpstreamProvider` resources in a **single namespace** — the one pointed at by `oidc.upstreamProviderNamespace` (defaults to the Helm release namespace). Resources created in other namespaces are ignored.

### Internal Provider

A single `internal` provider is special: it does not declare an issuer or credentials and simply enables the login form. It is automatically added by Kubauth when no `UpstreamProvider` exists at all, but you can also declare it explicitly to:

- pin a human-friendly label via `displayName`,
- disable it temporarily (`enabled: false`),
- exclude it from the default login page (`clientSpecific: true`).

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: UpstreamProvider
metadata:
  name: internal
  namespace: kubauth
spec:
  type: internal
  displayName: "Local administrators"
```

### Single-Provider Auto-Redirect

When a client is offered exactly one provider — either because the global list contains a single non-`clientSpecific` entry, or because the OidcClient's [`upstreamProviders`](110-oidcclient.md#upstreamproviders) list resolves to one entry — the login page is bypassed and the user is redirected straight to that provider.

### Listing Resources

```bash
kubectl -n kubauth get upstreamproviders
# or
kubectl -n kubauth get upstreams
```

## Examples

### Internal-Only

Equivalent to the historical Kubauth behavior (login form using the configured `ucrd` / `ldap` / `merger` chain):

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: UpstreamProvider
metadata:
  name: internal
  namespace: kubauth
spec:
  type: internal
  displayName: "Welcome"
```

### OIDC Provider with Discovery

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: upstream-okta
  namespace: kubauth
type: Opaque
stringData:
  clientSecret: "aGoodSecret"

---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: UpstreamProvider
metadata:
  name: corp-okta
  namespace: kubauth
spec:
  type: oidc
  displayName: "Sign in with Okta"
  issuerURL: "https://corp.okta.com"
  redirectURL: "https://kubauth.mycluster.mycompany.com/upstream/callback"
  clientId: kubauth
  clientSecret:
    name: upstream-okta
    key: clientSecret
  scopes:
    - openid
    - profile
    - groups
    - email
  useUserInfo: true
```

### OIDC Provider with Explicit Endpoints

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: UpstreamProvider
metadata:
  name: keycloak
  namespace: kubauth
spec:
  type: oidc
  displayName: "Sign in with Keycloak"
  issuerURL: "https://keycloak.mycompany.com/realms/default"
  redirectURL: "https://kubauth.mycluster.mycompany.com/upstream/callback"
  clientId: kubauth-downstream
  clientSecret:
    name: upstream-keycloak
    key: clientSecret
  scopes:
    - openid
    - profile
    - groups
  explicitConfig:
    authorization_endpoint: https://keycloak.mycompany.com/realms/default/protocol/openid-connect/auth
    token_endpoint:         https://keycloak.mycompany.com/realms/default/protocol/openid-connect/token
    userinfo_endpoint:      https://keycloak.mycompany.com/realms/default/protocol/openid-connect/userinfo
    jwks_uri:               https://keycloak.mycompany.com/realms/default/protocol/openid-connect/certs
    end_session_endpoint:   https://keycloak.mycompany.com/realms/default/protocol/openid-connect/logout
```

### Tenant-Specific Provider

A provider reserved for OidcClients that opt in:

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: UpstreamProvider
metadata:
  name: partner
  namespace: kubauth
spec:
  type: oidc
  displayName: "Sign in with Partner SSO"
  clientSpecific: true
  issuerURL: "https://idp.partner.com"
  redirectURL: "https://kubauth.mycluster.mycompany.com/upstream/callback"
  clientId: kubauth
  clientSecret:
    name: upstream-partner
    key: clientSecret
  scopes:
    - openid
    - profile
```

The corresponding `OidcClient` must reference it explicitly:

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
metadata:
  name: partner-portal
  namespace: kubauth
spec:
  upstreamProviders:
    - partner
  ....
```

## Related Resources

- [OidcClient](110-oidcclient.md) — References upstream providers through `spec.upstreamProviders`
- [User](120-user.md) — Targets of the `localEnrichment` lookup
- [Upstream Providers user guide](../30-user-guide/200-upstream-providers.md) — End-to-end walkthrough
