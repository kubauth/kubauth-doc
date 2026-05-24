# kc token

## Overview

The `kc token` command obtains OIDC tokens using the **Authorization Code** flow. It starts a local HTTP server, opens a browser on the Kubauth login page, exchanges the resulting authorization code for tokens, and prints them on the terminal. The browser then displays a success page with the decoded tokens (formatted as JSON, with copy buttons).

After issuance, `kc token` always verifies the returned tokens:

- The ID token signature is verified against the server's signing keys (JWKS).
- A JWT access token is verified the same way (with the audience check relaxed).
- An opaque access token is verified via the OAuth2 introspection endpoint.

A warning is printed on stderr if any of these verifications fail.

## Syntax

```bash
kc token [--issuerURL <url>] [--clientId <id>] [options]
```

When `--issuerURL` and/or `--clientId` are omitted, `kc` falls back to the corresponding `KC_*` environment variable, then to the current kubeconfig (see [Kubeconfig integration](100-overview.md#kubeconfig-integration)).

## Connection Flags

These flags are shared with `kc token-nui` and `kc client`. See [Common Options](100-overview.md#common-options) for the full description.

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

!!! note

    The browser success page **always** shows the decoded tokens regardless of `-d` and `-a`. These two flags only affect what is printed on the terminal.

## Flow-Specific Flags

### `--bindPort`, `-p` { #bindport }

<p class="api-meta">
<span class="api-badge api-type">int</span>
<span class="api-badge api-default">default: <code>9921</code></span>
</p>

Port of the local HTTP server used to receive the authorization callback.

The server listens on `127.0.0.1` and the redirect URI is computed as `http://127.0.0.1:<bindPort>/callback`. This redirect URI must be allowed by the OIDC client (Kubauth ships with a sensible default for `localhost`).

<hr class="api-field-separator">

### `--pkce` { #pkce }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Enable [PKCE](https://datatracker.ietf.org/doc/html/rfc7636) (Proof Key for Code Exchange, `S256`). Recommended for public clients.

<hr class="api-field-separator">

### `--prompt` { #prompt }

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Value forwarded as the OAuth2 `prompt` parameter in the authorization request. Valid OIDC values are `none`, `login`, `consent`, `select_account` (space-separated for several).

When the flag is omitted (default), `kc` does not include any `prompt` parameter in the request. Use `--prompt=login` to force the user to re-authenticate even when an SSO session is active, or `--prompt=none` to require silent re-authentication.

<hr class="api-field-separator">

### `--browser` { #browser }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: OS-level default browser</span>
</p>

Pick a specific browser to open. Possible values: `chrome`, `firefox`, `safari`.

<hr class="api-field-separator">

### `--dumpServerExchanges` { #dumpserverexchanges }

<p class="api-meta">
<span class="api-badge api-type">int</span>
<span class="api-badge api-default">default: <code>0</code></span>
</p>

Dump HTTP requests/responses received by the local callback HTTP server. One of `0` (off), `1`, `2`, `3` (increasing verbosity).

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

### Basic Usage

```bash
kc token --issuerURL https://kubauth.example.com --clientId public
```

Output (after successful login in the browser):

```
If browser doesn't open automatically, visit: http://127.0.0.1:9921
Access token: ory_at_xLUfAhEGpFVWpMLdNEDZAj94hHFrHWjgOYB5g0Leh_k...
Refresh token: null
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY...
Expire in: 59m59s
```

### Decoded ID Token

```bash
kc token --issuerURL https://kubauth.example.com --clientId public -d
```

The decoded payload is printed after the regular output:

```
...
IdToken: JWT Payload:
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

### Only the ID Token (for piping)

```bash
kc token --issuerURL https://kubauth.example.com --clientId public --onlyIdToken
```

Output:

```
eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY3ZmY5MzUxMzZiMSIsInR5cCI6IkpXVCJ9.eyJhdF9oYXNoIjoiaGNBY2dtdmdBekJlSGgyODlkWHF3USIsImF1ZCI6WyJwdWJsaWMiXSwi...
```

### Pipe to the JWT Decoder

```bash
kc token --issuerURL https://kubauth.example.com --clientId public --onlyIdToken | kc jwt
```

### Force Re-Authentication (no SSO short-circuit)

```bash
kc token --issuerURL https://kubauth.example.com --clientId public --prompt login
```

### PKCE (recommended for public clients)

```bash
kc token --issuerURL https://kubauth.example.com --clientId public --pkce
```

### Renewal Loop

The OIDC client is configured with `accessTokenLifespan: 30s` and `refreshTokenLifespan: 30s`:

```bash
kc token --issuerURL https://kubauth.example.com --clientId kc-test --ttl 1m10s
```

Output:

```
If browser doesn't open automatically, visit: http://127.0.0.1:9921
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1N.............
Refresh token: ory_rt_L5R5G3kTb5sEZOTCxz_J121GA59ogeYoe1xJXJXSyAM...
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3.............
Expire in: 29s

Renewal loop started (ttl: 1m10s, renewAt: 60%, deadline: 2026-03-31T17:36:15+02:00)
Token lifetime: 29s, renewal in: 17s (at 17:35:22), expires at: 17:35:34
Waiting 17s before next renewal...

--- Renewal #1 at 2026-03-31T17:35:22+02:00 ---
Renewal #1 successful
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1N.............
Refresh token: ory_rt_oQybFhJPQO-eI0xuu77kdCS9rpY8xAcoExFJODMyNvo...
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1NTk3M..............
Expire in: 30s
Token lifetime: 30s, renewal in: 18s (at 17:35:40), expires at: 17:35:52
Waiting 18s before next renewal...

--- Renewal #2 at 2026-03-31T17:35:40+02:00 ---
Renewal #2 successful
...
Next renewal would be past deadline, waiting 16s for TTL to expire...
TTL reached, exiting renewal loop
```

## Behavior

### Browser Flow

1. **Local server started** — `kc` starts an HTTP server on `127.0.0.1:<bindPort>`.
2. **Browser opens** — Your default browser is launched on the authorization URL.
3. **User authenticates** — You log in with your credentials in Kubauth.
4. **Callback received** — Kubauth redirects to `http://127.0.0.1:<bindPort>/callback` with an authorization code.
5. **Token exchange** — `kc` exchanges the code for tokens.
6. **Success page** — A success page is rendered in the browser, with the decoded tokens (and optionally userinfo) formatted as JSON.
7. **Terminal output** — Tokens are printed in the terminal according to `--onlyIdToken` / `--onlyAccessToken` / `-d` / `-a` / `--userInfo`.

### Token Storage

Tokens are displayed but never written to disk by `kc token`. To save them:

```bash
# Save the ID token to a variable
ID_TOKEN=$(kc token --issuerURL https://kubauth.example.com --clientId public --onlyIdToken)

# Save to a file
kc token --issuerURL https://kubauth.example.com --clientId public --onlyIdToken > token.txt
```

### SSO Session

If you previously checked "Remember me" on the Kubauth login page, subsequent `kc token` calls complete without prompting (SSO session active). Use `--prompt login` to force re-authentication, or `kc logout --sso` to drop the SSO cookie entirely.

## Troubleshooting

### Browser Doesn't Open

If the browser doesn't open automatically:

1. Read the terminal output for the URL.
2. Copy/paste it into your browser.
3. Or use [`kc token-nui`](140-token-nui.md) when no browser is available.

Example:

```
If browser doesn't open automatically, visit: http://127.0.0.1:9921
```

### TLS Certificate Errors

Error:

```
Error: x509: certificate signed by unknown authority
```

Solutions:

- Use `--insecureSkipVerify` for testing (not recommended for production).
- Provide a CA: `--caFile ./ca.crt`. To extract the issuer CA from the cluster:
   ```bash
   kubectl -n kubauth get secret kubauth-oidc-server-cert \
     -o=jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
   ```
- Or add this CA certificate to the system trust store.

## Security Considerations

1. **Don't expose tokens** — be careful when displaying or logging tokens.
2. **Use HTTPS** — always use HTTPS for the issuer URL in production.
3. **Verify certificates** — only use `--insecureSkipVerify` for testing.
4. **Use PKCE** — pass `--pkce` for public clients.
5. **Client secrets** — never commit client secrets to version control.

## Related Commands

- [`kc token-nui`](140-token-nui.md) — Non-interactive authentication (no browser)
- [`kc client`](145-client.md) — Client Credentials flow
- [`kc jwt`](160-jwt.md) — Decode arbitrary JWTs
- [`kc logout`](180-logout.md) — Clear SSO session and/or local kubectl OIDC cache
- [`kc whoami`](170-whoami.md) — Display current user

## See Also

- [Tokens and Claims](../30-user-guide/120-tokens-and-claims.md)
- [OidcClient Reference](../60-references/110-oidcclient.md)
