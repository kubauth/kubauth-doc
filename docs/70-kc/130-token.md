# kc token

## Overview

The `kc token` command obtains OIDC tokens using the authorization code flow with PKCE. It opens a browser for user authentication and returns access, refresh, and ID tokens.

## Syntax

```bash
kc token --issuerURL <url> --clientId <id> [options]
```

## Required Flags

### `--issuerURL` (string)
The Kubauth OIDC issuer URL.

**Example:** `--issuerURL https://kubauth.example.com`

### `--clientId` (string)
The OIDC client ID to use for authentication.

**Example:** `--clientId public`

## Optional Flags

### `--clientSecret` (string)
The client secret (for confidential clients).

**Example:** `--clientSecret mysecret123`

### `--insecureSkipVerify`
Skip TLS certificate verification. Use only for testing with self-signed certificates.

**Example:** `--insecureSkipVerify`

### `--onlyIDToken`
Output only the ID token (base64-encoded JWT). Useful for piping to other commands or scripts.

**Example:** `--onlyIDToken`

### `-d, --decode`
Decode and display the JWT token payload. This is a shortcut for `| kc jwt`.

**Example:** `-d`

### `--scopes` (string)
Comma-separated list of OAuth2 scopes to request.

**Default:** `openid,profile,email,groups,offline_access`

**Example:** `--scopes openid,profile,email`

## Examples

### Basic Usage

```bash
kc token --issuerURL https://kubauth.example.com --clientId public
```

**Output:**
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
kc token --issuerURL https://kubauth.example.com --clientId public --onlyIDToken
```

**Output:**
```
eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY3ZmY5MzUxMzZiMSIsInR5cCI6IkpXVCJ9.eyJhdF9oYXNoIjoiaGNBY2dtdmdBekJlSGgyODlkWHF3USIsImF1ZCI6WyJwdWJsaWMiXSwi...
```

### Pipe to JWT Decoder

```bash
kc token --issuerURL https://kubauth.example.com --clientId public --onlyIDToken | kc jwt
```

### With Confidential Client

```bash
kc token --issuerURL https://kubauth.example.com \
  --clientId webapp \
  --clientSecret myappsecret
```

### Skip TLS Verification (Testing Only)

```bash
kc token --issuerURL https://kubauth.local --clientId public --insecureSkipVerify
```

### Custom Scopes

```bash
kc token --issuerURL https://kubauth.example.com \
  --clientId public \
  --scopes openid,profile,email
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
ID_TOKEN=$(kc token --issuerURL https://kubauth.example.com --clientId public --onlyIDToken)

# Save to file
kc token --issuerURL https://kubauth.example.com --clientId public --onlyIDToken > token.txt
```

### SSO Session

If you previously checked "Remember me" on the login page, subsequent `kc token` commands will complete automatically without requiring you to log in again (SSO session active).

To clear the SSO session:

```bash
kc logout --issuerURL https://kubauth.example.com
```

## Use Cases

### Testing OIDC Configuration

```bash
# Quick test after setting up Kubauth
kc token --issuerURL https://kubauth.example.com --clientId public
```

### Inspecting User Claims

```bash
# View what claims are in your token
kc token --issuerURL https://kubauth.example.com --clientId public -d
```

### API Testing

```bash
# Get a token for API testing
TOKEN=$(kc token --issuerURL https://kubauth.example.com --clientId api-client --onlyIDToken)

# Use in API call
curl -H "Authorization: Bearer $TOKEN" https://api.example.com/endpoint
```

### Application Development

```bash
# Test your application's OIDC integration
kc token --issuerURL https://kubauth.example.com \
  --clientId myapp
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

### Certificate Errors

```bash
# For development/testing only
kc token --issuerURL https://kubauth.local --clientId public --insecureSkipVerify
```

**Better approach:** Add the CA certificate to your system trust store.

### Token Expired

Tokens have a limited lifespan. If you receive an expired token error, simply request a new token:

```bash
kc token --issuerURL https://kubauth.example.com --clientId public
```

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

