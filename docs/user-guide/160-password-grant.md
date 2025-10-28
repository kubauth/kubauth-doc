# Password Grant (ROPC)

OAuth's Resource Owner Password Credentials (ROPC) grant type, also known as the password grant, was included in the original OAuth 2.0 specification back in 2012 as a temporary migration path.
It was designed to help legacy applications transition from HTTP Basic Authentication or direct credential sharing to an OAuth token-based architecture.

The OAuth 2.0 Security Best Current Practice (BCP) has since **deprecated** this flow, and OAuth 2.1 removes it entirely due to several fundamental security concerns:

- **Credentials exposure**: The client application directly handles user passwords
- **Phishing risk**: Users are trained to enter passwords into applications
- **Credential theft**: If the client is compromised, user passwords are exposed

Despite deprecation, there are legitimate scenarios where ROPC may be the most pragmatic solution:

- Constrained CLI/headless sessions: When an interactive browser is impossible (air‑gapped shells, jump hosts).
- Automated scripts and CI/CD pipelines (where service accounts aren't suitable)
- Terminal-only environments on embedded systems
- Legacy migrations: Lets you keep an existing UX while you transition server-side to OAuth/OIDC tokens.

For these reasons, ROPC/Password Grant is supported by Kubauth

## Configuration.

While supported, ROPC is unactivated by default. To use it, you must activate it at two levels.

First, at global level, by setting a helm chart configuration value:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      issuer: https://kubauth.ingress.kubo6.mbp
      postLogoutURL: https://kubauth.ingress.kubo6.mbp/index
      ....
      allowPasswordGrant: true
    ```

Then, at the client definition level. Here is a modified version of our public client:

???+ abstract "client-public.yaml"

    ``` { .yaml .copy }
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: public
      namespace: kubauth-oidc
    spec:
      redirectURIs:
        - "http://127.0.0.1:9921/callback"
      grantTypes: [ "refresh_token", "authorization_code", "password" ]
      responseTypes: [ "id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token" ]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access" ]
      description: A test OIDC public client
      public: true
    
      # hashedSecret: "$2a$12$9vdc.xb3Zf4ts/C2pSvIOuGmFiv0EStBJWslaaycavblaIjYZ9Mia"
      # accessTokenLifespan: 1h
      # refreshTokenLifespan: 1h
      # idTokenLifespan: 1h
    ```

We just added `"password"` to the `grantTypes` list.

!!! note

    The `redirectURIs` list is not used for ROPC flow. Preserving its value will allow to still use `authorization_code` usual flow.
    
    For a client intended to be used only with ROPC flow, the `redirectURIs` can be empty. (But defined as `redirectURIs: []` for syntax coherency)

Once these two modification successfully applied (`helm upgrade ....` and `kubectl apply ...`) , we can use this flow.

## kc token-nui

Similar to the `kc token` subcommand, there is a `kc token-nui` subcommand to generate a token using the ROPC flow:

``` { .bash .copy }
kc token-nui --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public
Login:jim
Password:
```

If authentication is successful, you will get the tokens 

```bash
Access token: ory_at_LAhtO0e8T8-V2wLZ72V0G98jKMJEpYQLH6tm6Aeg_Lw.yZhdVxRSMGnp6FlM63ErD6Lj8vpyJPxxTafNbygAvTE
Refresh token: ory_rt_kP1rTr6eF_AgdVvUtzfEKywhIddEK2cjDRC9EmkT0Hw.OeeTl_eAgq7jmBbYg6u7MT3P_ukg117nE8RxvZShZRM
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY3ZmY5MzUxMzZiMSIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicHVibGljIl0sImF1dGhfdGltZSI6MTc2MTY2MDI4NSwiYXpwIjoicHVibGljIiwiZXhwIjoxNzYxNjYzODg1LCJncm91cHMiOlsiZGV2cyJdLCJpYXQiOjE3NjE2NjAyODUsImlzcyI6Imh0dHBzOi8va3ViYXV0aC5pbmdyZXNzLmt1Ym82Lm1icCIsImp0aSI6IjFmMTRiYjkxLTQyYTQtNGUwZC1iNDEzLWE0MDAwN2E4ZmU0ZiIsInJhdCI6MTc2MTY2MDI4NSwic3ViIjoiamltIn0.PaR36uaDqZ0iLm--KZaYjNrD1bE5KI3p5Djo535ig6pC35QakhV4swikN2860koCALiq_Sl5A8Ki0Q7JLNGUp8h67E_ebcs4KVYzbEJq4sK6YfsCRgEEulijiX060DXl76u3hsPq2LEeKo710iIzPTFy_zy9GRTw7vbjk9_NJm3XbVqEw339H-l-yiUO3MKuS7MF6w77tMpw3NHIJ_uDSUC6ZNbXmsGts6N0K2Dy_lEtjij8KG3_zmRDszmV-CzbysUGBy5n0c8LemVRit6JlbwIJs8NvqB-zW_CZhty-3MEJOWitCAdmgcJmLYT_ZRG_YqNnWAWEdwWlZFg_8I6yg
Expire in: 1h0m0s
```

If you got an answer like the following:

```bash
token request failed with status 403: {"error":"request_forbidden","error_description":"The request is not allowed. This server does not  allow to use authorization grant 'password'. Check server configuration"}
```

the configuration steps described above is not effective.

For batch inclusion, the `kc token-nui` subcommand also support `--login` and/or `--password` option. And most of the same option as `kc token`.

``` { .bash .copy }
kc token-nui --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public \
    --login jim --password jim123 --onlyIDToken
```
```bash
eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY3ZmY5MzUxMzZiMSIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicHVibGljIl0sImF1dGhfdGltZSI6MTc2MTY2MDYxNywiYXpwIjoicHVibGljIiwiZXhwIjoxNzYxNjY0MjE3LCJncm91cHMiOlsiZGV2cyJdLCJpYXQiOjE3NjE2NjA2MTcsImlzcyI6Imh0dHBzOi8va3ViYXV0aC5pbmdyZXNzLmt1Ym82Lm1icCIsImp0aSI6IjY0YjcwNmQ5LWI1MjgtNGRlMy1iM2M2LTVkMjc3MTZjN2FjZSIsInJhdCI6MTc2MTY2MDYxNywic3ViIjoiamltIn0.G2VkVCsWVG1kNFXLp1lWu1ehXzkMJFWDQVANpR1wC8OGpBnwVaoTwRoTjAUw_yUrJu1u_m-NLWyzLIflJfmrTPTN3iz7Jsqc77iFoOmkOBUkOPvp9q66Uu3cbP3e52cYJcgOb5RcvaAOcBdp32zYotSLAPcRSHhuc1K2sdHg96bhU9dR5zs9Z29iXOzez4Bvq2haJpvjz4slZ2FZjSSkswyUlQQdfxoGC_VZgXyAJOycVK-e_oHJSOT1dtCi2y9QEHHHRRX3XpAqvZ86Q3Xk0Loxb03z6VDwzKeH1tYgplAcXTqb9jMmWFdh31JHZGd82S6v9lwUatrEuqo6ZXJR2A
```