
# OIDC Clients Configuration

## Client Creation

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
- This client is defined as `public`, so no client secret is required. See below for confidential (non-public) clients.

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

As shown above, the `CLIENT_ID` — the identifier used by client applications to refer to this client — is the Kubernetes resource name (`public`).

### Test it

To test this OIDC client immediately, refer to the [next chapter](120-tokens-and-claims.md).

## OidcClient and Kubernetes Namespaces

Let's now create another client in a different namespace. 

First create a new namespace:

``` { .bash .copy }
kubectl create namespace tenant1
```

Then, using the same client manifest, create another OidcClient resource in this namespace:

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

The `CLIENT_ID` for the second client is constructed using the pattern <br>`<namespace>-<k8sResourceName>`. 

This introduces namespace-based scoping into the otherwise flat OIDC CLIENT_ID namespace.

### Multi-Tenancy Scenario

This feature enables multi-tenancy configurations. 

In such a configuration, a super-admin creates a tenant consisting of one or more namespaces, then grants permissions to one or more subjects (User, Group, or ServiceAccount) acting as tenant administrators.

In practice, this involves creating a `RoleBinding` that binds the tenant administrator to the `kubauth-oidc-client-admin` ClusterRole, allowing them to create OidcClient resources. 

> The  `kubauth-oidc-client-admin` ClusterRole was created by initial Kubauth installation.

Since this is a `RoleBinding` rather than a `ClusterRoleBinding`, the tenant administrator can only create OidcClient resources in their own namespace. The namespace prefix in the CLIENT_ID prevents clashes with other tenants. 

### The Privileged Namespace

The first client we created in this chapter does not have its CLIENT_ID prefixed.

This is because it was created in a special 'privileged' namespace, which defaults to the Helm release namespace.

Using only the privileged namespace to define OidcClient resources provides a more conventional approach, where client definitions are treated as OIDC configuration operations reserved for the global system administrator. This also avoids CLIENT_ID name mangling.

An alternate value of this 'privileged' namespace can be defined at initial installation, in the Helm `values.yaml` file: 

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      ....
      clientPrivilegedNamespace: oidc-clients
      ....

    ```

## Confidential Client

In most cases, OIDC clients must be protected by a shared secret between Kubauth and the application.

The secret value is stored in a Kubernetes Secret, which is then referenced by the OidcClient resource.

Here is a confidential (non-public) variation of our OIDC test client:

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

- The `public: true` attribute has been removed (or set to `false`). 
- A `secrets` list references one or more Kubernetes Secrets. These secrets must reside in the same namespace as the OidcClient resource.

> Supporting multiple valid secrets enables seamless secret rotation.

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

As expected, the newly created OidcClient is in an error state because the referenced secret does not yet exist.

Create and apply the secret:

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

Verify that the OidcClient is now in READY state:

``` { .bash .copy }
kubectl get --all-namespaces oidcclients
```

```
NAMESPACE   NAME      CLIENT_ID        STATUS   MESSAGE   PUB.    DESCRIPTION                  DISPLAY   LINK   AGE
kubauth     private   private          READY    OK        false   A test OIDC private client                    9m25s
kubauth     public    public           READY    OK        true    A test OIDC public client                     10m
tenant1     public    tenant1-public   READY    OK        true    A test OIDC public client                     9m57s
```


### Alternative Secret Formats

As with any Kubernetes Secret, the value (here `secret2`) can be provided in base64 encoding:

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

For additional obfuscation, the value can be hashed using the same tool as for user passwords:

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

In this case, a `hashed: true` flag must be set on the corresponding secret reference:


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

This OidcClient will accept any of `secret1`, `secret2`, or `secret3` as the client secret.  


## Explicit Client ID

Kubauth also supports explicitly setting the OIDC `client_id` value:

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

    In this case, there is no namespace decoration. It is up to administrators to ensure the global uniqueness of the `clientId` value.

Create the `project32` namespace and apply this manifest:


``` { .bash .copy }
kubectl create namespace project32
```

``` { .bash .copy }
kubectl apply -f client-public-prj32.yaml
```

Verify the result:

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