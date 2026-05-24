# kc client

## Overview

The `kc client` command obtains an access token using the **Client Credentials** flow. It is intended for machine-to-machine scenarios where no end-user is involved — a confidential client authenticates with its `client_id` / `client_secret` and receives an access token directly.

After issuance, the token is verified:

- A JWT access token is verified against the server's signing keys.
- An opaque access token is verified via the OAuth2 introspection endpoint.

The flow returns only an access token: there is no ID token and (in this version) no refresh token, so renewal-related flags (`--ttl`, `--renewAt`) do not apply.

## Syntax

```bash
kc client --issuerURL <url> --clientId <id> --clientSecret <secret> [options]
```

## Prerequisites

The OIDC client used here must:

- Have `"client_credentials"` in its `grantTypes`.
- Be configured as a confidential client (i.e. have a registered secret).

Most Kubauth deployments do not allow Client Credentials for end-user clients; configure a dedicated machine client instead.

## Connection flags

These flags are shared with the other OIDC subcommands — see [Common Options](100-overview.md#common-options):

- `-i, --issuerURL` (string) — Kubauth OIDC issuer URL (env `KC_ISSUER_URL`)
- `-c, --clientId` (string) — OIDC client ID (env `KC_CLIENT_ID`)
- `-s, --clientSecret` (string) — Client secret (env `KC_CLIENT_SECRET`)
- `--insecureSkipVerify` — Skip TLS verification of the issuer URL
- `--caFile <path>` (repeatable) — Trusted CA certificate(s) for the issuer URL
- `--kubeconfig <path>` / `--context <name>` — Look up the issuer URL/CA from a kubeconfig
- `--scope <name>` (repeatable) — Requested scope(s). **Default:** `openid`, `profile`, `groups`
- `--logMode <text|json>`, `-l, --logLevel <DEBUG|INFO|WARN|ERROR>` — Logging
- `--dumpClientExchanges` — Dump every HTTP request/response made by `kc`

## Output flags

- `--onlyAccessToken` — Print only the access token on stdout (useful for piping)
- `-a, --detailAccessToken` — Print the decoded access token after the regular output (or a notice if the token is opaque)

> ID-token-related flags (`--onlyIdToken`, `-d`/`--detailIdToken`) are accepted but have no effect, because the Client Credentials flow does not return an ID token.

## Examples

### Opaque Access Token

```bash
kc client --issuerURL https://kubauth.example.com --clientId=private --clientSecret=private-secret
```

**Output:**

```
Access token: ory_at_Jr45qPvItBKA8TRy-kYcrfE96ayosKwSmkTp1kVctAk.A1Asl0v_Qb9vXHaYDx8QlAhHT301QiY4xl8zdfHjXyw
Refresh token: null
ID token: null
Expire in: 4m59s
```

### JWT Access Token (decoded)

```bash
kc client --issuerURL https://kubauth.example.com --clientId=private --clientSecret=private-secret -a
```

**Output:**

```
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg4MDdjNzUzLTU3MTYtNDIzYi1hZWFmLTNiODRiYTIxOWY2NyIs...
Refresh token: null
ID token: null
Expire in: 4m59s
AccessToken: JWT Payload:
{
  "aud": [],
  "exp": 1772018301,
  "exp_human": "2026-02-25 11:18:21 UTC",
  "iat": 1772018001,
  "iat_human": "2026-02-25 11:13:21 UTC",
  "iss": "http://localhost:6801",
  "jti": "b12a7b1b-f976-4220-a826-49c25e8a8ec4",
  "scp": ["openid", "profile", "groups"]
}
```

### Pipe into another command

```bash
TOKEN=$(kc client --issuerURL https://kubauth.example.com \
  --clientId=private --clientSecret=private-secret \
  --onlyAccessToken)

curl -H "Authorization: Bearer $TOKEN" https://api.example.com/v1/whatever
```

## Related Commands

- [`kc token`](130-token.md) — Authorization Code flow (for end users)
- [`kc token-nui`](140-token-nui.md) — ROPC flow (for end users without a browser)
- [`kc jwt`](160-jwt.md) — Decode arbitrary JWT tokens

## See Also

- [OidcClient Reference](../60-references/110-oidcclient.md)
- [Tokens and Claims](../30-user-guide/120-tokens-and-claims.md)
