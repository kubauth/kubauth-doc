# kc token-nui

## Overview

The `kc token-nui` command obtains OIDC tokens using the Resource Owner Password Credentials (ROPC) flow. It prompts for username and password in the terminal without requiring a browser, making it suitable for headless environments, SSH sessions, and automation.

**NUI** stands for "No User Interface" (no browser).

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

Value may also be fetched from `KC_CLIENT_ID` environment variable, or Kubernetes kubeconfig if `kc init ....` has been used.

-----
### `--insecureSkipVerify`
Skip TLS certificate verification. Use only for testing with self-signed certificates.

**Example:** `--insecureSkipVerify`

-----
### `--caFile`
Provide a CA file for TLS certificate verification of ìssuerURL

**Example:** `--caFile ./CA.crt`

-----
### `--onlyIDToken`
Output only the ID token (base64-encoded JWT). Useful for piping to other commands or scripts.

**Example:** `--onlyIDToken`

-----
### `--onlyAccessToken`
Output only the access token (base64-encoded). Useful for piping to other commands or scripts.

**Example:** `--onlyAccessToken`

-----
### `-d`, `--detailIDToken`
Decode and display the JWT token payload. This is a shortcut for `| kc jwt`.

**Example:** `-d`

-----
### `--scopes`
Comma-separated list of OAuth2 scopes to request.

**Default:** `openid,profile,groups,offline`

**Example:** `--scopes openid,profile,email,groups`

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
  --onlyIDToken
```

### For CI/CD Pipelines

```bash
#!/bin/bash
TOKEN=$(kc token-nui \
  --issuerURL https://kubauth.example.com \
  --clientId automation \
  --login serviceaccount \
  --password $SERVICE_PASSWORD \
  --onlyIDToken)

curl -H "Authorization: Bearer $TOKEN" https://api.example.com/deploy
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

