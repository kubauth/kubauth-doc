# kc token-nui

## Overview

The `kc token-nui` command obtains OIDC tokens using the Resource Owner Password Credentials (ROPC) flow. It prompts for username and password in the terminal without requiring a browser, making it suitable for headless environments, SSH sessions, and automation.
 
- The ID token signature is checked against the server key.
- If Access Token is in JWT form, its signature is checked against the server key.
- If Access Token is in opaque form, it is checked against server introspection endpoint.

> **NUI** stands for "No User Interface" (no browser).

## Syntax

```bash
kc token-nui --issuerURL <url> --clientId <id> [options]
```

## Prerequisites

The ROPC/Password Grant must be enabled in Kubauth:

1. **Global configuration:** Set `allowPasswordGrant: true` in Kubauth Helm values
2. **Client configuration:** Add `"password"` to the client's `grantTypes` list

See [Password Grant Configuration](../30-user-guide/160-password-grant.md#configuration) for details.

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
### `--login` (string)
Username for authentication. If not provided, you'll be prompted.

Value may also be fetched from `KC_USER_LOGIN` environment variable.

----
### `--password` (string)
Password for authentication. If not provided, you'll be prompted (input hidden).

Value may also be fetched from `KC_USER_PASSWORD` environment variable.

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

### Interactive Login

```bash
kc token-nui --issuerURL https://kubauth.example.com --clientId public
```

**Interaction:**

```
Login: john
Password: 
```

**Output:**

```
Access token: ory_at_LAhtO0e8T8-V2wLZ72V0G98jKMJEpYQLH6tm6Aeg_Lw...
Refresh token: ory_rt_kP1rTr6eF_AgdVvUtzfEKywhIddEK2cjDRC9EmkT0Hw...
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY...
Expire in: 1h0m0s
```

### Non-Interactive (Automation)

```bash
kc token-nui --issuerURL https://kubauth.example.com \
  --clientId public \
  --login john \
  --password john123
```

### With Token Decoding

```bash
kc token-nui --issuerURL https://kubauth.example.com \
  --clientId public \
  --login john \
  --password john123 \
  -d
```

### Only ID Token

```bash
kc token-nui --issuerURL https://kubauth.example.com \
  --clientId public \
  --login john \
  --password john123 \
  --onlyIdToken
```

### For CI/CD Pipelines

```bash
#!/bin/bash
TOKEN=$(kc token-nui \
  --issuerURL https://kubauth.example.com \
  --clientId automation \
  --login serviceaccount \
  --password $SERVICE_PASSWORD \
  --onlyIdToken)

curl -H "Authorization: Bearer $TOKEN" https://api.example.com/deploy
```


### Renewal

The OIDC client is configured with:

- `accessTokenLifespan: 30s`
- `refreshTokenLifespan: 30s`

```bash
kc token-nui  --issuerURL https://kubauth.example.com --clientId kc-test --ttl 1m
```

**output:**

```bash
Login:admin
Password:
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4ZWUtNDhlNS1hZDJiLW.................
Refresh token: ory_rt_smAzQrY5dtkxfSVdYTXf8HA42yOeXHsubruhT4TMiy8.GVAqyR78s12adQIQvw4rq8zFiakoyrk_gwzUHINCpCQ
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4ZWUtNDhlNS1hZDJiLWU5NDI.................
Expire in: 30s

Renewal loop started (ttl: 1m0s, renewAt: 60%, deadline: 2026-03-31T17:47:08+02:00)
Token lifetime: 30s, renewal in: 18s (at 17:46:26), expires at: 17:46:38
Waiting 18s before next renewal...

--- Renewal #1 at 2026-03-31T17:46:26+02:00 ---
Renewal #1 successful
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4ZWUtNDhlNS1hZDJiLWU5ND.................
Refresh token: ory_rt_44D98GD_NsQGcHEOrLEx7ydT8CcaL5nm3VkPQHK8tBg.boRkDPffu_vkn0s0hULXx7BgNoT6bRcMo6ff7QyJykc
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4ZWUtNDhlNS1hZDJiLWU5NDI3Y.................
Expire in: 30s
Token lifetime: 30s, renewal in: 18s (at 17:46:44), expires at: 17:46:56
Waiting 18s before next renewal...

--- Renewal #2 at 2026-03-31T17:46:44+02:00 ---
Renewal #2 successful
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4ZWUtNDhlNS1hZDJiLWU5.................
Refresh token: ory_rt_uftfqVe1JtCvL35wOZrdh2L1Q8ZZTxrSdcr7bl4a6hQ.6RSZz6-WV5C7uVxJJiSPTuo3_nb-fczIwTHYlE2N3e8
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4ZWUtNDhlNS1hZDJiLWU5NDI3YW.................
Expire in: 30s
Token lifetime: 30s, renewal in: 18s (at 17:47:02), expires at: 17:47:14
Waiting 18s before next renewal...

--- Renewal #3 at 2026-03-31T17:47:02+02:00 ---
Renewal #3 successful
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4ZWUtNDhlNS1hZDJiLWU5NDI3YWI3YjdlMCI.................
Refresh token: ory_rt_2I7g7UGrhVGh-p37licpl8G4Hb0M-owJV5rFwa1n4Mk.gXg8IopCJPlqhtnRyDDk_puU4NlhBK6N-srZ-AGDD_c
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4ZWUtNDhlNS1hZDJiLWU5NDI3YWI3YjdlMCIsInR5cCI.................
Expire in: 30s
Token lifetime: 30s, renewal in: 18s (at 17:47:20), expires at: 17:47:32
Next renewal would be past deadline, waiting 5s for TTL to expire...
TTL reached, exiting renewal loop
```

## Security Considerations

!!! warning "Password Grant Security"
    The password grant flow is deprecated in OAuth 2.1 due to security concerns:
    
    - Credentials are exposed to the client application
    - Cannot support phishing-resistant MFA
    - Users may be trained to enter passwords in applications
    
    Use only when browser-based flows are impossible.

## Troubleshooting

### Password Grant Not Allowed

**Error:**
```
token request failed with status 403: {"error":"request_forbidden","error_description":"The request is not allowed. This server does not allow to use authorization grant 'password'. Check server configuration"}
```

**Solution:** Enable password grant in both Kubauth configuration and the OidcClient. See [Password Grant Configuration](../30-user-guide/160-password-grant.md#configuration).


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

### Authentication Failed

**Error:**
```
token request failed with status 400: {"error":"invalid_grant","error_description":"...Unable to authenticate the provided username and password credentials."}
```

**Solutions:**

- Verify username and password are correct
- Check user is not disabled: `kubectl -n kubauth-users get user <username>`
- Review audit logs: `kc audit logins`

## Comparison with kc token

| Feature | `kc token` | `kc token-nui` |
|---------|-----------|----------------|
| Browser required | Yes | No |
| OAuth flow | Authorization Code + PKCE | Password Grant (ROPC) |
| SSH-friendly | No | Yes |
| Automation-friendly | Limited | Yes |
| MFA support | Yes | Limited |
| Security | Better | Acceptable for specific cases |
| Setup required | Standard OIDC | Must enable password grant |

## Related Commands

- [`kc token`](130-token.md) - Browser-based authentication (preferred)
- [`kc config`](190-config.md) - Configure kubectl with password grant
- [`kc jwt`](160-jwt.md) - Decode JWT tokens
- [`kc audit`](150-audit.md) - View authentication attempts

## See Also

- [Password Grant (ROPC)](../30-user-guide/160-password-grant.md)
- [Workstation Setup](../50-kubernetes-integration/140-workstation-setup.md#no-ui-mode)

