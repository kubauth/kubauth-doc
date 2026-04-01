# kc token

## Overview

The `kc token` command obtains OIDC tokens using the authorization code flow. It opens a browser for user authentication and returns access, refresh, and ID tokens.

- The ID token signature is checked against the server key.
- If Access Token is in JWT form, its signature is checked against the server key.
- If Access Token is in opaque form, it is checked against server introspection endpoint.

## Syntax

```bash
kc token --issuerURL <url> --clientId <id> [options]
```

## Flags

### `--issuerURL`

The Kubauth OIDC issuer URL.

**Example:** `--issuerURL https://kubauth.example.com`

Value may also be fetched from `KC_ISSUER_URL` environment variable, or Kubernetes kubeconfig if `kc init ....` has been used.

-----
### `--clientId`

The OIDC client ID to use for authentication.

**Example:** `--clientId public`

Value may also be fetched from `KC_CLIENT_ID` environment variable, or Kubernetes kubeconfig if `kc init ....` has been used.

-----
### `--clientSecret`

The client secret (for confidential clients).

**Example:** `--clientSecret mysecret123`

Value may also be fetched from `KC_CLIENT_SECRET` environment variable, or Kubernetes kubeconfig if `kc init ....` has been used.

-----
### `--insecureSkipVerify`
Skip TLS certificate verification. Use only for testing with self-signed certificates.

**Example:** `--insecureSkipVerify`

-----
### `--caFile`
Provide a CA file for TLS certificate verification of ìssuerURL

**Example:** `--caFile ./CA.crt`

-----
### `--onlyIdToken`
Output only the ID token (base64-encoded JWT). Useful for piping to other commands or scripts.

**Example:** `--onlyIdToken`

-----
### `--onlyAccessToken`
Output only the access token (base64-encoded). Useful for piping to other commands or scripts.

**Example:** `--onlyAccessToken`

-----
### `-d`, `--detailIdToken`
Decode and display the JWT OIDC token payload. This is equivalent to `kc token .... --onlyIdToken | kc jwt`.

**Example:** `-d`

-----
### `-a`, `--detailAccessToken`
Decode and display the JWT Access token payload. This is equivalent to `kc token .... --onlyAccessToken | kc jwt`.

**Example:** `-a`

> The Kubauth server must be configured to generate AccessToken in JWT form.

-----
### `--scope`
List of OAuth2 scopes to request.

**Default:** `openid profile groups offline`

**Example:** `--scope "openid" --scope "profile" --scope "email" --scope "groups"`

!!! warning

    In its current version, Kubauth does not manage scopes. All claims are included in the JWT token.

-----
### `-p`, `bindPort`

Local web server bind port.

**Default:** 9921

-----
### `--pkce`

Use PKCE (Proof Key for Code Exchange) for enhanced security.

----
### `--browser`

Override default browser. Possible values: 

- `chrome`
- `firefox`
- `safari`

---
### `--ttl` 

Instead of ending immediately, the command enter a loop ending after this duration value. 

During this period, it will exercise the renewal of the Access Token

**Default:** 0

**Example**: `--ttl 30m`

---
### `--renewAt`

The threshold percentage of the token's life before renewal is initiated.

**Example**: `--renewAt 50`  # Renewal will be triggered halfway through the access token's lifespan.

## Examples

### Basic Usage

```bash
kc token --issuerURL https://kubauth.example.com --clientId public
```

**output:**
```
if browser doesn't open automatically, visit: http://127.0.0.1:9921
```

**Output:** (After successful login)
```
Access token: ory_at_xLUfAhEGpFVWpMLdNEDZAj94hHFrHWjgOYB5g0Leh_k...
Refresh token: ory_rt_nU9NBZs4NtKTxVYVko1aqlJkAMF5MLBYjfiZbhVt9aE...
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY...
Expire in: 59m59s
```

### With Decoded Token

```bash
kc token --issuerURL https://kubauth.example.com --clientId public -d
```

**Output:**
```
Access token: ory_at_...
Refresh token: ory_rt_...
ID token: eyJhbG...
Expire in: 59m59s
JWT Payload:
{
  "aud": ["public"],
  "auth_time": 1763573723,
  "auth_time_human": "2025-11-19 17:35:23 UTC",
  "azp": "public",
  "email": "john@example.com",
  "emails": ["john@example.com"],
  "exp": 1763577323,
  "exp_human": "2025-11-19 18:35:23 UTC",
  "groups": ["developers", "ops"],
  "iat": 1763573723,
  "iat_human": "2025-11-19 17:35:23 UTC",
  "iss": "https://kubauth.example.com",
  "name": "John DOE",
  "sub": "john"
}
```

### Only ID Token (for Piping)

```bash
kc token --issuerURL https://kubauth.example.com --clientId public --onlyIdToken
```

**Output:**
```
eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY3ZmY5MzUxMzZiMSIsInR5cCI6IkpXVCJ9.eyJhdF9oYXNoIjoiaGNBY2dtdmdBekJlSGgyODlkWHF3USIsImF1ZCI6WyJwdWJsaWMiXSwi...
```

### Pipe to JWT Decoder

```bash
kc token --issuerURL https://kubauth.example.com --clientId public --onlyIdToken | kc jwt
```

### Renewal

The OIDC client is configured with:

- `accessTokenLifespan: 30s`
- `refreshTokenLifespan: 30s`

```bash
kc token --issuerURL https://kubauth.example.com --clientId kc-test --ttl 1m10s
```

**output:**

```bash
If browser doesn't open automatically, visit: http://127.0.0.1:9921
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1N.............
Refresh token: ory_rt_L5R5G3kTb5sEZOTCxz_J121GA59ogeYoe1xJXJXSyAM.YCfxq0uc4YVQ566WPPEwaXh-_YL5pAiy6xa7a79GHFw
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3.............
Expire in: 29s

Renewal loop started (ttl: 1m10s, renewAt: 60%, deadline: 2026-03-31T17:36:15+02:00)
Token lifetime: 29s, renewal in: 17s (at 17:35:22), expires at: 17:35:34
Waiting 17s before next renewal...

--- Renewal #1 at 2026-03-31T17:35:22+02:00 ---
Renewal #1 successful
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1N.............
Refresh token: ory_rt_oQybFhJPQO-eI0xuu77kdCS9rpY8xAcoExFJODMyNvo.Fydp0sV5beCqLwG1MA11FN2yzi2PtRAWhFoPO6BB0Vw
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M..............
Expire in: 30s
Token lifetime: 30s, renewal in: 18s (at 17:35:40), expires at: 17:35:52
Waiting 18s before next renewal...

--- Renewal #2 at 2026-03-31T17:35:40+02:00 ---
Renewal #2 successful
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1L.............
Refresh token: ory_rt_qcpmGnDVMU8NvLEzjOl24xzGRx3MUca87QAjLHzDBnM.LPb0LDWuLNPxQrquv2dqrRq1onnBY4wE_IXGMAN55Hg
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4Z.............
Expire in: 30s
Token lifetime: 30s, renewal in: 18s (at 17:35:58), expires at: 17:36:10
Waiting 18s before next renewal...

--- Renewal #3 at 2026-03-31T17:35:58+02:00 ---
Renewal #3 successful
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3.............
Refresh token: ory_rt_m3OcpGHUkBf651qUFCzuqm-7y7Q17852QQzHOl3fOZE.vD7m3vu13p_TKf9VK5c5iekB3CZUxkhzMv82Nilhrdw
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M.............
Expire in: 30s
Token lifetime: 30s, renewal in: 18s (at 17:36:16), expires at: 17:36:28
Next renewal would be past deadline, waiting 16s for TTL to expire...
TTL reached, exiting renewal loop
```


## Behavior

### Browser Flow

1. **Local Server Started** - `kc` starts a local HTTP server on a localhost port
2. **Browser Opens** - Your default browser opens to the Kubauth login page
3. **User Authenticates** - You log in with your credentials
4. **Callback Received** - Kubauth redirects back to the local server with an authorization code
5. **Token Exchange** - `kc` exchanges the code for tokens
6. **Display Results** - Tokens are displayed in the terminal

### Token Storage

Tokens are displayed but not automatically stored. If you need to save them:

```bash
# Save ID token to variable
ID_TOKEN=$(kc token --issuerURL https://kubauth.example.com --clientId public --onlyIdToken)

# Save to file
kc token --issuerURL https://kubauth.example.com --clientId public --onlyIdToken > token.txt
```

### SSO Session

If you previously checked "Remember me" on the login page, subsequent `kc token` commands will complete automatically without requiring you to log in again (SSO session active).

To clear the SSO session:

```bash
kc logout --issuerURL https://kubauth.example.com
```

## Troubleshooting

### Browser Doesn't Open

If the browser doesn't open automatically:

1. Check the terminal output for the URL
2. Manually copy and paste it into your browser
3. Or use [`kc token-nui`](140-token-nui.md) for terminal-based authentication

**Example:**
```
If browser doesn't open automatically, visit: http://127.0.0.1:9921
```

### TLS Certificate Errors

**Error:**
```
Error: x509: certificate signed by unknown authority
```

**Solutions:**

- Use `--insecureSkipVerify` for testing (not recommended for production)
- Use `--caFile ./ca.crt`. To extract the CA:
   ```bash
   kubectl -n kubauth get secret kubauth-oidc-server-cert \
     -o=jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
   ```
- Add this CA certificate to system trust store.

## Security Considerations

1. **Don't Expose Tokens** - Be careful when displaying or logging tokens
2. **Use HTTPS** - Always use HTTPS for the issuer URL in production
3. **Verify Certificates** - Only use `--insecureSkipVerify` for testing
4. **Token Lifetime** - Tokens expire quickly by design; request new ones as needed
5. **Client Secrets** - Never commit client secrets to version control

## Related Commands

- [`kc token-nui`](140-token-nui.md) - Non-interactive authentication (no browser)
- [`kc jwt`](160-jwt.md) - Decode JWT tokens
- [`kc logout`](180-logout.md) - Clear SSO session
- [`kc whoami`](170-whoami.md) - Display current user information

## See Also

- [Tokens and Claims](../30-user-guide/120-tokens-and-claims.md)
- [OidcClient Reference](../60-references/110-oidcclient.md)

