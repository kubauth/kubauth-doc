# Configuration

Basic Kubauth configuration is based on:

- Helm chart variable
- Users and Groups as Kubernetes Custom Resources
- Client Application as Kubernetes Custom Resources.

We suggest you apply the sample configuration described below as this will be used in subsequent chapters.

## User creation

With Kubauth users may be defined as Kubernetes Custom Resources.

Here is a sample manifest which will create two users:

???+ abstract "users.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: User
    metadata:
      name: jim
      namespace: kubauth-users
    spec:
      passwordHash: "$2a$12$yJEo9EoYn/ylGS4PCamfNe8PReYH9IPumsw7rMTDi3glZjuA7dXMm"  # jim123
    
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: User
    metadata:
      name: john
      namespace: kubauth-users
    spec:
      passwordHash: "$2a$12$YjalsuGc6uuWtQqVuU/O.eW9L6QGU/vHk2wpvle4dsS7hC2Ic1F.q"  # john123
      name: John DOE
      claims:
        office: 208G
      emails:
        - johnd@mycompany.com
    ```

- The resource name is the user login.
- User must be defined in a specific namespace (`kubauth-users`). This to allow control using k8s rbac.
- The only mandatory user attribute is its password, provided as a hash.
- A `name` attribute can be set with the user full name.
- A list of emails can be associated to each user.
- To each user can be associated a list of supplementary OIDC claims, which will be merged with the system provided one. More on this below

Deploy the manifest on your clusters

``` { .bash .copy }
kubectl apply -f users.yaml 
```

You can now list the newly created users

``` { .bash .copy }
kubectl -n kubauth-users get users.kubauth.kubotal.io
```
```
NAME   USERNAME   EMAILS                    UID   COMMENT   DISABLED   AGE
jim                                                                    82m
john   John DOE   ["johnd@mycompany.com"]                              67m
```

!!! note
    We better provide the fully qualified name of the resource, as `user` may refer to several other Kind of CRD.<br>
    For this reason, an alias (`kuser`) has also be defined for kubauth's users:
    ``` { .bash .copy }
    kubectl -n kubauth-users get kusers
    ```

### Password hash

The `kc` CLI tool provide a subcommand to generate the hash of a password:

``` { .copy }
kc hash jim123
```

```
Secret: jim123
Hash: $2a$12$nSplFbbsGoI7LXdhJrKx0erRmIv.zkTftG82sQZA0.v3l1eCf.ey.

Use this hash in your User 'passwordHash' field

Example:
  apiVersion: kubauth.kubotal.io/v1alpha1
  kind: User
  .....
  spec:
    passwordHash: "$2a$12$nSplFbbsGoI7LXdhJrKx0erRmIv.zkTftG82sQZA0.v3l1eCf.ey."

Or in your OidcClient 'hashedSecret' field

Example:
  apiVersion: kubauth.kubotal.io/v1alpha1
  kind: OidcClient
  .....
  spec:
    hashedSecret: "$2a$12$nSplFbbsGoI7LXdhJrKx0erRmIv.zkTftG82sQZA0.v3l1eCf.ey."
```

Just cut/paste appropriate line in your user manifest.

### Namespace

If, for any reason, you need to change the namespace storing users resources definition, this can be modified by setting a helm chart configuration value: 

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      issuer: https://kubauth.ingress.kubo6.mbp
      postLogoutURL: https://kubauth.ingress.kubo6.mbp/index
      ....

    ucrd:
      namespace: kubauth-users
      createNamespace: true

    ```

## OIDC Client creation

In OIDC terminology, a 'client' is an application delegating user's authentication to an OIDC server. As such, it must be referenced in the server.

With Kubauth, a client application is defined as a Kubernetes Custom resource.

Here is a first sample:

???+ abstract "users.yaml"

    ``` { .yaml .copy }
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: public
      namespace: kubauth-oidc
    spec:
      redirectURIs:
        - "http://127.0.0.1:9921/callback"
      grantTypes: [ "refresh_token", "authorization_code" ]
      responseTypes: [ "id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token" ]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access" ]
      description: A test OIDC public client
      public: true
    
      # hashedSecret: "$2a$12$9vdc.xb3Zf4ts/C2pSvIOuGmFiv0EStBJWslaaycavblaIjYZ9Mia"
      # accessTokenLifespan: 1h
      # refreshTokenLifespan: 1h
      # idTokenLifespan: 1h
    ```

- The resource name is the client ID.
- The `redirectURIs` list must be adjusted for each application. The value here is specific to the test client included in the `kc` cli. See below.
- The `grantTypes` list define which authorization flow will be accepted by this client definition.
- The `responseTypes` list define what kind of tokens or credentials the client can expects to receive from the authorization endpoint after the user authenticates.
- The `scopes` list define which scope can be requested by the application. 
- This client is defined as `public`. As such no client secret need to be provided.<br>For non-public client, a `secret` in hashed form must be provided, as in the commented line. 
  Use the `kc hash` command described previously to generate it.

Apply this manifest:

``` { .bash .copy }
kubectl apply -f client-public.yaml
```

You can list existing OIDC client:

``` { .bash .copy }
kubectl -n kubauth-oidc get oidcclients
```

```
NAME     PUB.   DISPLAY   DESCRIPTION                 LINK   AGE
public   true             A test OIDC public client          25m
```

### Namespace

If, for any reason, you need to change the namespace storing clients resources definition, this can be modified by setting a helm chart configuration value:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      issuer: https://kubauth.ingress.kubo6.mbp
      postLogoutURL: https://kubauth.ingress.kubo6.mbp/index
      ....
      clients:
        createNamespace: true
        namespace: kubauth-oidc
    ```
