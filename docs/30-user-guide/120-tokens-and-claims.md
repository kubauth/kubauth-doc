
# Tokens and Claims

## Obtaining a Token

The Kubauth companion CLI application `kc` provides an embedded OIDC client. Beyond testing the installation, its primary purpose is to fetch access tokens or ID tokens for use in any application.

Launch the following command after adjusting the issuer URL:

``` { .bash .copy }
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public
```

> Adjust the `issuerURL` to the value set previously in Kubauth configuration  

!!! tip

    If you encounter an error like `tls: failed to verify certificate: x509:...`, the CA associated with your ClusterIssuer is not recognized on your local workstation.

    - Add the `--insecureSkipVerify` option to the `kc token` command. You will also need to configure your browser to accept the certificate.
    - Add the CA as a trusted certificate on your local workstation. You can extract it with:
      ``` { .bash .copy }
      kubectl -n kubauth get secret kubauth-oidc-server-cert \
        -o=jsonpath='{.data.ca\.crt}' | base64 -d >./ca.crt 
      ```


Your browser should open to the Kubauth login page:

![login](../assets/kubauth-login.png){ .center width="50%" }

Log in using `jim/jim123`. You should land on a page similar to the following:

![tokens](../assets/kubauth-tokens.png){ .center width="70%" }

From this page, you can copy the provided tokens.

These tokens are also displayed in the CLI response:

```bash
Access token: ory_at_xLUfAhEGpFVWpMLdNEDZAj94hHFrHWjgOYB5g0Leh_k.0rgIzRGFOiIeGsMKnIZ74QL4Ve5vVOuEZyhA0402u8Y
Refresh token: ory_rt_nU9NBZs4NtKTxVYVko1aqlJkAMF5MLBYjfiZbhVt9aE.THwsnTlqzIsWo5O1NAf1EbDhz7HdaqVHHwSTkWxrkqY
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY3ZmY5MzUxMzZiMSIsInR5cCI6IkpXVCJ9.eyJhdF9oYXNoIjoiaGNBY2dtdmdBekJlSGgyODlkWHF3USIsImF1ZCI6WyJwdWJsaWMiXSwiYXV0aF90aW1lIjoxNzYxMzI2MDg2LCJhenAiOiJwdWJsaWMiLCJleHAiOjE3NjEzMjk2ODYsImlhdCI6MTc2MTMyNjA4NiwiaXNzIjoiaHR0cHM6Ly9rdWJhdXRoLmluZ3Jlc3Mua3VibzYubWJwIiwianRpIjoiZDZhYjkwODMtYTEzMi00YTNiLTlmMWItMzM2NWFhOTQ5MjQ2IiwicmF0IjoxNzYxMzI2MDg2LCJzdWIiOiJqaW0ifQ.Q8ZkF33jsUJDqLH98uqRgrFa2nwioRP1TO9n6QjX9XFr-1WmsKk9nEeHGAiASb1brQ3cSAmK8ta7fX3lBLBlszxmeVZRzq5Qvg0N8nqvlV3C4CAiv6lEl6_-y6wBoQOWN9OhNhYU6wFjpNNDTx_RW0329i9TYVxaygw58wJGCX_1F5-PY0NG74n_1sdZxYop7s5GnZ0_9S9-DEI-LNR2MMx-oVH4lpGjV5dhGRvZS0l4tMm2C7J6Yx_JoTQoZfWwPI0GGf2smZZ-C2ieB5Wj0b19fgrafuexHW9yeejI51j6WZs_eDqUwvCIf52_yAvokA4SiW4PW8Eod9fX-JuwJQ
Expire in: 59m59s
```

Let's try another variant of the command:

``` { .bash .copy }
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public --onlyIDToken | kc jwt
```

- The `--onlyIDToken` option instructs the command to output only the base64-encoded ID token, useful for batch processing.
- The `kc jwt` command decodes the JWT token.

The response should look like:

```
JWT Header:
{
  "alg": "RS256",
  "kid": "f4ccd454-f3a8-447f-a7c3-67ff935136b1",
  "typ": "JWT"
}

JWT Payload:
{
  "at_hash": "_GWrC20juEb4Zh39S0ly5w",
  "aud": [
    "public"
  ],
  "auth_time": 1761564624,
  "auth_time_human": "2025-10-27 11:30:24 UTC",
  "azp": "public",
  "exp": 1761568224,
  "exp_human": "2025-10-27 12:30:24 UTC",
  "iat": 1761564624,
  "iat_human": "2025-10-27 11:30:24 UTC",
  "iss": "https://kubauth.ingress.kubo6.mbp",
  "jti": "be30eeb2-153f-4dec-97b8-c75d23035f81",
  "rat": 1761564624,
  "rat_human": "2025-10-27 11:30:24 UTC",
  "sub": "jim"
}
```

!!! note

    The `auth_time_human`, `exp_human`, `iat_human`, and `rat_human` fields are not actual claims but human-readable values added by the decoder to aid interpretation of the corresponding timestamp values.

There is also a shortcut (`-d`) for this command:

``` { .bash .copy }
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public -d
```

Note: This option skips the JWT header.

## Claims

A set of 'system' claims are provided by the OIDC server. You can find a [description of most standard claims here](http://openid.net/specs/openid-connect-core-1_0.html#IDToken){:target="_blank"}.

Another important claim is `sub`, which stands for 'subject' and represents the user's login.

Now, run the previous command again, but use `john/john123` when prompted for login:

```
JWT Payload:
{
  "at_hash": "fdg2po7ht7lBaFFvgXg14A",
  "aud": [
    "public"
  ],
  "auth_time": 1761575699,
  "auth_time_human": "2025-10-27 14:34:59 UTC",
  "azp": "public",
  "email": "johnd@mycompany.com",
  "emails": [
    "johnd@mycompany.com"
  ],
  "exp": 1761579299,
  "exp_human": "2025-10-27 15:34:59 UTC",
  "iat": 1761575699,
  "iat_human": "2025-10-27 14:34:59 UTC",
  "iss": "https://kubauth.ingress.kubo6.mbp",
  "jti": "822ed082-e615-4153-ad7e-d623df491253",
  "name": "John DOE",
  "office": "208G",
  "rat": 1761575699,
  "rat_human": "2025-10-27 14:34:59 UTC",
  "sub": "john"
}
```

Kubauth has added several new claims derived from the `User` resource definition:

- `name`: The `spec.name` property, containing the user's full name.
- `emails`: The `spec.emails` list.
- `email`: The first email from the emails list.
- `office`: Content from the `spec.claims` property, which can contain any valid map values.


The resulting claim set is the result of merging:

- An initial set of system claims (`aud`, `azp`, `exp`, `iss`, ...)
- Claims added by Kubauth from the user CRD definition:
    - `name` from `spec.name`
    - `emails` from `spec.emails`
    - `groups` described in a [following chapter](./150-users-groups.md)
- The contents of the user's `spec.claims`

!!! warning

    In the current version, claims are not filtered by scope. In other words, all user claims are included in the ID token.

