# Configuration

Kubauth configuration is based on:

- Helm chart variables
- Users and Groups defined as Kubernetes Custom Resources
- Client Applications defined as Kubernetes Custom Resources

We recommend applying the sample configuration described below, as it will be referenced in subsequent chapters.

## User Creation

With Kubauth, users can be defined as Kubernetes Custom Resources.

Here is a sample manifest that creates two users:

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
- Users must be defined in a specific namespace (`kubauth-users`) to enable access control using Kubernetes RBAC.
- The only mandatory user attribute is the password, provided as a bcrypt hash.
- A `name` attribute can be set to specify the user's full name.
- A list of email addresses can be associated with each user.
- Each user can have a set of supplementary OIDC claims defined in `spec.claims`, which will be merged with system-provided claims. More details on this below.

Deploy the manifest on your cluster:

``` { .bash .copy }
kubectl apply -f users.yaml 
```

List the newly created users:

``` { .bash .copy }
kubectl -n kubauth-users get users.kubauth.kubotal.io
```
```
NAME   USERNAME   EMAILS                    UID   COMMENT   DISABLED   AGE
jim                                                                    82m
john   John DOE   ["johnd@mycompany.com"]                              67m
```

!!! note
    We provide the fully qualified resource name, as `user` may refer to other CRD types.<br>
    For convenience, an alias (`kuser`) has also been defined for Kubauth users:
    ``` { .bash .copy }
    kubectl -n kubauth-users get kusers
    ```

### Password Hash

The `kc` CLI tool provides a subcommand to generate password hashes:

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

Copy and paste the appropriate line into your user manifest.

### Namespace

If you need to change the namespace for user resource storage, modify the Helm chart configuration:

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

## OIDC Client Creation

In OIDC terminology, a 'client' is an application that delegates user authentication to an OIDC server. As such, it must be registered with the server.

With Kubauth, client applications are defined as Kubernetes Custom Resources.

Here is an initial example:

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
- The `redirectURIs` list must be configured for each application. The value shown here is specific to the test client included in the `kc` CLI (see below).
- The `grantTypes` list defines which authorization flows are accepted by this client.
- The `responseTypes` list defines what types of tokens or credentials the client can expect from the authorization endpoint after user authentication.
- The `scopes` list defines which scopes can be requested by the application.
- This client is defined as `public`, so no client secret is required.<br>For confidential clients, a hashed `secret` must be provided, as shown in the commented line. Use the `kc hash` command described above to generate it.

Apply this manifest:

``` { .bash .copy }
kubectl apply -f client-public.yaml
```

List existing OIDC clients:

``` { .bash .copy }
kubectl -n kubauth-oidc get oidcclients
```

```
NAME     PUB.   DISPLAY   DESCRIPTION                 LINK   AGE
public   true             A test OIDC public client          25m
```

> This client will be used in the next chapter to test tokens and claims.


### Namespace

If you need to change the namespace for client resource storage, modify the Helm chart configuration:

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
