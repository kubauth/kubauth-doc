# Users Configuration

## User Creation

With Kubauth, users can be defined as Kubernetes Custom Resources.

> With this configuration, Kubauth operates in a fully autonomous mode. Handling users defined in external identity providers is covered in a later chapter.

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

### User Groups

Kubauth also supports user group management, which is covered in a [dedicated chapter](150-users-groups.md).

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

## Helm Companion Chart

For convenience, the `kubauth-users` Helm chart packages `User`, `Group`, `GroupBinding`, `RoleBinding` and `ClusterRoleBinding` resources behind a single values file. This is well suited to GitOps workflows where the user catalog must be versioned alongside the rest of the cluster configuration.

A typical values file looks like:

???+ abstract "values-users.yaml"

    ``` { .yaml .copy }
    users:
      - login: jim
        passwordHash: "$2a$12$8Ews1KmZO/79WcWzlTjhyOCzCm6G61n1RbpNw5oFlLO0lcnT7RJ7S"  # jim123
    
      - login: john
        name: John DOE
        passwordHash: "$2a$12$YjalsuGc6uuWtQqVuU/O.eW9L6QGU/vHk2wpvle4dsS7hC2Ic1F.q"  # john123
        emails:
          - johnd@mycompany.com
        claims:
          office: 208G
        comment: "The CEO"
    
    groups:
      - name: ops
        comment: "Operations team"
        claims:
          accessProfile: p24x7
    
    groupBindings:
      - user: jim
        group: devs
      - user: john
        group: devs
      - user: john
        group: ops
    
    roleBindings:
      - name: john-tenant1-admin
        namespace: tenant1
        clusterRole: admin
        users:
          - john
    
    clusterRoleBindings:
      - name: ops-cluster-readers
        clusterRole: view
        groups:
          - ops
    ```

Each `users`, `groups` and `groupBindings` entry generates the corresponding Kubauth Custom Resource in the release namespace. `roleBindings` and `clusterRoleBindings` produce standard Kubernetes `RoleBinding` and `ClusterRoleBinding` objects, with their `subjects` populated from the listed `users` and `groups`. This lets you tie a Kubauth identity to cluster permissions in the very same file.

Deploy it with:

``` { .bash .copy }
helm -n kubauth-users upgrade -i kubauth-users \
    --values ./values-users.yaml \
    oci://quay.io/kubauth/charts/kubauth-users \
    --version 0.3.0 \
    --create-namespace --wait
```

!!! note

    The chart targets the namespace passed to `helm` (here `kubauth-users`). Make sure this matches the value of `ucrd.namespace` configured for the Kubauth main chart, otherwise the resources will be created in a namespace the OIDC controller does not watch.
