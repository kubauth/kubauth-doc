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

## Required Flags

### `--issuerURL` (string)
The Kubauth OIDC issuer URL.

### `--clientId` (string)
The OIDC client ID.

## Optional Flags

### `--login` (string)
Username for authentication. If not provided, you'll be prompted.

### `--password` (string)
Password for authentication. If not provided, you'll be prompted (input hidden).

### `--clientSecret` (string)
Client secret for confidential clients.

### `--insecureSkipVerify`
Skip TLS certificate verification.

### `--onlyIDToken`
Output only the ID token.

### `-d, --decode`
Decode and display JWT token payload.

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

## Use Cases

### SSH/Remote Sessions

When working on a remote server without browser access:

```bash
ssh user@server
kc token-nui --issuerURL https://kubauth.example.com --clientId public
```

### kubectl on Remote Servers

```bash
# Configure kubectl to use password grant
kc config https://kubeconfig.example.com/kubeconfig --grantType password

# kubectl commands will prompt for credentials
kubectl get pods
```

**Interaction:**
```
Username: john
Password: 
```

### Automated Scripts

```bash
#!/bin/bash
# Fetch configuration data with authentication
CONFIG=$(kc token-nui \
  --issuerURL $KUBAUTH_URL \
  --clientId $CLIENT_ID \
  --login $AUTOMATION_USER \
  --password $AUTOMATION_PASSWORD \
  --onlyIDToken | \
  curl -H "Authorization: Bearer $(cat -)" https://config-api.example.com/config)
```

### CI/CD Authentication

```yaml
# GitLab CI example
test:
  script:
    - TOKEN=$(kc token-nui --issuerURL $KUBAUTH_URL --clientId $CLIENT_ID --login $CI_USER --password $CI_PASSWORD --onlyIDToken)
    - kubectl --token=$TOKEN get pods
```

## Security Considerations

!!! warning "Password Grant Security"
    The password grant flow is deprecated in OAuth 2.1 due to security concerns:
    
    - Credentials are exposed to the client application
    - Cannot support phishing-resistant MFA
    - Users may be trained to enter passwords in applications
    
    Use only when browser-based flows are impossible.

### Best Practices

1. **Use environment variables** for passwords in scripts:
   ```bash
   kc token-nui --issuerURL $URL --clientId $CLIENT --login $USER --password $PASSWORD
   ```

2. **Avoid logging passwords:**
   ```bash
   # Bad
   set -x
   kc token-nui --login user --password secretpass
   
   # Good
   set +x
   kc token-nui --login user --password $PASSWORD
   set -x
   ```

3. **Use service accounts** for automation, not personal accounts

4. **Rotate passwords regularly** for automated accounts

5. **Restrict client permissions** - Use dedicated clients with minimal scopes

## Troubleshooting

### Password Grant Not Allowed

**Error:**
```
token request failed with status 403: {"error":"request_forbidden","error_description":"The request is not allowed. This server does not allow to use authorization grant 'password'. Check server configuration"}
```

**Solution:** Enable password grant in both Kubauth configuration and the OidcClient. See [Password Grant Configuration](../30-user-guide/160-password-grant.md#configuration).

### Authentication Failed

**Error:**
```
token request failed with status 400: {"error":"invalid_grant","error_description":"...Unable to authenticate the provided username and password credentials."}
```

**Solutions:**
- Verify username and password are correct
- Check user is not disabled: `kubectl -n kubauth-users get user <username>`
- Review audit logs: `kc audit logins`

### Network/TLS Errors

```bash
# For development/testing only
kc token-nui --issuerURL https://kubauth.local --clientId public --insecureSkipVerify
```

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

