# ArgoCD Integration


## OIDC Client Creation

As described in [Configuration](../30-user-guide/110-configuration.md/#oidc-client-creation), an OIDC client application is defined as a Kubernetes Custom Resource.

Create a manifest like the following:

???+ abstract "client-argocd.yaml"

    ``` { .yaml .copy }
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: argocd
      namespace: kubauth-oidc
    spec:
      hashedSecret: "$2a$12$.34NOSBLz9cfW9PD/yjj6uhrvys42Xb4euwKy6UFx9YLYEwxIICAK" 
      redirectURIs:
        - "https://argocd.ingress.kubo6.mbp/auth/callback"
        - "http://localhost:8085/auth/callback"
      grantTypes: [ "refresh_token", "authorization_code" ]
      responseTypes: ["id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token"]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access"]
      # Following are optional
      displayName: ArgoCD
      description: GitOps continuous delivery tool
      entryURL: https://argocd.ingress.kubo6.mbp/
    ```

- Replace `argocd.ingress.kubo6.mbp` with your ArgoCD entry point (in 2 locations)
- The sample password is 'argocd123'. The `hashedSecret` value is the result of the `kc hash argocd123` command.
- The `http://localhost:8085/auth/callback` entry in the `redirectURIs` list is for the `argocd` CLI command
- The `displayName`, `description`, and `entryURL` attributes are optional. They enable ArgoCD to appear in a list of available applications displayed on a specific page (`https://kubauth.ingress.kubo6.mbp/index`) or the logout page (see below).

Apply this manifest:

``` { .bash .copy }
kubectl apply -f client-argocd.yaml
```

## ArgoCD Configuration

We assume ArgoCD is installed using the [community-provided Helm chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd){:target="_blank"}.

> If ArgoCD is installed using another method, it should be straightforward to configure OIDC as described in the 
  [ArgoCD manual](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#existing-oidc-provider){:target="_blank"} using the information provided here.

This means configuration is provided using Helm values or values files. Since general ArgoCD configuration is beyond the scope of this manual, we will focus only on the OIDC-related section of the values file.

There are two challenging aspects of ArgoCD OIDC configuration:

- How to provide the secret value shared between ArgoCD and the Kubauth OIDC server
- How to provide the CA to validate the Kubauth OIDC issuer URL

### Basic Configuration

In this approach, the secret is provided in clear text, and the CA certificate is embedded directly.

Create a values file like the following to be added to your Helm command when deploying ArgoCD (`... --values values-kubauth.yaml...`):

???+ abstract "values-kubauth.yaml"

    ``` { .yaml .copy }
    configs:
      cm:
        url: "https://argocd.ingress.kubo6.mbp"
        oidc.config: |
          name: Kubauth
          issuer: https://kubauth.ingress.kubo6.mbp
          clientID: argocd
          clientSecret: argocd123 
          requestedScopes: ["openid", "profile", "email", "groups"]
          enablePKCEAuthentication: true
          # logoutURL: https://kubauth.ingress.kubo6.mbp/oauth2/logout
          rootCA: |
            -----BEGIN CERTIFICATE-----
            MIIGSzCCBDOgAwIBAgIJAN3rPrHNIFfAMA0GCSqGSIb3DQEBCwUAMHUxCzAJBgNV
            BAYTAkZSMQ4wDAYDVQQIDAVQYXJpczEOMAwGA1UEBwwFUGFyaXMxGTAXBgNVBAoM
            EE9wZW5EYXRhUGxhdGZvcm0xFjAUBgNVBAsMDUlUIERlcGFydG1lbnQxEzARBgNV
            BAMMCmNhLm9kcC5jb20wHhcNMjEwODE4MDkyMzA1WhcNMzEwODE2MDkyMzA1WjB1
            .......
            .......
            bCbEcvjOBGCIMC+KrWGLbT3i1e1Lici91aqXcHp9rEZSlO/kPGf5gX6FJcj6jVo7
            P6KClBmIhVYHMueorH7OUFl8mdsVayxMB8dzlr49yQQzhqif3ywLJQEpClCsbq/d
            J2D93BTA8z5cto4I5oCtfQ2GjlkfEJG863gcIT/3ieu3AI/+LATFO7+TYVqYY8SI
            wDQVxs1wOpHZOEekfO4fKW12BQ+f+K9m+j0ISFzUCA==
            -----END CERTIFICATE-----
    
      rbac:
        policy.csv: |
          g, argocd-admin, role:admin 
    ```
- Replace `argocd.ingress.kubo6.mbp` with your ArgoCD entry point.
- Replace `kubauth.ingress.kubo6.mbp` with your Kubauth entry point (in 2 locations).
- We enable PKCE, as it is the safest option and supported by both parties.
- The `logoutURL` parameter is commented out here. More on this below.
- The `rootCA` parameter is the CA of the Kubauth issuer. If Kubauth was installed using Certificate Manager as described at the beginning of this manual, it can be retrieved with:
    ```
    kubectl -n kubauth get secret kubauth-oidc-server-cert -o=jsonpath='{.data.ca\.crt}' | base64 -d
    ```
- The `rbac` subsection grants ArgoCD admin rights to members of the `argocd-admin` group. 
  Of course, access management can be defined in more detail using ArgoCD's RBAC system, but this is beyond the scope of this manual.

Add `--values values-kubauth.yaml` to your Helm command when deploying ArgoCD.
    
### Configuration with Secret

To better protect the client secret and avoid embedding the CA certificate, ArgoCD allows these values to be stored in a secret.

Modify the values file as follows:

???+ abstract "values-kubauth.yaml"

    ``` { .yaml .copy }
    configs:
      cm:
        url: "https://argocd.ingress.kubo6.mbp"
        oidc.config: |
          name: Kubauth
          issuer: https://kubauth.ingress.kubo6.mbp
          clientID: argocd
          clientSecret: $oidc.kubauth.clientSecret
          requestedScopes: ["openid", "profile", "email", "groups"]
          enablePKCEAuthentication: true
          # logoutURL: https://kubauth.ingress.kubo6.mbp/oauth2/logout
          rootCA: $oidc.kubauth.rootCA
           
      rbac:
        policy.csv: |
          g, argocd-admin, role:admin 
    ```

Update your Helm chart deployment.


The values must now be stored in a secret named `argocd-secret` (ArgoCD's hard-coded name) in the argocd namespace. In most cases, this secret already exists and contains other critical values. Care must be taken to append the new values without overwriting existing ones:

``` { .bash .copy }
kubectl -n argocd create secret generic argocd-secret \
  --from-literal='oidc.kubauth.clientSecret=argocd123' \
  --from-file=oidc.kubauth.rootCA=./ca.crt \
  --dry-run=client -o yaml | kubectl apply -f -
```

> You can ignore any warning messages.

This assumes `./ca.crt` contains the CA of the Kubauth issuer:

``` { .bash .copy }
cat ca.crt
```
```
-----BEGIN CERTIFICATE-----
MIIGSzCCBDOgAwIBAgIJAN3rPrHNIFfAMA0GCSqGSIb3DQEBCwUAMHUxCzAJBgNV
BAYTAkZSMQ4wDAYDVQQIDAVQYXJpczEOMAwGA1UEBwwFUGFyaXMxGTAXBgNVBAoM
.....
J2D93BTA8z5cto4I5oCtfQ2GjlkfEJG863gcIT/3ieu3AI/+LATFO7+TYVqYY8SI
wDQVxs1wOpHZOEekfO4fKW12BQ+f+K9m+j0ISFzUCA==
-----END CERTIFICATE-----
```

Refer to the ArgoCD documentation for more information.


## Usage

Once configuration is complete, a 'LOG IN VIA KUBAUTH' button should appear on the ArgoCD entry page.

You can log in using any defined user, such as `john`. Once logged in, you can verify your identity and group membership using the 'User Info' menu entry.

> ArgoCD displays the email address as the Username.

Although logged in, you won't have any permissions without additional configuration.

Now, add the user `john` to the `argocd-admin` group:

``` { .bash .copy }
kubectl apply -f - <<EOF
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-argocd-admin
  namespace: kubauth-users
spec:
  group: argocd-admin
  user: john
EOF
```

After logging out and logging back in, the user `john` will now be able to act as an ArgoCD administrator. You can create a new project to validate this.

## Logout URL

With the current configuration, when a user logs out from the ArgoCD UI, they are redirected to the landing page with the 'LOG IN VIA KUBAUTH' button and can log in again.

!!! note

    If the "Remember me" checkbox was checked, you will be logged in again automatically due to SSO. If you want to log in as a different user, you can cancel your SSO session using the `kc logout...` command.

Now, uncomment the `logoutURL: ...` entry in the values file "values-kubauth.yaml" and update your Helm deployment.

After this change, on logout, ArgoCD will clean your local context as before and redirect your browser to the configured logout URL. This has two effects:

- Clears your global SSO session
- Redirects you to a logout page listing the applications (or clients) defined in the OidcClient resources (currently only ArgoCD)

![logout](../assets/kubauth-logout2.png){ .center width="80%" }

For an OidcClient application to appear in this list, three attributes must be set. For ArgoCD:

```
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
...
spec:
  .....
  displayName: ArgoCD
  description: GitOps continuous delivery tool
  entryURL: https://argocd.ingress.kubo6.mbp/
```

!!! note

    Kubauth also exposes this page at the `/index` path:<br> 
    `https://kubauth.ingress.kubo6.mbp/index`

