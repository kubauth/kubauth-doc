
# OIDC clients configuration

## Creation

In OIDC terminology, a 'client' is an application that delegates user authentication to an OIDC server. As such, it must be registered with the server.

With Kubauth, client applications are defined as Kubernetes Custom Resources.

Here is an initial example:

???+ abstract "client-public.yaml"

    ``` { .yaml .copy }
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: public
    spec:
      redirectURIs:
        - "http://127.0.0.1:9921/callback"
      grantTypes: [ "refresh_token", "authorization_code" ]
      responseTypes: [ "id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token" ]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access" ]
      description: A test OIDC public client
      public: true
    
      # accessTokenLifespan: 1h
      # refreshTokenLifespan: 1h
      # idTokenLifespan: 1h
    ```

- The `redirectURIs` list must be configured for each application. The value shown here is specific to the test client included in the `kc` CLI (see next chapter).
- The `grantTypes` list defines which authorization flows are accepted by this client.
- The `responseTypes` list defines what types of tokens or credentials the client can expect from the authorization endpoint after user authentication.
- The `scopes` list defines which scopes can be requested by the application.
- This client is defined as `public`, so no client secret is required. See below for non-public client

Apply this manifest in the **Kubauth release namespace** (Here, `kubauth`):

``` { .bash .copy }
kubectl apply -n kubauth -f client-public.yaml
```

List existing OIDC clients:

``` { .bash .copy }
kubectl get --all-namespaces oidcclients
```

```
NAMESPACE   NAME     CLIENT_ID   STATUS   MESSAGE   PUB.   DESCRIPTION                 DISPLAY   LINK   AGE
kubauth     public   public      READY    OK        true   A test OIDC public client                    7s
```

> This client will be used in the next chapter to test tokens and claims.

As you can see, the `CLIENT_ID`, the identifier used by the client application to refer to this client is the name of the k8s resources (`public`)

### Test it

If you want to test immediately this OIDC client, you can refer to the [next chapter](120-tokens-and-claims.md)

## OidcClient and K8s namespaces

We will now create another client in another namespace. 

First create a new namespace:

``` { .bash .copy }
kubectl create namespace tenant1
```

Then, using the same client manifest, create another OidcClient resource in this namespace

``` { .bash .copy }
kubectl apply -n tenant1 -f client-public.yaml
```

Now, list existing OIDC clients:

``` { .bash .copy }
kubectl get --all-namespaces oidcclients
```

```
NAMESPACE   NAME     CLIENT_ID        STATUS   MESSAGE   PUB.   DESCRIPTION                 DISPLAY   LINK   AGE
kubauth     public   public           READY    OK        true   A test OIDC public client                    32s
tenant1     public   tenant1-public   READY    OK        true   A test OIDC public client                    5s
```

We can see the `CLIENT_ID` for our second client is build with the pattern <br>`<namespace>-<k8sResourceName>`. 

This allows to add some kind of namespacing in the unique space of the OIDC CLIENT_IDs.

### Multi-tenancy scenario.

This feature will allow to setup multi-tenancy configuration. 

In such configuration, a super-admin create a 'tenant', made of one (or several) namespace.  This super-admin will then give some permissions to one or several Subject 
(User, Group or ServiceAccount) acting as tenant-admin.

In our case, it will setup a `RoleBinding` to bind the tenant-admin to the ClusterRole `kubauth-oidc-client-admin` to allow tenant-admin to create
OidcClient resources. 

> The  `kubauth-oidc-client-admin` ClusterRole was created by initial Kubauth installation.

As it is a `RoleBinding`, not a `ClusterRoleBinding`, the tenant-admin will be limited to create OidcClient only in its namespace. 
And the addition of the namespace in the CLIENT_ID will prevent any clashes with other tenants. 

### The 'Privileged' namespace

The first client we created in the chapter don't have it's CLIENT_ID prefixed

This is because it was created in a specific `privileged' namespace. Which is by default the Release namespace of the installation.

Using only the 'privileged' namespace to define OidcClient will allow a more standard approach, where OidcClient definitions are considered as OIDC configuration operations
and, as such, reserved to the global system administrator. And also to not be bothered by CLIENT_ID name mangling.

An alternate value of this 'privileged' namespace can be defined at initial installation, in the Helm `values.yaml` file: 

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      ....
      clientPrivilegedNamespace: oidc-clients
      ....

    ```

## Private client

In most case, for obvious security reasons, the OIDC client must be protected by a secret shared between Kubauth and the application.

This secret value will be stored in a k8s secret. And this secret will be referenced by the OidcClient resource.

Here is a 'private' variation of our OIDC test client:

???+ abstract "client-private.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: private
    spec:
      redirectURIs:
        - "http://127.0.0.1:9921/callback"
      grantTypes: [ "refresh_token", "authorization_code" ]
      responseTypes: [ "id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token" ]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access" ]
      description: A test OIDC private client
      secrets:
        - name: oidc-client-secret
          key: clientSecret
    
    ```

- The `public: true` attribute has been removed (Or set to `false`) 
- There is a `secrets` list, which will reference one or several k8s secrets. These secret(s) must be in the same namespace as the OidcClient resources.

> Being able to have more than one valid secrets allow for easy secret rotation.

Apply this manifest:

``` { .bash .copy }
kubectl apply -n kubauth -f client-private.yaml
```

And check it:

``` { .bash .copy }
kubectl get --all-namespaces oidcclients
```

```
NAMESPACE   NAME      CLIENT_ID        STATUS   MESSAGE                                               PUB.    DESCRIPTION                  DISPLAY   LINK   AGE
kubauth     private   private          ERROR    unable to fetch secret 'kubauth:oidc-client-secret'   false   A test OIDC private client                    31s
kubauth     public    public           READY    OK                                                    true    A test OIDC public client                     90s
tenant1     public    tenant1-public   READY    OK                                                    true    A test OIDC public client                     63s
```

Obviously, the newly created OidcClient is missing the secret.

So create and apply it:

???+ abstract "client-secret.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: oidc-client-secret
    type: Opaque
    stringData:
      clientSecret: "secret1"
    ```

``` { .bash .copy }
kubectl apply -n kubauth -f client-secret.yaml
```

And check new the OidcClient is in READY state:

``` { .bash .copy }
kubectl get --all-namespaces oidcclients
```

```
NAMESPACE   NAME      CLIENT_ID        STATUS   MESSAGE   PUB.    DESCRIPTION                  DISPLAY   LINK   AGE
kubauth     private   private          READY    OK        false   A test OIDC private client                    9m25s
kubauth     public    public           READY    OK        true    A test OIDC public client                     10m
tenant1     public    tenant1-public   READY    OK        true    A test OIDC public client                     9m57s
```


### Alternate secret form

As with every k8s secret, the value (here `secret2`) can be defined in base64

```
echo -n secret2 | base64
```

???+ abstract "client-secret2.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: oidc-client-secret2
    type: Opaque
    data:
      clientSecret: c2VjcmV0Mg==  #  echo -n secret2 | base64
    ```

And, to have a better obfuscation, the value could be hashed, with the same tool used for the User password.

```
kc hash secret3 -r | base64
```

???+ abstract "client-secret3.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: oidc-client-secret3
    type: Opaque
    data:
      clientSecret: "JDJhJDEyJDZEZC9oVWVwUy9udkNvU2ZsanhDM08xS2R3QU1UM0RabE9abDQuVzU1Mk5NRkVUZ0hxZkZh"  #  kc hash secret3 -r | base64
    ```

In this last case, a `hashed: true` flag must be set in the secret reference:


???+ abstract "client-private.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: private
    spec:
      redirectURIs:
        - "http://127.0.0.1:9921/callback"
      grantTypes: [ "refresh_token", "authorization_code" ]
      responseTypes: [ "id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token" ]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access" ]
      description: A test OIDC private client
      secrets:
        - name: oidc-client-secret
          key: clientSecret
        - name: oidc-client-secret2
          key: clientSecret
        - name: oidc-client-secret3
          key: clientSecret
          hashed: true
    ```

This OidcClient will accept one of `secret1`, `secret2` or `secret3` as client secret value.  


## Explicit client_id

Kubauth also support the explicit setting of the OIDC `client_id` value:

???+ abstract "client-public-prj32.yaml"

    ``` { .yaml .copy }
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: public
      namespace: project32
    spec:
      clientId: prj32-public
      redirectURIs:
        - "http://127.0.0.1:9921/callback"
      grantTypes: [ "refresh_token", "authorization_code" ]
      responseTypes: [ "id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token" ]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access" ]
      description: A test OIDC public client
      public: true
    ```

!!! warning

    In such case, there is no namespace decoration anymore. It up to all administrators to ensure the global uniqness of the clientId value.

Create the `project32` namespace and apply this manifest:


``` { .bash .copy }
kubectl create namespace project32
```

``` { .bash .copy }
kubectl apply -f client-public-prj32.yaml
```

And check the result:

``` { .bash .copy }
kubectl get --all-namespaces oidcclients
```

```
NAMESPACE   NAME      CLIENT_ID        STATUS   MESSAGE   PUB.    DESCRIPTION                  DISPLAY   LINK   AGE
kubauth     private   private          READY    OK        false   A test OIDC private client                    44m
kubauth     public    public           READY    OK        true    A test OIDC public client                     45m
project32   public    prj32-public     READY    OK        true    A test OIDC public client                     4m
tenant1     public    tenant1-public   READY    OK        true    A test OIDC public client                     44m

```