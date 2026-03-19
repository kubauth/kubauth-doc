# Harbor Integration

## OIDC Client Creation

As described in [Configuration](../30-user-guide/110-configuration.md/#oidc-client-creation), a client application is defined as a Kubernetes Custom Resource.

Create a manifest like the following:

???+ abstract "client-harbor.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: harbor-oidc-client-secret
      namespace: kubauth
    type: Opaque
    stringData:
      clientSecret: "harbor123"
    
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: harbor
      namespace: kubauth
    spec:
      redirectURIs:
        - "https://harbor.mycluster.mycompany.com/c/oidc/callback"
      grantTypes: [ "implicit", "refresh_token", "authorization_code", "password", "client_credentials" ]
      responseTypes: ["id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token"]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access"]
      displayName: Harbor
      description: Harbor OCI repository
      entryURL: https://harbor.mycluster.mycompany.com/
      secrets:
        - name: harbor-oidc-client-secret
          key: clientSecret
    ```

- Replace `harbor.mycluster.mycompany.com` with your Harbor entry point (in 2 locations)
- The `displayName`, `description`, and `entryURL` attributes are optional. They enable Harbor to appear in a list of available applications displayed on a specific page (`https://kubauth.mycluster.mycompany.com/index`) or the logout page.

Apply this manifest:

``` { .bash .copy }
kubectl apply -f client-harbor.yaml
```

## Manual Harbor Configuration

We assume you have a running Harbor installation.

- Log in to the Harbor interface with an account that has Harbor system administrator privileges.
- Under Administration, go to Configuration and select the Authentication tab.
- Use the Auth Mode drop-down menu to select OIDC.

Set the following values:

- Auth Mode: `OIDC`
- OIDC Provider Name: `KUBAUTH`
- OIDC Endpoint: `https://kubauth.mycluster.mycompany.com` <br>(Adjust to your local Kubauth entry point)
- OIDC Client ID: `harbor`
- OIDC Client Secret: `harbor123`
- Group Claim Name: `groups`
- OIDC Admin Group: `harbor-admins`
- OIDC Scopes: `openid,email,profile,offline_access,groups`
- Automatic onboarding: `true` 
- Username Claim: `name`

## Automated Harbor Configuration

OIDC can also be configured [using environment variables](https://goharbor.io/docs/2.7.0/install-config/configure-system-settings-cli/#set-configuration-items-using-an-environment-variable){:target="_blank"}.

If you have installed Harbor using the provided Helm chart, this can be achieved by appending a values file like the following to your deployment:

???+ abstract "values-kubauth.yaml"

    ``` { .yaml .copy }
    core:
      extraEnvVars:
        - name: CONFIG_OVERWRITE_JSON
          value: |
            {
              "auth_mode": "oidc_auth",
              "oidc_name": "KUBAUTH",
              "oidc_endpoint": "https://kubauth.mycluster.mycompany.com",
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

> Replace `https://kubauth.mycluster.mycompany.com` with the Kubauth entry point of your installation.

## Admin Rights

To grant admin rights to a user, add them to the group we defined as `oidc_admin_group` (here `harbor-admins`) in the configuration by creating a new `GroupBinding`:

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

Now, you can log in with this user and verify they have full admin rights.
