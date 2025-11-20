# Group Reference

## Overview

A `Group` represents an explicit group definition with associated claims. Groups can exist implicitly through `GroupBinding` resources alone, but creating an explicit Group resource allows you to:

- Document the group's purpose
- Define claims that are inherited by all group members
- Centralize group-level permissions and attributes

**API Group:** `kubauth.kubotal.io/v1alpha1`

**Kind:** `Group`

**Namespaced:** Yes (typically `kubauth-users`)

## Example

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: ops
  namespace: kubauth-users
spec:
  comment: "Operations team with 24x7 access"
  claims:
    accessProfile: "24x7"
    pager_duty: "true"
    alert_level: "critical"
```

## Spec Fields

All fields in the Group spec are optional. A Group can exist with an empty spec.

### Optional Fields

#### `comment` (string)
A description or comment about the group for administrative purposes. Not included in OIDC tokens.

**Example:**
```yaml
comment: "Development team with access to staging environments"
```

#### `claims` (map[string]any)
Custom OIDC claims that are inherited by all members of this group. Can contain any valid JSON values.

**Behavior:** When a user is a member of this group (via GroupBinding), these claims are merged into the user's ID token.

**Use Cases:**
- Application-specific permissions
- Role indicators
- Policy assignments
- Common attributes for all group members

**Example:**
```yaml
claims:
  accessProfile: "business-hours"
  cost_center: "ENG-001"
  security_clearance: 2
```

**JWT Token for a member:**
```json
{
  "groups": ["ops"],
  "accessProfile": "business-hours",
  "cost_center": "ENG-001",
  "security_clearance": 2,
  ...
}
```

## Group Existence

### Implicit Groups

Groups can exist without an explicit Group resource. Simply referencing a group name in a GroupBinding creates an implicit group.

**Example:**
```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: alice-developers
  namespace: kubauth-users
spec:
  user: alice
  group: developers  # Group 'developers' now exists implicitly
```

### Explicit Groups

Creating a Group resource makes the group explicit and allows you to:

- Add a description via the `comment` field
- Define claims that all members inherit

**Example:**
```yaml
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: developers
  namespace: kubauth-users
spec:
  comment: "Software development team"
  claims:
    department: "Engineering"
    build_access: "true"
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: alice-developers
  namespace: kubauth-users
spec:
  user: alice
  group: developers
```

## Claim Inheritance

When a user belongs to multiple groups, claims from all groups are merged. If multiple groups define the same claim key, the behavior depends on the identity provider configuration and group ordering.

**Example:**
```yaml
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: developers
  namespace: kubauth-users
spec:
  claims:
    department: "Engineering"
    access_level: 2
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: ops
  namespace: kubauth-users
spec:
  claims:
    department: "Operations"  # Conflict with developers group
    accessProfile: "24x7"
    access_level: 3  # Conflict with developers group
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
```

**Result:** Claim merging behavior depends on implementation, but typically later groups override earlier ones. Individual user claims (from the User resource) typically take precedence over group claims.

## Usage Notes

### Naming Convention

Group names should be descriptive and follow your organization's naming conventions. Consider:

- Using lowercase with hyphens: `ops-team`, `developers`, `cluster-admins`
- Namespace-scoped names if managing multiple clusters/environments
- Prefixes for different categories: `app-`, `k8s-`, `ldap-`

### Documentation

Use the `comment` field generously to document:

- The group's purpose
- Who should be members
- What access or permissions it grants
- When it should be reviewed

### Kubernetes RBAC Integration

When integrating with Kubernetes RBAC, be aware of the group name prefix configured in the API server OIDC settings.

**Example:**
If your API server is configured with `--oidc-groups-prefix=oidc-`, a group named `cluster-admin` in Kubauth will appear as `oidc-cluster-admin` in Kubernetes RBAC.

```yaml
---
# Kubauth Group
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: cluster-admin
  namespace: kubauth-users
spec:
  comment: "Full cluster administrators"
---
# Kubernetes ClusterRoleBinding references the prefixed name
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc-cluster-admins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: oidc-cluster-admin  # Note the prefix
```

### Application-Specific Claims

Groups are ideal for centralizing application-specific permissions and policies.

**Best Practice:** Create dedicated groups for each application or permission level rather than adding application-specific claims to individual users.

## Examples

### Simple Group with Comment

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: developers
  namespace: kubauth-users
spec:
  comment: "Software development team - full access to dev and staging"
```

### Group with Claims

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: ops
  namespace: kubauth-users
spec:
  comment: "Operations team with 24x7 on-call responsibilities"
  claims:
    accessProfile: "24x7"
    pager_duty: "true"
    alert_level: "critical"
    cost_center: "OPS-001"
```

### Application-Specific Group (MinIO)

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: minio-admins
  namespace: kubauth-users
spec:
  comment: "MinIO administrators with full console access"
  claims:
    minio_policies: "consoleAdmin"
```

### Application-Specific Group (Harbor)

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: harbor-admins
  namespace: kubauth-users
spec:
  comment: "Harbor registry administrators"
  claims:
    harbor_role: "admin"
```

### Multiple Application Claims

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: platform-admins
  namespace: kubauth-users
spec:
  comment: "Platform administrators with access to all infrastructure tools"
  claims:
    # MinIO access
    minio_policies: "consoleAdmin"
    # Harbor access
    harbor_role: "admin"
    # ArgoCD access (handled via k8s RBAC)
    # Custom claims
    admin_level: "full"
    cost_center: "INFRA"
    security_clearance: 3
```

### Department Group

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: engineering
  namespace: kubauth-users
spec:
  comment: "All engineering department members"
  claims:
    department: "Engineering"
    cost_center: "ENG-001"
    office_location: "HQ"
    time_zone: "America/New_York"
```

### Environment-Specific Group

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: production-access
  namespace: kubauth-users
spec:
  comment: "Production environment access - requires management approval"
  claims:
    environment: "production"
    approval_required: "true"
    audit_level: "high"
    change_window: "business-hours-only"
```

## Deletion Behavior

Deleting a Group resource:

- Removes the explicit group definition
- Does **not** automatically delete associated GroupBindings
- Does **not** automatically remove users from the group

If GroupBindings still reference the deleted group, the group continues to exist implicitly through those bindings, but without any group-level claims or comments.

To fully remove a group:

1. Delete all GroupBindings that reference the group
2. Delete the Group resource (if it exists)

```bash
# Find all bindings for a group
kubectl -n kubauth-users get groupbindings -o json | \
  jq -r '.items[] | select(.spec.group=="ops") | .metadata.name'

# Delete the bindings
kubectl -n kubauth-users delete groupbinding john-ops alice-ops bob-ops

# Delete the group resource
kubectl -n kubauth-users delete group ops
```

## Related Resources

- [GroupBinding](./groupbinding.md) - Associates users with groups
- [User](./user.md) - User accounts that can be members of groups
- [OidcClient](./oidcclient.md) - Client applications that receive group claims in tokens

