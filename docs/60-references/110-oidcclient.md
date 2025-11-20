# OidcClient Reference

## Overview

An `OidcClient` represents an OIDC client application that can authenticate users through Kubauth. In OIDC terminology, a client is an application that delegates user authentication to an OIDC server.

**API Group:** `kubauth.kubotal.io/v1alpha1`

**Kind:** `OidcClient`

**Namespaced:** Yes (typically `kubauth-oidc`)

## Example

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
metadata:
  name: my-app
  namespace: kubauth-oidc
spec:
  hashedSecret: "$2a$12$..."
  redirectURIs:
    - "https://myapp.example.com/callback"
  grantTypes:
    - "refresh_token"
    - "authorization_code"
  responseTypes:
    - "code"
    - "id_token"
  scopes:
    - "openid"
    - "profile"
    - "groups"
    - "email"
  description: "My Application"
  displayName: "My App"
  entryURL: "https://myapp.example.com"
  accessTokenLifespan: 1h
  idTokenLifespan: 1h
  refreshTokenLifespan: 8h
```

## Spec Fields

### Required Fields

#### `redirectURIs` ([]string)
List of allowed redirect URIs for the OAuth2 authorization flow. After successful authentication, the authorization server will redirect the user back to one of these URIs.

**Example:**
```yaml
redirectURIs:
  - "https://myapp.example.com/callback"
  - "http://localhost:8080/callback"  # For local development
```

#### `grantTypes` ([]string)
List of OAuth2 grant types that this client is allowed to use.

**Possible values:**

- `authorization_code` - Standard OAuth2 authorization code flow
- `refresh_token` - Allows using refresh tokens to obtain new access tokens
- `password` - Resource Owner Password Credentials (ROPC) flow (must be explicitly enabled)

**Example:**
```yaml
grantTypes:
  - "authorization_code"
  - "refresh_token"
```

#### `responseTypes` ([]string)
List of response types the client can expect from the authorization endpoint.

**Common values:**

- `code` - Authorization code
- `token` - Access token (implicit flow)
- `id_token` - ID token
- `id_token token` - Both ID token and access token
- `code id_token` - Both code and ID token
- `code token` - Both code and access token
- `code id_token token` - All three

**Example:**
```yaml
responseTypes:
  - "code"
  - "id_token"
```

#### `scopes` ([]string)
List of OAuth2 scopes that this client can request.

**Standard OIDC scopes:**

- `openid` - Required for OIDC authentication
- `profile` - Access to user profile information
- `email` - Access to user email
- `offline` / `offline_access` - Request refresh tokens
- `groups` - Access to user group membership

**Example:**
```yaml
scopes:
  - "openid"
  - "profile"
  - "groups"
  - "email"
  - "offline_access"
```

### Optional Fields

#### `hashedSecret` (string)
The hashed client secret for confidential clients. Use the `kc hash` command to generate the hash from a plain-text secret.

**Note:** Omit this field for public clients (see `public` field below).

**Example:**
```yaml
hashedSecret: "$2a$12$..."
```

#### `public` (boolean)
Indicates whether this is a public client. Public clients do not require a client secret.

**Default:** `false`

**Use for:** Browser-based applications, native mobile apps, CLI tools

**Example:**
```yaml
public: true
```

#### `description` (string)
A description of the client application for administrative purposes.

**Example:**
```yaml
description: "Internal corporate application for employee management"
```

#### `displayName` (string)
A user-friendly name for the application. This is displayed on the Kubauth index page and logout page.

**Example:**
```yaml
displayName: "Employee Portal"
```

#### `entryURL` (string)
The main entry URL for the application. Used to provide a link to the application on the Kubauth index page and logout page.

**Note:** Requires `displayName` and `description` to be set for the application to appear in the application list.

**Example:**
```yaml
entryURL: "https://portal.example.com"
```

#### `accessTokenLifespan` (duration)
The lifespan of access tokens issued to this client.

**Default:** Server default (typically 1 hour)

**Format:** Duration string (e.g., `1m0s`, `1h`, `30m`)

**Example:**
```yaml
accessTokenLifespan: 15m
```

#### `idTokenLifespan` (duration)
The lifespan of ID tokens issued to this client.

**Default:** Server default (typically 1 hour)

**Format:** Duration string (e.g., `1m0s`, `1h`, `30m`)

**Example:**
```yaml
idTokenLifespan: 1h
```

#### `refreshTokenLifespan` (duration)
The lifespan of refresh tokens issued to this client.

**Default:** Server default (typically several hours)

**Format:** Duration string (e.g., `1h`, `8h`, `24h`)

**Example:**
```yaml
refreshTokenLifespan: 8h
```

## Status Fields

The `OidcClient` resource does not currently expose status fields. The resource is ready to use immediately after creation.

## Usage Notes

### Client ID

The client ID is derived from the resource name in the metadata section. This is what client applications use to identify themselves to the OIDC server.

### Namespacing

`OidcClient` resources are typically created in the `kubauth-oidc` namespace, though this can be configured via Helm chart values.

### Security Considerations

1. **Public vs Confidential Clients:**
   - Use `public: true` for applications that cannot securely store a secret (browsers, mobile apps, CLIs)
   - Use `hashedSecret` for server-side applications that can securely store credentials

2. **Token Lifespans:**
   - Shorter access token lifespans increase security but may impact performance
   - Balance security requirements with user experience
   - For kubectl integration, consider very short access tokens (1-5 minutes) with longer refresh tokens

3. **Grant Types:**
   - Only enable the grant types your application actually needs
   - The `password` grant type is deprecated and disabled by default - use only for specific use cases

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
  namespace: kubauth-oidc
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
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
metadata:
  name: webapp
  namespace: kubauth-oidc
spec:
  hashedSecret: "$2a$12$..."
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
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
metadata:
  name: k8s
  namespace: kubauth-oidc
spec:
  hashedSecret: "$2a$12$..."
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

## Related Resources

- [User](./120-user.md) - User accounts that authenticate through clients
- [Group](./130-group.md) - User groups for authorization
- [GroupBinding](./140-groupbinding.md) - Associates users with groups

