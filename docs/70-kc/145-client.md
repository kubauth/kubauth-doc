# kc client

## Overview

The `kc client` command obtains an Access Token using the Client Credentials flow. 

- If Access Token is in JWT form, its signature is checked against the server key.
- If Access Token is in opaque form, it is checked against server introspection endpoint.


## Syntax

```bash
kc client --issuerURL <url> --clientId <id> --clientSecret <secret> [options]
```

## Flags

### `--issuerURL`

The Kubauth OIDC issuer URL.

**Example:** `--issuerURL https://kubauth.example.com`

Value may also be fetched from `KC_ISSUER_URL` environment variable, or Kubernetes kubeconfig if `kc init ....` has been used.

-----
### `--clientId`

The OIDC client ID to use for authentication.

**Example:** `--clientId private`

Value may also be fetched from `KC_CLIENT_ID` environment variable, or Kubernetes kubeconfig if `kc init ....` has been used.

-----
### `--clientSecret`

The client secret.

**Example:** `--clientSecret mysecret123`

Value may also be fetched from `KC_CLIENT_SECRET` environment variable, or Kubernetes kubeconfig if `kc init ....` has been used.

-----
### `--insecureSkipVerify`
Skip TLS certificate verification. Use only for testing with self-signed certificates.

**Example:** `--insecureSkipVerify`

-----
### `--caFile`
Provide a CA file for TLS certificate verification of the issuer URL.

**Example:** `--caFile ./CA.crt`

-----
### `--onlyAccessToken`
Output only the access token (base64-encoded). Useful for piping to other commands or scripts.

**Example:** `--onlyAccessToken`

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

    In its current version, Kubauth does not enforce scope restrictions for the Client Credentials flow.

## Examples

### Opaque Access Token

```bash
kc client --issuerURL https://kubauth.example.com  --clientId=private --clientSecret=private-secret
```

**Output:**

```
Access token: ory_at_Jr45qPvItBKA8TRy-kYcrfE96ayosKwSmkTp1kVctAk.A1Asl0v_Qb9vXHaYDx8QlAhHT301QiY4xl8zdfHjXyw
Refresh token: null
ID token: null
Expire in: 4m59s
```


### JWT Access Token

```bash
kc client --issuerURL https://kubauth.example.com  --clientId=private --clientSecret=private-secret -a
```

**Output:**

```
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg4MDdjNzUzLTU3MTYtNDIzYi1hZWFmLTNiODRiYTIxOWY2NyIsInR5cCI6IkpXVCJ9.eyJhdWQiOltdLCJleHAiOjE3NzIwMTgzMDEsImlhdCI6MTc3MjAxODAwMSwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDo2ODAxIiwianRpIjoiYjEyYTdiMWItZjk3Ni00MjIwLWE4MjYtNDljMjVlOGE4ZWM0Iiwic2NwIjpbIm9wZW5pZCIsInByb2ZpbGUiLCJvZmZsaW5lIiwiZ3JvdXBzIl19.Wl2nFhxXKzeABPSNIwaNPPJ9qhQUDffY340kfh_3vGaHrXeRQEPG_UWs9dx_4e0B2uGvRkDzp3-R5pM7c9_C_yzmypgt3jLPKxtgAP2sSxuNkk7iMTJXTee-BRCI43a8vR7LqucHCT2rnl_Yw4Y137YUWpUtXkemm1HXwbyOR9dz8oWw96RJN23TsvNFpS6IA-W71RINmph97wccxMV7PrjLaq_X4FryHqon4TU_7wBQGT_2w5sTY972p0lbhEjDtm3dhIJXoBP4u7XPReIDVRjCcKhJZrHT_7EanubfFPpOF3zoOheMnRLpKOmzcU-Vl7CjFL944JRvJtS0zVrh-Q
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
  "scp": [
    "openid",
    "profile",
    "offline",
    "groups"
  ]
}
```