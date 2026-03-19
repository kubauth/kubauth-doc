# Users configuration

## User Creation

With Kubauth, users can be defined as Kubernetes Custom Resources.

> With this kind of configuration, Kubauth works in a fully autonomous way. We will see later how to handle users defined on other external Identity Providers

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
      passwordHash: "$2a$12$8Ews1KmZO/79WcWzlTjhyOCzCm6G61n1RbpNw5oFlLO0lcnT7RJ7S"  # jim123
    
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

> We recommend applying the sample configuration described below, as it will be referenced in subsequent chapters.

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
Hash: $2a$12$8Ews1KmZO/79WcWzlTjhyOCzCm6G61n1RbpNw5oFlLO0lcnT7RJ7S
```

Copy and paste the appropriate value into your user manifest.

### User's Groups

Kubauth can also manage groups of users. This is the subject of a [dedicated chapter](150-users-groups.md)

### Namespace

If you need to change the namespace for user resource storage, modify the `ucrd.namespace` in the Helm chart configuration:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      issuer: https://kubauth.mycluster.mycompany.com
      postLogoutURL: https://kubauth.mycluster.mycompany.com/index
      ....

    ucrd:
      namespace: kubauth-users
      createNamespace: true

    ```
