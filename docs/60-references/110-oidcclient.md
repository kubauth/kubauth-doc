# OidcClient Reference

## Overview

An `OidcClient` represents an OIDC client application that can authenticate users through Kubauth. In OIDC terminology, a client is an application that delegates user authentication to an OIDC server.

| Property      | Value                                                                                         |
|---------------|-----------------------------------------------------------------------------------------------|
| API Group     | `kubauth.kubotal.io`                                                                          |
| API Version   | `v1alpha1`                                                                                    |
| Kind          | `OidcClient`                                                                                  |
| Scope         | Namespaced (typically the Kubauth release namespace, or any tenant namespace)                 |
| Short names   | —                                                                                             |

## Example

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
metadata:
  name: my-app
  namespace: kubauth
spec:
  enabled: true
  redirectURIs:
    - "https://myapp.example.com/callback"
  grantTypes:
    - "refresh_token"
    - "authorization_code"
  responseTypes:
    - "code"
    - "id_token"
    - "token"
    - "id_token token"
    - "code id_token"
    - "code token"
    - "code id_token token"
  scopes:
    - "openid"
    - "profile"
    - "groups"
    - "email"
  description: "My Application"
  displayName: "My App"
  entryURL: "https://myapp.example.com"
  style: dark
  accessTokenLifespan: 1h
  idTokenLifespan: 1h
  refreshTokenLifespan: 8h
  public: false
  secrets:
    - name: oidc-my-app-client-secret
      key: clientSecret
      hashed: false
  upstreamProviders:
    - internal
    - corp-okta
```

## Spec Fields

### `enabled`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>true</code></span>
</p>

Whether the client is active. When set to `false`, the resource is kept in etcd but Kubauth rejects every OIDC request that uses this `client_id`. The client appears in `OFF` status.

```yaml
enabled: false
```

<hr class="api-field-separator">

### `secrets`

<p class="api-meta">
<span class="api-badge api-type">[]secretRef</span>
<span class="api-badge api-required">required if not <code>public</code></span>
</p>

A list of Kubernetes Secret references holding the `client_secret` value(s) accepted by the OIDC server.

The referenced Secrets must live in the **same namespace** as the OidcClient resource. Supporting multiple entries enables seamless secret rotation.

#### `secrets[].name`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required</span>
</p>

The name of the referenced Kubernetes Secret.

#### `secrets[].key`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required</span>
</p>

The key within the Secret that holds the client secret value.

#### `secrets[].hashed`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Set to `true` if the secret value is stored as a bcrypt hash instead of clear-text. Use the `kc hash <value> -r | base64` command to generate the hash from a plain-text secret.

```yaml
secrets:
  - name: oidc-my-app-client-secret-current
    key: clientSecret
  - name: oidc-my-app-client-secret-previous
    key: clientSecret
  - name: oidc-my-app-client-secret-hashed
    key: clientSecret
    hashed: true
```

<hr class="api-field-separator">

### `redirectURIs`

<p class="api-meta">
<span class="api-badge api-type">[]string</span>
<span class="api-badge api-required">required</span>
</p>

List of allowed redirect URIs for the OAuth2 authorization flow. After successful authentication, the authorization server will redirect the user back to one of these URIs.

For ROPC-only clients, this list may be empty but the field must be declared as `redirectURIs: []`.

```yaml
redirectURIs:
  - "https://myapp.example.com/callback"
  - "http://localhost:8080/callback"  # For local development
```

<hr class="api-field-separator">

### `grantTypes`

<p class="api-meta">
<span class="api-badge api-type">[]string</span>
<span class="api-badge api-required">required</span>
</p>

List of OAuth2 grant types that this client is allowed to use.

**Common values:**

- `authorization_code` — Standard OAuth2 authorization code flow
- `refresh_token` — Allows using refresh tokens to obtain new access tokens
- `client_credentials` — Machine-to-machine flow
- `password` — Resource Owner Password Credentials (ROPC) flow (must also be allowed globally with `oidc.allowPasswordGrant: true`)

```yaml
grantTypes:
  - "authorization_code"
  - "refresh_token"
```

<hr class="api-field-separator">

### `responseTypes`

<p class="api-meta">
<span class="api-badge api-type">[]string</span>
<span class="api-badge api-required">required</span>
</p>

List of response types the client can expect from the authorization endpoint.

**Common values:**

- `code` — Authorization code
- `token` — Access token (implicit flow)
- `id_token` — ID token
- `id_token token` — Both ID token and access token
- `code id_token` — Both code and ID token
- `code token` — Both code and access token
- `code id_token token` — All three

```yaml
responseTypes: [ "id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token" ]
```

<hr class="api-field-separator">

### `scopes`

<p class="api-meta">
<span class="api-badge api-type">[]string</span>
<span class="api-badge api-required">required</span>
</p>

List of OAuth2 scopes that this client can request.

**Standard OIDC scopes:**

- `openid` — Required for OIDC authentication
- `profile` — Access to user profile information
- `email` — Access to user email
- `offline` / `offline_access` — Request refresh tokens
- `groups` — Access to user group membership

```yaml
scopes:
  - "openid"
  - "profile"
  - "groups"
  - "email"
  - "offline_access"
```

<hr class="api-field-separator">

### `public`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Indicates whether this is a public client. Public clients do not require a client secret.

**Use for:** Browser-based applications, native mobile apps, CLI tools.

```yaml
public: true
```

<hr class="api-field-separator">

### `audiences`

<p class="api-meta">
<span class="api-badge api-type">[]string</span>
<span class="api-badge api-optional">optional</span>
</p>

Additional audiences (`aud` claim values) accepted for this client. The `client_id` is always implicitly included as an audience.

```yaml
audiences:
  - https://api.myapp.example.com
```

<hr class="api-field-separator">

### `forceOpenIdScope`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Force the `openid` scope even if the client application did not explicitly request it. Useful for clients that perform OAuth 2.0 flows but still expect an ID token.

<hr class="api-field-separator">

### `style`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>oidc.defaultStyle</code></span>
</p>

Name of the CSS theme to apply to the login, index and logout pages displayed during this client's flow. Allows per-client visual branding.

When omitted, the Helm value `oidc.defaultStyle` is used (`dark` by default).

```yaml
style: light
```

<hr class="api-field-separator">

### `upstreamProviders`

<p class="api-meta">
<span class="api-badge api-type">[]string</span>
<span class="api-badge api-optional">optional</span>
</p>

Names of the `UpstreamProvider` resources that should be offered to the user when signing in through this client.

Behavior:

- Empty / absent: every active, non-`clientSpecific` provider is presented (default).
- One entry: the login page is bypassed and the user is redirected straight to that provider.
- Multiple entries: only the listed providers are presented.
- Unknown or disabled entries are skipped and an event is recorded on the OidcClient resource.

See the [Upstream Providers](../30-user-guide/200-upstream-providers.md) chapter for the full picture.

```yaml
upstreamProviders:
  - internal
  - corp-okta
```

<hr class="api-field-separator">

### `postLogoutURL`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

Where to redirect the user after logout. Takes precedence over the global `oidc.postLogoutURL` Helm value. May still be overridden by a `post_logout_redirect_uri` query parameter on the logout URL.

```yaml
postLogoutURL: "https://myapp.example.com/logged-out"
```

<hr class="api-field-separator">

### `clientId`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

Explicit value of the OIDC `client_id`. When omitted, Kubauth derives a value automatically:

- The resource name, if the resource is defined in the **privileged namespace** (Helm value `oidc.clientPrivilegedNamespace`, defaults to the release namespace).
- `<namespace>-<resourceName>` in any other namespace, to prevent collisions across tenants.

!!! warning

    When you set `clientId` explicitly, no namespace decoration is applied. It is up to administrators to ensure uniqueness of the value across the cluster.

The **effective** client_id is always exposed in `.status.clientId`.

```yaml
clientId: prj32-public
```

<hr class="api-field-separator">

### `displayName`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

A user-friendly name for the application. Displayed on the Kubauth index page and logout page.

```yaml
displayName: "Employee Portal"
```

<hr class="api-field-separator">

### `description`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

A short description of the client application. Displayed on the Kubauth index page and logout page.

```yaml
description: "Corporate application for employee management"
```

<hr class="api-field-separator">

### `entryURL`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

The main entry URL for the application. Used to provide a link to the application on the Kubauth index page and logout page.

!!! note

    Requires `displayName` and `description` to also be set for the application to appear in the application list.

```yaml
entryURL: "https://portal.example.com"
```

<hr class="api-field-separator">

### `accessTokenLifespan`

<p class="api-meta">
<span class="api-badge api-type">duration</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>1h</code></span>
</p>

The lifespan of access tokens issued to this client. Format: Go duration string (e.g. `1m0s`, `1h`, `30m`).

```yaml
accessTokenLifespan: 15m
```

<hr class="api-field-separator">

### `idTokenLifespan`

<p class="api-meta">
<span class="api-badge api-type">duration</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>1h</code></span>
</p>

The lifespan of ID tokens issued to this client.

```yaml
idTokenLifespan: 1h
```

<hr class="api-field-separator">

### `refreshTokenLifespan`

<p class="api-meta">
<span class="api-badge api-type">duration</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>30d</code></span>
</p>

The lifespan of refresh tokens issued to this client.

```yaml
refreshTokenLifespan: 8h
```

## Status Fields

The controller maintains a small status block on every OidcClient resource. These fields are also surfaced as columns in `kubectl get oidcclients`.

### `phase`

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Lifecycle phase of the client. One of:

| Phase   | Meaning                                                                                          |
|---------|--------------------------------------------------------------------------------------------------|
| `READY` | The client is loaded and ready to serve OIDC requests.                                           |
| `OFF`   | The client is disabled (`spec.enabled: false`) and Kubauth will reject any request using it.    |
| `ERROR` | The client could not be loaded (e.g. missing client secret, invalid configuration).             |

<hr class="api-field-separator">

### `clientId`

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

The effective `client_id`, as derived from `spec.clientId`, the resource name and the privileged namespace rules described above. This is the value client applications must use.

<hr class="api-field-separator">

### `message`

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Human-readable explanation for the current phase. Set to `OK` when the client is ready, otherwise contains an error description (e.g. `unable to fetch secret 'kubauth:oidc-client-secret'`).

## Usage Notes

### Client ID

By default the OIDC `client_id` is derived from the resource name and the namespace, as described in the [`clientId`](#clientid) field above. The exact rule depends on the **privileged namespace**:

- Resources created in the privileged namespace (the Helm release namespace by default) use the bare resource name.
- Resources created in any other namespace are prefixed with `<namespace>-`.

### Namespacing

OidcClient resources can live in any namespace. The chart pre-creates the `kubauth-oidc-client-admin` ClusterRole, which allows tenant administrators to manage OidcClients restricted to their own namespace through a `RoleBinding`.

See the [OIDC Clients Configuration](../30-user-guide/115-oidc-clients-configuration.md) chapter for the multi-tenancy pattern.

### Security Considerations

**Public vs Confidential Clients:**

- Use `public: true` for applications that cannot securely store a secret (browsers, mobile apps, CLIs).
- Use the `secrets` list for server-side applications. Prefer `hashed: true` and rotate secrets by appending a new entry before removing the old one.

**Token Lifespans:**

- Shorter access token lifespans increase security but may impact performance.
- For kubectl integration, consider very short access tokens (1–5 minutes) with longer refresh tokens.

**Grant Types:**

- Only enable the grant types your application actually needs.
- The `password` grant type is deprecated. It must additionally be allowed globally with `oidc.allowPasswordGrant: true`.

### Application List Display

For an application to appear on the Kubauth index page (`https://kubauth.example.com/index`) and logout page, all three of the following fields must be set:

- `displayName`
- `description`
- `entryURL`

## Examples

### Public Client (Browser/CLI)

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
metadata:
  name: public
  namespace: kubauth
spec:
  redirectURIs:
    - "http://127.0.0.1:9921/callback"
  grantTypes:
    - "refresh_token"
    - "authorization_code"
  responseTypes:
    - "id_token"
    - "code"
  scopes:
    - "openid"
    - "profile"
    - "groups"
    - "email"
    - "offline_access"
  description: "Test public client"
  public: true
```

### Confidential Client (Server Application)

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: webapp-client-secret
  namespace: kubauth
type: Opaque
stringData:
  clientSecret: "aGoodSecret"

---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
metadata:
  name: webapp
  namespace: kubauth
spec:
  secrets:
    - name: webapp-client-secret
      key: clientSecret
  redirectURIs:
    - "https://webapp.example.com/callback"
  grantTypes:
    - "refresh_token"
    - "authorization_code"
  responseTypes:
    - "code"
  scopes:
    - "openid"
    - "profile"
    - "groups"
    - "email"
    - "offline_access"
  description: "Corporate Web Application"
  displayName: "Corporate Portal"
  entryURL: "https://webapp.example.com"
  accessTokenLifespan: 30m
  refreshTokenLifespan: 24h
```

### Kubernetes kubectl Client

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: k8s-client-secret
  namespace: kubauth
type: Opaque
stringData:
  clientSecret: "aGoodSecret"

---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
metadata:
  name: k8s
  namespace: kubauth
spec:
  secrets:
    - name: k8s-client-secret
      key: clientSecret
  description: "For kubernetes kubectl access"
  grantTypes:
    - "refresh_token"
    - "authorization_code"
    - "password"
  redirectURIs:
    - "http://localhost:8000"
    - "http://localhost:18000"
  responseTypes:
    - "id_token"
    - "code"
  scopes:
    - "openid"
    - "offline"
    - "profile"
    - "groups"
    - "email"
    - "offline_access"
  accessTokenLifespan: 1m
  idTokenLifespan: 1m
  refreshTokenLifespan: 30m
```

### Client Restricted to a Single Upstream Provider

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
metadata:
  name: corporate
  namespace: kubauth
spec:
  redirectURIs:
    - "https://corporate.example.com/callback"
  grantTypes:
    - "refresh_token"
    - "authorization_code"
  responseTypes:
    - "code"
  scopes:
    - "openid"
    - "profile"
    - "groups"
    - "email"
  description: "Corporate-only application"
  public: true
  upstreamProviders:
    - corp-okta
```
