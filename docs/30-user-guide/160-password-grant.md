# Password Grant (ROPC)

OAuth's Resource Owner Password Credentials (ROPC) grant type, also known as the password grant, was included in the original OAuth 2.0 specification in 2012 as a temporary migration path. It was designed to help legacy applications transition from HTTP Basic Authentication or direct credential sharing to an OAuth token-based architecture.

The OAuth 2.0 Security Best Current Practice (BCP) has since **deprecated** this flow, and OAuth 2.1 removes it entirely due to several fundamental security concerns:

- **Credentials exposure**: The client application directly handles user passwords
- **Phishing risk**: Users are trained to enter passwords into applications
- **Credential theft**: If the client is compromised, user passwords are exposed

Despite deprecation, there are legitimate scenarios where ROPC may be the most pragmatic solution:

- Constrained CLI/headless sessions: When an interactive browser is unavailable (air-gapped shells, jump hosts)
- Automated scripts and CI/CD pipelines (where service accounts aren't suitable)
- Terminal-only environments on embedded systems
- Legacy migrations: Maintaining existing UX while transitioning server-side to OAuth/OIDC tokens

For these reasons, ROPC/Password Grant is supported by Kubauth.

## Configuration

While supported, ROPC is disabled by default. To use it, you must enable it at two levels.

First, at the global level, by setting a Helm chart configuration value:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      issuer: https://kubauth.mycluster.mycompany.com
      postLogoutURL: https://kubauth.mycluster.mycompany.com/index
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
    spec:
      redirectURIs:
        - "http://127.0.0.1:9921/callback"
      grantTypes: [ "refresh_token", "authorization_code", "password" ]
      responseTypes: [ "id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token" ]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access" ]
      description: A test OIDC public client
      public: true
    
      # accessTokenLifespan: 1h
      # refreshTokenLifespan: 1h
      # idTokenLifespan: 1h
    ```

We simply added `"password"` to the `grantTypes` list.

!!! note

    The `redirectURIs` list is not used for the ROPC flow. Retaining the value allows the client to continue using the standard `authorization_code` flow.
    
    For a client intended exclusively for ROPC flow, `redirectURIs` can be empty (but must be defined as `redirectURIs: []` for syntax consistency).

Once these two modifications are successfully applied (`helm upgrade ...` and `kubectl apply ...`), you can use this flow.

## kc token-nui

Similar to the `kc token` subcommand, there is a `kc token-nui` subcommand to generate tokens using the ROPC flow:

``` { .bash .copy }
kc token-nui --issuerURL https://kubauth.mycluster.mycompany.com --clientId public
Login:jim
Password:
```

If authentication is successful, you will receive the tokens:

```bash
Access token: ory_at_LAhtO0e8T8-V2wLZ72V0G98jKMJEpYQLH6tm6Aeg_Lw.yZhdVxRSMGnp6FlM63ErD6Lj8vpyJPxxTafNbygAvTE
Refresh token: ory_rt_kP1rTr6eF_AgdVvUtzfEKywhIddEK2cjDRC9EmkT0Hw.OeeTl_eAgq7jmBbYg6u7MT3P_ukg117nE8RxvZShZRM
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY3ZmY5MzUxMzZiMSIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicHVibGljIl0sImF1dGhfdGltZSI6MTc2MTY2MDI4NSwiYXpwIjoicHVibGljIiwiZXhwIjoxNzYxNjYzODg1LCJncm91cHMiOlsiZGV2cyJdLCJpYXQiOjE3NjE2NjAyODUsImlzcyI6Imh0dHBzOi8va3ViYXV0aC5pbmdyZXNzLmt1Ym82Lm1icCIsImp0aSI6IjFmMTRiYjkxLTQyYTQtNGUwZC1iNDEzLWE0MDAwN2E4ZmU0ZiIsInJhdCI6MTc2MTY2MDI4NSwic3ViIjoiamltIn0.PaR36uaDqZ0iLm--KZaYjNrD1bE5KI3p5Djo535ig6pC35QakhV4swikN2860koCALiq_Sl5A8Ki0Q7JLNGUp8h67E_ebcs4KVYzbEJq4sK6YfsCRgEEulijiX060DXl76u3hsPq2LEeKo710iIzPTFy_zy9GRTw7vbjk9_NJm3XbVqEw339H-l-yiUO3MKuS7MF6w77tMpw3NHIJ_uDSUC6ZNbXmsGts6N0K2Dy_lEtjij8KG3_zmRDszmV-CzbysUGBy5n0c8LemVRit6JlbwIJs8NvqB-zW_CZhty-3MEJOWitCAdmgcJmLYT_ZRG_YqNnWAWEdwWlZFg_8I6yg
Expire in: 1h0m0s
```

If you receive a response like the following:

```bash
token request failed with status 403: {"error":"request_forbidden","error_description":"The request is not allowed. This server does not  allow to use authorization grant 'password'. Check server configuration"}
```

the configuration steps described above have not been applied successfully.

For batch processing, the `kc token-nui` subcommand also supports `--login` and `--password` options, along with most of the same options as `kc token`:

``` { .bash .copy }
kc token-nui --issuerURL https://kubauth.mycluster.mycompany.com --clientId public \
    --login jim --password jim123 --onlyIdToken
```
```bash
eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY3ZmY5MzUxMzZiMSIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicHVibGljIl0sImF1dGhfdGltZSI6MTc2MTY2MDYxNywiYXpwIjoicHVibGljIiwiZXhwIjoxNzYxNjY0MjE3LCJncm91cHMiOlsiZGV2cyJdLCJpYXQiOjE3NjE2NjA2MTcsImlzcyI6Imh0dHBzOi8va3ViYXV0aC5pbmdyZXNzLmt1Ym82Lm1icCIsImp0aSI6IjY0YjcwNmQ5LWI1MjgtNGRlMy1iM2M2LTVkMjc3MTZjN2FjZSIsInJhdCI6MTc2MTY2MDYxNywic3ViIjoiamltIn0.G2VkVCsWVG1kNFXLp1lWu1ehXzkMJFWDQVANpR1wC8OGpBnwVaoTwRoTjAUw_yUrJu1u_m-NLWyzLIflJfmrTPTN3iz7Jsqc77iFoOmkOBUkOPvp9q66Uu3cbP3e52cYJcgOb5RcvaAOcBdp32zYotSLAPcRSHhuc1K2sdHg96bhU9dR5zs9Z29iXOzez4Bvq2haJpvjz4slZ2FZjSSkswyUlQQdfxoGC_VZgXyAJOycVK-e_oHJSOT1dtCi2y9QEHHHRRX3XpAqvZ86Q3Xk0Loxb03z6VDwzKeH1tYgplAcXTqb9jMmWFdh31JHZGd82S6v9lwUatrEuqo6ZXJR2A
```

or:

``` { .bash .copy }
kc token-nui --issuerURL https://kubauth.mycluster.mycompany.com --clientId public \
    --login jim --password jim123 -d
```

```
Access token: eyJhbGciOiJSUzI1NiIsImtpZCI6Ijk1ODhlNWIyLTIwY2QtNGM3Mi04MGIwLTU0OGJjZDdjNDg0OCIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicHVibGljIl0sImF6cCI6InB1YmxpYyIsImV4cCI6MTc3Mzg1ODkyNSwiZ3JvdXBzIjpbImRldnMiXSwiaWF0IjoxNzczODU1MzI0LCJpc3MiOiJodHRwczovL2t1YmF1dGguaW5ncmVzcy5rdWJvMi5tYnAiLCJqdGkiOiJlMjA2Zjg4OS01ZjQxLTRiYjUtYThkMi1lYTVjNTYxNjFjNjQiLCJzY3AiOlsib3BlbmlkIiwicHJvZmlsZSIsIm9mZmxpbmUiLCJncm91cHMiXSwic3ViIjoiamltIn0.U_HsGMZzl59OTJ5lGtDoohMDn00uBqJqbvZ10VdEd0TntHk9SPtaeoDQrSG0pD9iEoUoA8wMvIcySNvEgOFhC_ehE6LVMNJeubLo6d8r2Dhr7WfSR3mbkUmihIi1IT0IwnkIKAzwoyVZUbvB9SxrNJe-S5SObMGWce985m2turu45cqYN-K9NaXNyzZxepZz4Imhoe7HWs0tBejabsjETJfjpcEibb4TiQbNqs2zPxFOhjhcWPdv4ZV8AqtVoH-aRKX7BZ4Rubp2JWfbC4mh5E37znZospW8w6E4drfHXbXLnMY3eNBex04QaDBZOeMM07Aqm3ubBle3uQGIMLc3zA
Refresh token: ory_rt_OVHJ5DNzgqo39bg_s24kcn7vpIneMg8OR19pFPAi_yo.eYIunfSgmkBv-d6oNtNvdMroULDcYsQV2Lhd_wEmFDg
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6Ijk1ODhlNWIyLTIwY2QtNGM3Mi04MGIwLTU0OGJjZDdjNDg0OCIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicHVibGljIl0sImF1dGhfdGltZSI6MTc3Mzg1NTMyNCwiYXpwIjoicHVibGljIiwiZXhwIjoxNzczODU4OTI0LCJncm91cHMiOlsiZGV2cyJdLCJpYXQiOjE3NzM4NTUzMjQsImlzcyI6Imh0dHBzOi8va3ViYXV0aC5pbmdyZXNzLmt1Ym8yLm1icCIsImp0aSI6ImZlOTczYzQ3LTY1NWMtNGZlMS1iODYzLWQ4Nzc4ZjMwYWUxNiIsInJhdCI6MTc3Mzg1NTMyNCwic3ViIjoiamltIn0.Ou7RO2LBRtmfPdZHFxpMKktfNp7VzyH9C-lu83rk1E1HaKmtJSZBsFnstwSRyCCyokji9fQW98eoGCvSTry0p2J-Hul2laEw7rXB1A_ixzdWbSnef4ELDc497LklJ6K4EN-gLwvGG56Y-cs_O3cw3HAdgWZRR6N-Sd91BX18QgZcj3MFlRr8D5O6_W53cFyLuJjuk6IDmMQpg9g6VOcty19__LjLIgeXP1A1WscSvPJxCxHUtbhrRjUYvZKRWYYvC0oN5iDHPS_hRAa_qohkfzVRgHIMc1WdQjGyO2JBLIlN88-5NpxvCB7G1o1wqMzJsfDjv_dA_ngeACchF8H1Mw
Expire in: 1h0m0s
IdToken: JWT Payload:
{
  "aud": [
    "public"
  ],
  "auth_time": 1773855324,
  "auth_time_human": "2026-03-18 17:35:24 UTC",
  "azp": "public",
  "exp": 1773858924,
  "exp_human": "2026-03-18 18:35:24 UTC",
  "groups": [
    "devs"
  ],
  "iat": 1773855324,
  "iat_human": "2026-03-18 17:35:24 UTC",
  "iss": "https://kubauth.mycluster.mycompany.com",
  "jti": "fe973c47-655c-4fe1-b863-d8778f30ae16",
  "rat": 1773855324,
  "rat_human": "2026-03-18 17:35:24 UTC",
  "sub": "jim"
}

```