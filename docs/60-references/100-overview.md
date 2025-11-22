# Overview

This section provides comprehensive reference documentation for Kubauth's Kubernetes Custom Resource Definitions (CRDs).

## Custom Resources

Kubauth stores all configuration and user data as native Kubernetes resources, providing a cloud-native, scalable solution without requiring an external database.

### Core Resources

- **[OidcClient](110-oidcclient.md)** - OIDC client application definitions
- **[User](120-user.md)** - User account definitions with authentication credentials
- **[Group](130-group.md)** - Group definitions with shared claims
- **[GroupBinding](140-groupbinding.md)** - User-to-group associations

## API Group and Version

All Kubauth resources use the following API group and version:

- **API Group:** `kubauth.kubotal.io`
- **Version:** `v1alpha1`

## Resource Organization

### Namespaces

Kubauth resources are namespaced and typically organized as follows:

| Resource Type | Default Namespace | Configurable |
|--------------|-------------------|--------------|
| OidcClient | `kubauth-oidc` | Yes |
| User | `kubauth-users` | Yes |
| Group | `kubauth-users` | Yes |
| GroupBinding | `kubauth-users` | Yes |

Namespace configuration can be adjusted via Helm chart values during Kubauth deployment.

## Common Patterns

### Accessing Resources

#### Fully Qualified Names

Since some resource names (like `User`) are common and may conflict with other CRDs, use fully qualified names:

```bash
kubectl -n kubauth-users get users.kubauth.kubotal.io
```

#### Using Aliases

For convenience, Kubauth provides aliases:

```bash
# User alias
kubectl -n kubauth-users get kusers
```

### Listing Resources

```bash
# List all OIDC clients
kubectl -n kubauth-oidc get oidcclients

# List all users
kubectl -n kubauth-users get users.kubauth.kubotal.io

# List all groups
kubectl -n kubauth-users get groups.kubauth.kubotal.io

# List all group bindings
kubectl -n kubauth-users get groupbindings
```

### Describing Resources

```bash
# Describe an OIDC client
kubectl -n kubauth-oidc describe oidcclient myapp

# Describe a user
kubectl -n kubauth-users describe user john

# Describe a group
kubectl -n kubauth-users describe group developers
```

## Security Considerations

### Access Control

Use Kubernetes RBAC to control access to Kubauth resources:

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

- **User Passwords:** Always stored as bcrypt hashes, never in plain text
- **Client Secrets:** Stored as bcrypt hashes in OidcClient resources
- **Use `kc hash` command:** Generate hashes for passwords and secrets

## Best Practices

### Resource Naming

- Use descriptive, lowercase names with hyphens
- Follow consistent naming conventions across your organization
- For GroupBindings, use pattern: `<username>-<groupname>`

## Examples Repository

Complete examples for all resources can be found throughout the documentation:

- [User Configuration](../30-user-guide/110-configuration.md)
- [User Groups](../30-user-guide/150-users-groups.md)
- [Applications Integration](../40-applications-integration/110-argocd.md)
- [Kubernetes Integration](../50-kubernetes-integration/110-overview.md)

## Additional Resources

- [Kubauth GitHub Repository](https://github.com/kubauth/kubauth){:target="_blank"}

