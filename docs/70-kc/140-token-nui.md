# kc token-nui

## Overview

The `kc token-nui` command obtains OIDC tokens using the **Resource Owner Password Credentials** (ROPC) flow. It accepts the username and password on the command line (or interactively in the terminal) and returns tokens — no browser is involved. This makes it suitable for SSH sessions, headless environments and automation.

After issuance, `kc token-nui` verifies the returned tokens, exactly like [`kc token`](130-token.md):

- The ID token signature is verified against the server's signing keys (JWKS).
- A JWT access token is verified the same way.
- An opaque access token is verified via the OAuth2 introspection endpoint.

!!! note

    **NUI** stands for *No User Interface* (no browser).

## Syntax

```bash
kc token-nui [--issuerURL <url>] [--clientId <id>] [--login <user>] [--password <pwd>] [options]
```

## Prerequisites

The ROPC/Password Grant must be enabled in Kubauth:

1. **Global configuration:** set `allowPasswordGrant: true` in Kubauth Helm values.
2. **Client configuration:** add `"password"` to the client's `grantTypes` list.

See [Password Grant Configuration](../30-user-guide/160-password-grant.md#configuration) for details.

## Connection Flags

These flags are shared with [`kc token`](130-token.md). See [Common Options](100-overview.md#common-options) for the full description.

| Flag                                   | Type   | Default                               | Env var             |
|----------------------------------------|--------|---------------------------------------|---------------------|
| `--issuerURL`, `-i`                    | string | —                                     | `KC_ISSUER_URL`     |
| `--clientId`, `-c`                     | string | —                                     | `KC_CLIENT_ID`      |
| `--clientSecret`, `-s`                 | string | —                                     | `KC_CLIENT_SECRET`  |
| `--insecureSkipVerify`                 | bool   | `false`                               | —                   |
| `--caFile` <small>(repeatable)</small> | string | —                                     | —                   |
| `--kubeconfig`                         | string | `$KUBECONFIG` or `$HOME/.kube/config` | —                   |
| `--context`                            | string | kubeconfig `current-context`          | —                   |
| `--scope` <small>(repeatable)</small>  | string | `openid`, `profile`, `groups`         | —                   |
| `--logMode`                            | string | `text`                                | —                   |
| `--logLevel`, `-l`                     | string | `INFO`                                | —                   |
| `--dumpClientExchanges`                | bool   | `false`                               | —                   |

!!! info "About `--scope`"

    `offline_access` is appended automatically when [`--ttl`](#ttl) is used, so the server returns a refresh token.

## Output Flags

### `--onlyIdToken` { #onlyidtoken }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Print only the ID token on stdout. Convenient for piping into another command.

<hr class="api-field-separator">

### `--onlyAccessToken` { #onlyaccesstoken }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Print only the access token on stdout.

<hr class="api-field-separator">

### `--detailIdToken`, `-d` { #detailidtoken }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

In addition to the regular output, print the decoded ID token (header + payload).

<hr class="api-field-separator">

### `--detailAccessToken`, `-a` { #detailaccesstoken }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

In addition to the regular output, print the decoded access token (or a notice when the access token is opaque).

<hr class="api-field-separator">

### `--userInfo` { #userinfo }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Call the provider `userinfo` endpoint with the obtained access token and print the result.

## ROPC-Specific Flags

### `--login`, `-u` { #login }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-env">env: <code>KC_USER_LOGIN</code></span>
</p>

Username. If not provided, `kc` reads `KC_USER_LOGIN`; if still empty, it prompts on stderr.

<hr class="api-field-separator">

### `--password`, `-p` { #password }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-env">env: <code>KC_USER_PASSWORD</code></span>
</p>

Password. If not provided, `kc` reads `KC_USER_PASSWORD`; if still empty, it prompts on stderr with hidden input.

## Token Renewal

### `--ttl`, `-t` { #ttl }

<p class="api-meta">
<span class="api-badge api-type">duration</span>
<span class="api-badge api-default">default: <code>0</code> (disabled)</span>
</p>

Instead of exiting immediately after retrieving tokens, enter a renewal loop that ends after this duration. During this period, `kc` exercises the OIDC refresh-token flow.

When `--ttl` is non-zero, `offline_access` is automatically added to the requested scopes (so the server returns a refresh token).

**Example:** `--ttl 30m`

<hr class="api-field-separator">

### `--renewAt` { #renewat }

<p class="api-meta">
<span class="api-badge api-type">int</span>
<span class="api-badge api-default">default: <code>60</code></span>
</p>

Percentage of the access token's lifetime after which a renewal is triggered.

**Example:** `--renewAt 50` triggers a renewal halfway through the access token's lifespan.

## Examples

### Interactive Login

```bash
kc token-nui --issuerURL https://kubauth.example.com --clientId public
```

Interaction:

```
Login: john
Password:
```

Output:

```
Access token: ory_at_LAhtO0e8T8-V2wLZ72V0G98jKMJEpYQLH6tm6Aeg_Lw...
Refresh token: null
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

Or via environment:

```bash
export KC_ISSUER_URL=https://kubauth.example.com
export KC_CLIENT_ID=public
export KC_USER_LOGIN=john
export KC_USER_PASSWORD=john123

kc token-nui
```

### With Token Decoding

```bash
kc token-nui --issuerURL https://kubauth.example.com \
  --clientId public \
  --login john --password john123 \
  -d
```

### Only ID Token

```bash
kc token-nui --issuerURL https://kubauth.example.com \
  --clientId public \
  --login john --password john123 \
  --onlyIdToken
```

### For CI/CD Pipelines

```bash
#!/bin/bash
TOKEN=$(kc token-nui \
  --issuerURL https://kubauth.example.com \
  --clientId automation \
  --login serviceaccount \
  --password "$SERVICE_PASSWORD" \
  --onlyIdToken)

curl -H "Authorization: Bearer $TOKEN" https://api.example.com/deploy
```

### Renewal

The OIDC client is configured with `accessTokenLifespan: 30s` and `refreshTokenLifespan: 30s`:

```bash
kc token-nui --issuerURL https://kubauth.example.com --clientId kc-test --ttl 1m
```

Output:

```
Login:admin
Password:
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4ZWUtNDhlNS1hZDJiLW.................
Refresh token: ory_rt_smAzQrY5dtkxfSVdYTXf8HA42yOeXHsubruhT4TMiy8...
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M2Y1LTU4ZWUtNDhlNS1hZDJiLWU5NDI.................
Expire in: 30s

Renewal loop started (ttl: 1m0s, renewAt: 60%, deadline: 2026-03-31T17:47:08+02:00)
Token lifetime: 30s, renewal in: 18s (at 17:46:26), expires at: 17:46:38
Waiting 18s before next renewal...

--- Renewal #1 at 2026-03-31T17:46:26+02:00 ---
Renewal #1 successful
...
Next renewal would be past deadline, waiting 5s for TTL to expire...
TTL reached, exiting renewal loop
```

## Security Considerations

!!! warning "Password Grant Security"
    The password grant flow is deprecated in OAuth 2.1 due to security concerns:

    - Credentials are exposed to the client application.
    - Cannot support phishing-resistant MFA.
    - Users may be trained to enter passwords in third-party applications.

    Use only when browser-based flows are impossible.

## Troubleshooting

### Password Grant Not Allowed

Error:

```
token request failed with status 403: {"error":"request_forbidden","error_description":"The request is not allowed. This server does not allow to use authorization grant 'password'. Check server configuration"}
```

Solution: enable password grant in both the Kubauth Helm configuration and the OidcClient. See [Password Grant Configuration](../30-user-guide/160-password-grant.md#configuration).

### TLS Certificate Errors

Error:

```
Error: x509: certificate signed by unknown authority
```

Solutions:

- Use `--insecureSkipVerify` for testing (not recommended for production).
- Provide a CA: `--caFile ./ca.crt`. To extract it:
   ```bash
   kubectl -n kubauth get secret kubauth-oidc-server-cert \
     -o=jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
   ```
- Or add the CA to the system trust store.

### Authentication Failed

Error:

```
token request failed with status 400: {"error":"invalid_grant","error_description":"...Unable to authenticate the provided username and password credentials."}
```

Solutions:

- Verify the username and password.
- Check the user is not disabled: `kubectl -n kubauth-users get user <username>`.
- Review audit logs: `kc audit logins`.

## Comparison with `kc token`

| Feature             | `kc token`                | `kc token-nui`                |
|---------------------|---------------------------|-------------------------------|
| Browser required    | Yes                       | No                            |
| OAuth flow          | Authorization Code (+PKCE)| Password Grant (ROPC)         |
| SSH-friendly        | No                        | Yes                           |
| Automation-friendly | Limited                   | Yes                           |
| MFA support         | Yes                       | Limited                       |
| Security            | Better                    | Acceptable for specific cases |
| Setup required      | Standard OIDC             | Password grant must be enabled|

## Related Commands

- [`kc token`](130-token.md) — Browser-based authentication (preferred)
- [`kc client`](145-client.md) — Client Credentials flow
- [`kc config`](190-config.md) — Configure kubectl with password grant
- [`kc jwt`](160-jwt.md) — Decode JWT tokens
- [`kc audit`](150-audit.md) — Inspect login attempts

## See Also

- [Password Grant (ROPC)](../30-user-guide/160-password-grant.md)
- [Workstation Setup](../50-kubernetes-integration/140-workstation-setup.md#no-ui-mode)
