# First usage

## User creation

For Kubauth, as a first approach, users are defined as Kubernetes Custom Resources.

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
```bash
NAME   USERNAME   EMAILS                    UID   COMMENT   DISABLED   AGE
jim                                                                    82m
john   John DOE   ["johnd@mycompany.com"]                              67m
```

!!! note
    We better provide the fully qualified name of the resource, as `user` may refer to several Kind of CRD.<br>
    For this reason, an alias has also be defined for kubauth's users:
    ``` { .bash .copy }
    kubectl -n kubauth-users get kusers
    ```

### Password hash

The `kc` cli tool provide a subcommand to generate the hash of a password:

``` { .bash .copy }
kc hash jim123
```

```bash
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

## Client creation

In OIDC terminology, a 'client' is an application referenced in an OIDC server.

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
- The redirectURIs must be adjusted for each application. The value here is specific to the test client included in the `kc` cli. See below.
- The grantTypes list define which authorization flow will be accepted by this client definition.
- The responseTypes list define what kind of tokens or credentials the client can expects to receive from the authorization endpoint after the user authenticates.
- The scopes list define which scope can be requested by the application. 
- This client is defined as public. As such no client secret need to be provided. For non-public client, a secret in hashed form must be provided, as in the commented line. 
  Use the `kc hash` command described above to generate.

!!! warning

    On the current version, claims are not filtered by scope. In other words, all claims of a user are provided in the OIDC token.

Apply this manifest:

``` { .yaml .copy }
kubectl apply -f client-public.yaml
```

You can list existing OIDC client:

``` { .yaml .copy }
kubectl -n kubauth-oidc get oidcclients
```

```bash
NAME     PUB.   DISPLAY   DESCRIPTION                 LINK   AGE
public   true             A test OIDC public client          25m
```

## logins

The Kubauth companion CLI application provide an embedded OIDC client application. Beside being used as here for testing installation, 
its aim is to provide a tool to fetch Access or/and OIDC token, able to be injected in whatever application.

Launch the following command, after adjusting the issuerURL;

```
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public
```

Your browser should open on the kubauth login page

![login](./assets/kubauth-login.png)
```
If browser doesn't open automatically, visit: http://127.0.0.1:9921
```



```
Access token: ory_at_xLUfAhEGpFVWpMLdNEDZAj94hHFrHWjgOYB5g0Leh_k.0rgIzRGFOiIeGsMKnIZ74QL4Ve5vVOuEZyhA0402u8Y
Refresh token: ory_rt_nU9NBZs4NtKTxVYVko1aqlJkAMF5MLBYjfiZbhVt9aE.THwsnTlqzIsWo5O1NAf1EbDhz7HdaqVHHwSTkWxrkqY
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY3ZmY5MzUxMzZiMSIsInR5cCI6IkpXVCJ9.eyJhdF9oYXNoIjoiaGNBY2dtdmdBekJlSGgyODlkWHF3USIsImF1ZCI6WyJwdWJsaWMiXSwiYXV0aF90aW1lIjoxNzYxMzI2MDg2LCJhenAiOiJwdWJsaWMiLCJleHAiOjE3NjEzMjk2ODYsImlhdCI6MTc2MTMyNjA4NiwiaXNzIjoiaHR0cHM6Ly9rdWJhdXRoLmluZ3Jlc3Mua3VibzYubWJwIiwianRpIjoiZDZhYjkwODMtYTEzMi00YTNiLTlmMWItMzM2NWFhOTQ5MjQ2IiwicmF0IjoxNzYxMzI2MDg2LCJzdWIiOiJqaW0ifQ.Q8ZkF33jsUJDqLH98uqRgrFa2nwioRP1TO9n6QjX9XFr-1WmsKk9nEeHGAiASb1brQ3cSAmK8ta7fX3lBLBlszxmeVZRzq5Qvg0N8nqvlV3C4CAiv6lEl6_-y6wBoQOWN9OhNhYU6wFjpNNDTx_RW0329i9TYVxaygw58wJGCX_1F5-PY0NG74n_1sdZxYop7s5GnZ0_9S9-DEI-LNR2MMx-oVH4lpGjV5dhGRvZS0l4tMm2C7J6Yx_JoTQoZfWwPI0GGf2smZZ-C2ieB5Wj0b19fgrafuexHW9yeejI51j6WZs_eDqUwvCIf52_yAvokA4SiW4PW8Eod9fX-JuwJQ
Expire in: 59m59s

```

```
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public
```

## Claims


## 



## SSO session.


## Audit