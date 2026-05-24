# UpstreamProvider Reference

## Overview

An `UpstreamProvider` represents an external identity provider that Kubauth can delegate user authentication to. Each resource describes either:

- an **OIDC** provider (`type: oidc`) reachable through the standard authorization-code flow (Keycloak, Okta, Google Workspace, Microsoft Entra ID, …), or
- the **internal** login form (`type: internal`), which delegates authentication to the configured chain of internal identity providers (`ucrd`, `ldap`, `merger`).

When at least one `UpstreamProvider` exists, the Kubauth login page becomes a *provider chooser*. When none is defined, Kubauth falls back to an implicit `internal` provider.

See the [Upstream Providers](../30-user-guide/200-upstream-providers.md) chapter for end-to-end usage.

**API Group:** `kubauth.kubotal.io/v1alpha1`

**Kind:** `UpstreamProvider`

**Short names:** `upstreams`

**Namespaced:** Yes — resources are only watched in the namespace pointed at by the Helm value `oidc.upstreamProviderNamespace` (defaults to the Kubauth release namespace).

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
boolean - optional - default: `true`

Whether the provider is active. When set to `false`, the provider is hidden from the login page and rejected by the upstream callback. The resource appears in `OFF` status.

-----
### `type`
string - required

Provider type. One of:

- `oidc` — external OIDC server, fully described by `issuerURL`, `clientId`, `clientSecret` and friends.
- `internal` — the built-in login form, backed by the configured internal identity providers (`ucrd`, `ldap`, `merger`).

-----
### `displayName`
string - optional (required for `oidc` providers in practice)

Label shown to the user on the login page. For `oidc` providers this appears on the provider button (*"Sign in with ..."*). For `internal` providers this overrides the default form label (which otherwise comes from the Helm value `oidc.defaultLoginLabel`).

-----
### `clientSpecific`
boolean - optional - default: `false`

When `true`, the provider does not appear on the default login page. Only `OidcClient` resources that explicitly list it in [`spec.upstreamProviders`](110-oidcclient.md#upstreamproviders) will offer it to their users.

-----
### `issuerURL`
string - optional (required for `oidc` providers)

OIDC issuer URL. Kubauth performs the standard OIDC discovery on `${issuerURL}/.well-known/openid-configuration` unless `explicitConfig` is provided.

**Example:**
```yaml
issuerURL: "https://keycloak.mycompany.com/realms/default"
```

-----
### `certificateAuthority`
object - optional

PEM-encoded CA bundle used to verify TLS to the upstream issuer. Must reference a `ConfigMap` or `Secret` in the **same namespace** as the UpstreamProvider. Exactly one of `configMap` or `secret` must be set.

#### `certificateAuthority.configMap.name` / `.key`
string - required when `configMap` is used

Name of the `ConfigMap` and the key inside it holding the PEM bundle.

#### `certificateAuthority.secret.name` / `.key`
string - required when `secret` is used

Name of the `Secret` and the key inside it holding the PEM bundle.

**Example:**
```yaml
certificateAuthority:
  secret:
    name: certs-bundle
    key: ca.crt
```

-----
### `insecureSkipVerify`
boolean - optional - default: `false`

Skips TLS verification for the upstream issuer. For development environments only.

-----
### `redirectURL`
string - optional (required for `oidc` providers)

URL the upstream provider must redirect back to once the user has authenticated. Must match the redirect URI registered on the upstream side and is typically:

```
https://<kubauth-host>/upstream/callback
```

-----
### `clientId`
string - optional (required for `oidc` providers)

`client_id` registered on the upstream OIDC server for Kubauth.

-----
### `clientSecret`
secretRef - optional (required for non-public `oidc` providers)

Reference to a Kubernetes `Secret` in the same namespace, holding the upstream client secret.

#### `clientSecret.name`
string - required

Name of the `Secret`.

#### `clientSecret.key`
string - required

Key inside the `Secret`.

**Example:**
```yaml
clientSecret:
  name: upstream-keycloak
  key: clientSecret
```

-----
### `scopes`
[]string - optional

OIDC scopes requested when sending the user to the upstream provider.

**Example:**
```yaml
scopes:
  - openid
  - profile
  - groups
  - email
```

-----
### `useUserInfo`
boolean - optional - default: `false`

When `true`, Kubauth calls the upstream `userinfo` endpoint after the token exchange and merges its claims with the ID token claims. Useful for providers that put extra claims in `userinfo` rather than in the ID token (Keycloak with certain mappers, for example).

-----
### `claimRenamings`
[]ClaimRenamingSpec - optional

List of claim rename/copy operations applied to the upstream payload.

#### `claimRenamings[].oldName`
string - required

Source claim name.

#### `claimRenamings[].newName`
string - required

Target claim name.

#### `claimRenamings[].operation`
string - optional - default: `rename`

One of:

- `rename` — remove `oldName` and write the value under `newName`.
- `copy` — keep `oldName` *and* write the value under `newName`. Useful to derive a stable `sub` from `preferred_username`, for instance.

**Example:**
```yaml
claimRenamings:
  - oldName: preferred_username
    newName: sub
    operation: copy
  - oldName: realm_roles
    newName: roles
```

-----
### `claimRemovals`
[]string - optional

List of upstream claim names to drop before merging.

In addition, Kubauth always strips the "technical" OIDC ID-Token claims (`iss`, `aud`, `exp`, `iat`, `auth_time`, `nonce`, `acr`, `amr`, `azp`, `at_hash`, `c_hash`) from the upstream payload. The `sub` claim is preserved as the user identifier.

**Example:**
```yaml
claimRemovals:
  - email_verified
  - session_state
```

-----
### `localEnrichment`
boolean - optional - default: `true`

When `true`, Kubauth matches the upstream `sub` claim against a local `User` resource and merges any extra information found there (groups, emails, claims, ...). Set to `false` to suppress local enrichment for this provider.

-----
### `explicitConfig`
UpstreamProviderConfig - optional

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

**Example:**
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

-----
### `dumpExchanges`
boolean - optional - default: `false`

When `true`, every HTTP exchange between Kubauth and this upstream is dumped to the controller logs. Intended for debugging only.

## Status Fields

The controller maintains a status block exposing the result of the discovery / load process.

### `phase`
string

Lifecycle phase. One of:

| Phase   | Meaning                                                                              |
|---------|--------------------------------------------------------------------------------------|
| `READY` | The provider is loaded and ready to serve authentication requests.                   |
| `OFF`   | The provider is disabled (`spec.enabled: false`).                                    |
| `ERROR` | The provider could not be loaded (e.g. unreachable issuer, invalid secret).          |

### `message`
string

Human-readable explanation for the current phase (`OK` when ready, otherwise an error string).

### `effectiveConfig`
UpstreamProviderConfig

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

- [OidcClient](110-oidcclient.md) - References upstream providers through `spec.upstreamProviders`
- [User](120-user.md) - Targets of the `localEnrichment` lookup
- [Upstream Providers user guide](../30-user-guide/200-upstream-providers.md) - End-to-end walkthrough
