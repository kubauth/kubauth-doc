# ArgoCD Integration


## Oidc client creation

As stated in [Configuration](../30-user-guide/110-configuration.md/#oidc-client-creation), a client application is defined as a Kubernetes Custom Resource.

So, a manifest like the following should be created:

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
      displayName: ArgoCD
      description: GitOps continuous delivery tool
      entryURL: https://argocd.ingress.kubo6.mbp/
    ```

> `argocd.ingress.kubo6.mbp` must be replaced by your ArgoCD entry point (In 2 locations)

- The sample password is 'argocd123'. Thus, the `hashedSecret` value is the result of a `kc hash argocd123` command.
- The `http://localhost:8085/auth/callback` entry in the `redirectURIs` list is for the `argocd` CLI command

Apply this manifest:

``` { .bash .copy }
kubectl apply -f client-argocd.yaml
```

## ArgoCD configuration

We will assume here ArgoCD is installed using the [community provided Helm chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd){:target="_blank"}.

> If ArgoCD is installed using another method, it should be easy to configure OIDC as described in the 
  [ArgoCD manual](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#existing-oidc-provider){:target="_blank"} with information provided here.   

This means the configuration is provided using Helm 'values' or 'values files'. As the general ArgoCD configuration is out of the scope of this manual,
we will will focus only on the OIDC relative section of the 'values file'.

There is two tricky points regarding ArgoCD OIDC configuration:

- How to provide the 'secret' value shared by ArgoCD and the Kubauth OIDC server
- How to provide the CA to validate the Kubauth OIDC issuer URL. 

### Basic configuration

In this case, the secret is provided in clear text, and the CA certificate is provided in place.

Create a values file like the following to be added on your Helm command when deploying ArgoCD (`.... --values values-kubauth.yaml....`).

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
> - `argocd.ingress.kubo6.mbp` must be replaced by your ArgoCD entry point.
> - `kubauth.ingress.kubo6.mbp` must be replaced by your Kubauth entry point (In 2 locations).

- We enable PKCE, as it is safest and supported by both party.
- The `logoutURL` parameter is here commented.. More on this below 
- The `rootCA` parameter is the CA of the Kubauth issuer. If Kubauth has been installed using Certificate Manager, 
  as described at the beginning of this manual, it can be retrieved with a command like:    
    ```
    kubectl -n cert-manager get secret cluster-odp-ca -o=jsonpath='{.data.ca\.crt}' | base64 -d
    ```
  > `cluster-odp-ca` must be replaced by `<your clusterIssuer>-ca`
  - The `rbac` subsection grant ArgoCD admin rights to the members of the group `argocd-admin`. 
    Of course, access management can be defined in more detail, using ArgoCD RBAC system, but this is out of the scope of this manuel.

Add `--values values-kubauth.yaml` on your Helm command deploying ArgoCD.
    
### Configuration with secret

In order to better protect the clientSecret, and to avoid in place CA certificate, ArgoCD allow these values to be set in a secret.

Modify the 'values file' like the following:

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

And update your Helm chart deployment.


The values must now be stored in a secret named `argocd-secret` (ArgoCD hard coded name) in the argocd namespace. 
But in most case, this secret exists and already contains some critical other values.
So, care must be taken to just append the new values:

``` { .bash .copy }
kubectl -n argocd create secret generic argocd-secret \
  --from-literal='oidc.kubauth.clientSecret=argocd123' \
  --from-file=oidc.kubauth.rootCA=./ca.crt \
  --dry-run=client -o yaml | kubectl apply -f -
```

> Don't care about warning message.

This assuming `./ca.crt` contains the CA of the Kubauth issuer

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

The configuration completed, a 'LOG IN VIA KUBAUTH' button must appears on the ArgoCD entry page.

You can log in using whatever defined user. Let's say `john`. Once logged, you can verify who we are, and the group we belong to, using 'User Info' menu entry.

> ArgoCD display the email adresse as the Username. 

Although logged, you can't do anything, without more permission. 

Now, add the user `john` to the group `argocd-admin`

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

And, after logout and login back, the user `john` will now be able to act as an ArgoCD administrator. You can create a new project to validate this.

## Logout URL

With the current configuration, when a user log out from ArgoCD UI, it is redirected to the landing page with the 'LOG IN VIA KUBAUTH' and can log again.

!!! notes

    If the `Remember me` checkbox has been checked, you will be log in again automatically by the magic of SSO. If you want to log under another user, 
    you can cancel your SSO session using a <br>`kc logout....` command.

Now, uncomment the `logoutURL: ...` entry in the values file "values-kubauth.yaml" and update your Helm deployment.

Now, on logout, ArgoCD will clean your local context, as previously and redirect your browser on the configured logoutURL. This will have two consequences:

- Cleanup your global SSO session
- Redirect you on a logout page, listing somme of the application (or client) listed on the OidcClients resources (Here only ArgoCD)

![logout](../assets/kubauth-logout2.png){ .center width="80%" }

For an OidcClient application to be presented on this list, three attributes must be set. For ArgoCD:

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

!!! Notes

    Kubauth expose also this page on the `/index` path:<br> 
    `https://kubauth.ingress.kubo6.mbp/index`

