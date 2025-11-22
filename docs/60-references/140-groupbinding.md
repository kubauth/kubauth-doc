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

------
### `user`
string - required

The name of the user to bind to the group. This must match the `metadata.name` of an existing User resource.

-----
#### `group`
string - required

The name of the group to bind the user to. The group does not need to exist as a Group resource - it will be created implicitly by the GroupBinding.


## Behavior

### Implicit Group Creation

Creating a GroupBinding automatically makes the referenced group exist, even if no explicit Group resource is defined. 
This follows Kubernetes' pattern of weak referential integrity.

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

## Naming Convention

While the `metadata.name` can be any valid Kubernetes resource name, we recommend a naming convention that makes the binding easy to understand:

**Pattern:** `<username>-<groupname>`

**Examples:**
- `john-developers`
- `alice-cluster-admins`
- `bob-ops-team`

This makes it easy to identify what each binding does and find all bindings for a specific user or group using kubectl.

## Deletion Behavior

Deleting a GroupBinding removes the user from the group immediately. The user will no longer have the group in their `groups` claim or inherit any group-level claims on the next authentication.

```bash
kubectl delete groupbinding john-developers -n kubauth-users
```

**Note:** Deleting the last GroupBinding that references a group does not delete the group itself if an explicit Group resource exists. 
Only implicit groups (those that exist solely through GroupBindings) cease to exist when all their bindings are deleted.

## Related Resources

- [User](./120-user.md) - User accounts that can be bound to groups
- [Group](./130-group.md) - Optional explicit group definitions with claims

