# GroupBinding Reference

## Overview

A `GroupBinding` associates a user with a group. Groups are used to organize users and apply common claims and permissions. With Kubauth, a group exists simply by being referenced in a `GroupBinding` - explicit Group creation is optional.

**API Group:** `kubauth.kubotal.io/v1alpha1`

**Kind:** `GroupBinding`

**Namespaced:** Yes (typically `kubauth-users`)

## Example

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-developers
  namespace: kubauth-users
spec:
  user: john
  group: developers
```

## Spec Fields

### Required Fields

#### `user` (string)
The name of the user to bind to the group. This must match the `metadata.name` of an existing User resource.

**Example:**
```yaml
user: john
```

#### `group` (string)
The name of the group to bind the user to. The group does not need to exist as a Group resource - it will be created implicitly by the GroupBinding.

**Example:**
```yaml
group: developers
```

## Behavior

### Implicit Group Creation

Creating a GroupBinding automatically makes the referenced group exist, even if no explicit Group resource is defined. This follows Kubernetes' pattern of weak referential integrity.

**Example:**
```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: alice-admins
  namespace: kubauth-users
spec:
  user: alice
  group: cluster-admins  # Group 'cluster-admins' now exists
```

### Group Claims in Tokens

When a user authenticates, all groups they belong to (via GroupBinding resources) are included in the `groups` claim in the OIDC ID token.

**Example:**
User `john` has two GroupBindings:
```yaml
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-developers
  namespace: kubauth-users
spec:
  user: john
  group: developers
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-leads
  namespace: kubauth-users
spec:
  user: john
  group: team-leads
```

**JWT Token for user `john`:**
```json
{
  "sub": "john",
  "groups": ["developers", "team-leads"],
  ...
}
```

### Referential Integrity

Kubernetes does not enforce referential integrity when creating resources. A GroupBinding can reference:

- A non-existent user (the binding will exist but have no effect)
- A non-existent group (the group will be created implicitly)

This is by design and follows Kubernetes patterns. Resources may be created in any order, and references may be fulfilled later.

**Example:**
```bash
# This succeeds even if user 'future-user' doesn't exist yet
kubectl apply -f - <<EOF
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: future-user-binding
  namespace: kubauth-users
spec:
  user: future-user
  group: developers
EOF
```

## Naming Convention

While the `metadata.name` can be any valid Kubernetes resource name, we recommend a naming convention that makes the binding easy to understand:

**Pattern:** `<username>-<groupname>`

**Examples:**
- `john-developers`
- `alice-cluster-admins`
- `bob-ops-team`

This makes it easy to identify what each binding does and find all bindings for a specific user or group using kubectl.

## Usage Notes

### Listing Group Memberships

To see all group bindings:
```bash
kubectl -n kubauth-users get groupbindings
```

To see bindings for a specific user:
```bash
kubectl -n kubauth-users get groupbindings -l user=john
```

To see all users in a specific group:
```bash
kubectl -n kubauth-users get groupbindings -l group=developers
```

**Note:** Label-based queries require labels to be set on the resources. Consider adding labels for easier management:

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-developers
  namespace: kubauth-users
  labels:
    user: john
    group: developers
spec:
  user: john
  group: developers
```

### Group-Level Claims

When a GroupBinding references an explicitly defined Group resource, the user inherits all claims from that group.

**Example:**
```yaml
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: ops
  namespace: kubauth-users
spec:
  claims:
    accessProfile: "24x7"
    pager_duty: "true"
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: bob-ops
  namespace: kubauth-users
spec:
  user: bob
  group: ops
```

**Result in JWT token for user `bob`:**
```json
{
  "groups": ["ops"],
  "accessProfile": "24x7",
  "pager_duty": "true",
  ...
}
```

## Examples

### Simple Group Membership

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: alice-developers
  namespace: kubauth-users
spec:
  user: alice
  group: developers
```

### Multiple Groups for One User

```yaml
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-developers
  namespace: kubauth-users
spec:
  user: john
  group: developers
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-ops
  namespace: kubauth-users
spec:
  user: john
  group: ops
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-architects
  namespace: kubauth-users
spec:
  user: john
  group: architects
```

### Kubernetes RBAC Integration

```yaml
---
# Bind user to Kubauth group
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: alice-cluster-admin
  namespace: kubauth-users
spec:
  user: alice
  group: cluster-admin
---
# Bind Kubauth group to Kubernetes role
# Note: group name is prefixed with 'oidc-' due to API server configuration
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: oidc-cluster-admin
```

### Application-Specific Group

```yaml
---
# Define group with application-specific claims
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: minio-admins
  namespace: kubauth-users
spec:
  claims:
    minio_policies: "consoleAdmin"
---
# Bind user to group
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: bob-minio-admins
  namespace: kubauth-users
spec:
  user: bob
  group: minio-admins
```

### With Labels for Easy Querying

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-developers
  namespace: kubauth-users
  labels:
    user: john
    group: developers
    team: engineering
spec:
  user: john
  group: developers
```

Query by labels:
```bash
# All bindings for user john
kubectl -n kubauth-users get groupbindings -l user=john

# All bindings for group developers
kubectl -n kubauth-users get groupbindings -l group=developers

# All bindings for engineering team
kubectl -n kubauth-users get groupbindings -l team=engineering
```

## Deletion Behavior

Deleting a GroupBinding removes the user from the group immediately. The user will no longer have the group in their `groups` claim or inherit any group-level claims on the next authentication.

```bash
kubectl delete groupbinding john-developers -n kubauth-users
```

**Note:** Deleting the last GroupBinding that references a group does not delete the group itself if an explicit Group resource exists. Only implicit groups (those that exist solely through GroupBindings) cease to exist when all their bindings are deleted.

## Related Resources

- [User](./user.md) - User accounts that can be bound to groups
- [Group](./group.md) - Optional explicit group definitions with claims
- [OidcClient](./oidcclient.md) - Client applications that receive group information in tokens

