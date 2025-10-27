
# Tokens and Claims

## Get a token

The Kubauth companion CLI application `kc` provide an embedded OIDC client application. Beside being used as here for testing installation,
its aim is to provide a tool to fetch Access token or OIDC token, ready to be injected in whatever application.

Launch the following command, after adjusting the issuerURL;

``` { .bash .copy }
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public
```

Your browser should open on the kubauth login page:

![login](../assets/kubauth-login.png){ .center width="50%" }

Log in using `jim/jim123`. You should land on a page like the following

![tokens](../assets/kubauth-tokens.png){ .center width="70%" }

Where you can copy the provided tokens from.

Theses tokens are also in the CLI response:

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

- The `--onlyIDToken` instruct the command to display only the base64 encoded OIDC token. Useful for batch inclusion.
- The `kc jwt` act as a filter to decode the jwt token.

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

!!! notes

    The `auth_time_human`, `exp_human`, `iat_human` and `rat_human` are not effective claims, 
    but values added by the filter to ease interpretation of the corresponding timestamp values.

There is also a shortcut (`-d`) to this command:

``` { .bash .copy }
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public -d
```

NB: Using this option skip the JWT header.

## Claims

A set of 'system' Claims are set by the OIDC server. You will find a [description of most of them here](http://openid.net/specs/openid-connect-core-1_0.html#IDToken){:target="_blank"}..

Another important one is the `sub` token. Stand for 'subject' and is in fact the user's login.

Now, type again the previous command, but use john/john123 when prompted for login:

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

Kubauth has added some new claims, issued from the `user` resource définition:

- `name`: The user `spec.name` property. Used to to the full user name.
- `emails`: The user `spec.emails` list.
- `email`: The first email of the previous list.
- `office`: The content of the `spec.claims` property. Could contains whatever valid map values.


The principle is the resulting set of claim is the result of the merge of:

- An initial set of system ones (`aud`, `azp`, `exp`, `iss`, ...)
- Some added by Kubauth from the Kubernetes CRD based definition:
    - `name`
    - `emails`
    - `groups` (Will be describe in a next chapter)
- The content of the user's `spec.claims`

!!! warning

    On the current version, claims are not filtered by scope. In other words, all claims of a user are provided in the OIDC token.

