# Harbor integration

## Oidc client creation

As stated in [Configuration](../30-user-guide/110-configuration.md/#oidc-client-creation), a client application is defined as a Kubernetes Custom Resource.

So, a manifest like the following should be created:

???+ abstract "client-harbor.yaml"

    ``` { .yaml .copy }
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: harbor
      namespace: kubauth-oidc
    spec:
      hashedSecret: "$2a$12$5lLVmTBlougPBAQ8h10wR.W9tvZQBRsK1/Sh48yO8WLyXr.P4w3tm"
      redirectURIs:
        - "https://harbor.ingress.kubo6.mbp/c/oidc/callback"
      grantTypes: [ "refresh_token", "authorization_code" ]
      responseTypes: ["id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token"]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access"]
      # Following are optional
      displayName: Harbor
      description: Harbor OCI repository
      entryURL: https://harbor.ingress.kubo6.mbp/
    ```


> `harbor.ingress.kubo6.mbp` must be replaced by your Harbor entry point (In 2 locations)

- The sample password is 'harbor123'. Thus, the `hashedSecret` value is the result of a <br>`kc hash harbor123` command.

Apply this manifest:

``` { .bash .copy }
kubectl apply -f client-harbor.yaml
```

## Manual Harbor configuration.

We assume here you have a running Harbor installation.

- Log in to the Harbor interface with an account that has Harbor system administrator privileges.
- Under Administration, go to Configuration and select the Authentication tab.
- Use the Auth Mode drop-down menu to select OIDC.

And set the following values:

- Auth Mode: `OIDC`
- OIDC Provider Name: `KUBAUTH`
- OIDC Endpoint: `https://kubauth.ingrees.kubo6.mbp` (To adjust to your local value)
- OIDC Client ID: `harbor`
- OIDC Client Secret: `harbor123`
- Group Claim Name: `group`
- OIDC Admin Group: `harbor-admins`
- OIDC Scopes: `openid,email,profile,offline_access,groups`
- Automatic onboarding: `true` 
- Username Claim: `name`

## Automated Harbor Configuration

OIDC can also be configured [using environment variables](https://goharbor.io/docs/2.7.0/install-config/configure-system-settings-cli/#set-configuration-items-using-an-environment-variable){:target="_blank"}.

???+ abstract "values-kubauth.yaml"

    ``` { .yaml .copy }
    core:
      extraEnvVars:
        - name: CONFIG_OVERWRITE_JSON
          value: |
            {
              "auth_mode": "oidc_auth",
              "oidc_name": "KUBAUTH",
              "oidc_endpoint": "https://kubauth.ingress.kubo6.mbp",
              "oidc_groups_claim": "groups",
              "oidc_admin_group": "harbor-admins",
              "oidc_client_id": "harbor",
              "oidc_client_secret": "harbor123",
              "oidc_scope": "openid,email,profile,offline_access,groups",
              "oidc_verify_cert": "false",
              "oidc_auto_onboard": "true",
              "oidc_user_claim": "name"
            }
    ```

## Admin rights

To grant admin rights to a user, just add it to the groups we have defined as `oidc_admin_group` in the configuration:

``` { .bash .copy }
kubectl apply -f - <<EOF
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-harbor-admins
  namespace: kubauth-users
spec:
  group: harbor-admins
  user: john
EOF
```

