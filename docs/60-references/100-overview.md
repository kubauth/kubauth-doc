# Overview

This section provides comprehensive reference documentation for Kubauth's Kubernetes Custom Resource Definitions (CRDs).

## Custom Resources

Kubauth stores all configuration and user data as native Kubernetes resources, providing a cloud-native, scalable solution without requiring an external database.

### Core Resources

- **[OidcClient](110-oidcclient.md)** - OIDC client application definitions
- **[User](120-user.md)** - User account definitions with authentication credentials
- **[Group](130-group.md)** - Group definitions with shared claims
- **[GroupBinding](140-groupbinding.md)** - User-to-group associations
- **[UpstreamProvider](150-upstreamprovider.md)** - External OIDC providers and the internal login form

## API Group and Version

All Kubauth resources use the following API group and version:

- **API Group:** `kubauth.kubotal.io`
- **Version:** `v1alpha1`

## Resource Organization

### Namespaces

Kubauth resources are namespaced and typically organized as follows:

| Resource Type      | Default Namespace                | Configurable via                          |
|--------------------|----------------------------------|-------------------------------------------|
| `OidcClient`       | Helm release namespace (`kubauth`) | `oidc.clientPrivilegedNamespace`         |
| `User`             | `kubauth-users`                  | `ucrd.namespace`                          |
| `Group`            | `kubauth-users`                  | `ucrd.namespace`                          |
| `GroupBinding`     | `kubauth-users`                  | `ucrd.namespace`                          |
| `UpstreamProvider` | Helm release namespace (`kubauth`) | `oidc.upstreamProviderNamespace`         |

`OidcClient` and `UpstreamProvider` are watched in **one specific namespace** for cluster-wide effect; `User`, `Group` and `GroupBinding` are watched in the namespace pointed at by `ucrd.namespace`.

`OidcClient` is the exception: it can be created in **any** namespace. Clients defined outside the privileged namespace simply get their `client_id` prefixed with the namespace name (see the [OIDC Clients Configuration](../30-user-guide/115-oidc-clients-configuration.md) chapter for the multi-tenancy pattern).

## Common Patterns

### Accessing Resources

#### Fully Qualified Names

Since some resource names (like `User`) are common and may conflict with other CRDs, use fully qualified names:

```bash
kubectl -n kubauth-users get users.kubauth.kubotal.io
```

#### Using Short Names and Aliases

For convenience, Kubauth provides several shortcuts:

```bash
# User
kubectl -n kubauth-users get kusers

# Group
kubectl -n kubauth-users get kgroups

# GroupBinding
kubectl -n kubauth-users get gb

# UpstreamProvider
kubectl -n kubauth get upstreams
```

### Listing Resources

```bash
# List all OIDC clients in every namespace (multi-tenancy view)
kubectl get --all-namespaces oidcclients

# List all users
kubectl -n kubauth-users get users.kubauth.kubotal.io

# List all groups
kubectl -n kubauth-users get groups.kubauth.kubotal.io

# List all group bindings
kubectl -n kubauth-users get groupbindings

# List all upstream providers
kubectl -n kubauth get upstreams
```

### Describing Resources

```bash
# Describe an OIDC client
kubectl -n kubauth describe oidcclient myapp

# Describe a user
kubectl -n kubauth-users describe user john

# Describe a group
kubectl -n kubauth-users describe group developers

# Describe an upstream provider
kubectl -n kubauth describe upstream keycloak
```

## Security Considerations

### Access Control

Use Kubernetes RBAC to control access to Kubauth resources. Kubauth pre-creates the following ClusterRoles to make this easier:

| ClusterRole                            | Purpose                                                                       |
|----------------------------------------|-------------------------------------------------------------------------------|
| `kubauth-oidc-client-admin`            | Manage `OidcClient` resources in a given namespace (tenant administrators).   |
| `kubauth-oidc-client-controller`       | Used internally by the OIDC controller to watch clients (do not bind manually). |

A typical RBAC snippet for a user manager:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: kubauth-user-manager
  namespace: kubauth-users
rules:
  - apiGroups: ["kubauth.kubotal.io"]
    resources: ["users", "groupbindings"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
```

### Secret Management

- **User passwords** are always stored as bcrypt hashes through the `User.spec.passwordHash` field. Use `kc hash <password>` to generate the value.
- **OIDC client secrets** are stored in standard Kubernetes `Secret` objects referenced by `OidcClient.spec.secrets`. Multiple entries enable rotation, and the optional `hashed: true` flag lets you store bcrypt hashes instead of clear-text values.
- **Upstream client secrets** are stored in standard Kubernetes `Secret` objects referenced by `UpstreamProvider.spec.clientSecret`.

## Best Practices

### Resource Naming

- Use descriptive, lowercase names with hyphens.
- For `GroupBinding`, follow the pattern `<username>-<groupname>` to make bindings easy to find.
- For `OidcClient`, remember that the resource name becomes part of the `client_id` (with a namespace prefix when created outside the privileged namespace).

## Examples Repository

Complete walkthrough examples for every resource can be found throughout the documentation:

- [Users Configuration](../30-user-guide/110-users-configuration.md)
- [OIDC Clients Configuration](../30-user-guide/115-oidc-clients-configuration.md)
- [User Groups](../30-user-guide/150-users-groups.md)
- [Upstream Providers](../30-user-guide/200-upstream-providers.md)
- [Applications Integration](../40-applications-integration/110-argocd.md)
- [Kubernetes Integration](../50-kubernetes-integration/110-overview.md)

## Additional Resources

- [Kubauth GitHub Repository](https://github.com/kubauth/kubauth){:target="_blank"}
