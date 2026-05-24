# User Reference

## Overview

A `User` represents a user account in Kubauth. Users are stored as Kubernetes Custom Resources, providing a cloud-native, scalable authentication solution.

| Property      | Value                                                          |
|---------------|----------------------------------------------------------------|
| API Group     | `kubauth.kubotal.io`                                           |
| API Version   | `v1alpha1`                                                     |
| Kind          | `User`                                                         |
| Scope         | Namespaced (typically `kubauth-users`)                         |
| Short names   | `kuser`, `kusers`                                              |

## Example

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: User
metadata:
  name: john
  namespace: kubauth-users
spec:
  passwordHash: "$2a$12$..."
  name: "John DOE"
  emails:
    - john.doe@example.com
    - j.doe@example.com
  claims:
    office: "Building A, Room 205"
    department: "Engineering"
    employee_id: "12345"
  comment: "Senior Software Engineer"
  disabled: false
```

## Spec Fields

### `name`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

The full name of the user. This appears as the `name` claim in OIDC ID tokens.

```yaml
name: "John DOE"
```

Resulting JWT token claim:

```json
{
  "name": "John DOE",
  ...
}
```

<hr class="api-field-separator">

### `emails`

<p class="api-meta">
<span class="api-badge api-type">[]string</span>
<span class="api-badge api-optional">optional</span>
</p>

List of email addresses associated with the user.

Behavior:

- The `emails` claim in the ID token contains the complete list.
- The `email` claim contains the first email in the list.

```yaml
emails:
  - john.doe@example.com
  - j.doe@example.com
```

Resulting JWT token claims:

```json
{
  "email": "john.doe@example.com",
  "emails": ["john.doe@example.com", "j.doe@example.com"],
  ...
}
```

<hr class="api-field-separator">

### `passwordHash`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

The bcrypt hash of the user's password.

- **Generation:** use the `kc hash <password>` command to generate the hash from a plain-text password.
- **Security:** passwords are stored as bcrypt hashes (never in plain text), providing strong protection against password database compromise.
- **Behavior:** a user definition without a password is useful in case of multiple identity providers.

```yaml
passwordHash: "$2a$12$yJEo9EoYn/ylGS4PCamfNe8PReYH9IPumsw7rMTDi3glZjuA7dXMm"
```

Generating a hash:

```bash
$ kc hash mypassword123
Secret: mypassword123
Hash: $2a$12$yJEo9EoYn/ylGS4PCamfNe8PReYH9IPumsw7rMTDi3glZjuA7dXMm
```

Use this hash in your User's `passwordHash` field.

<hr class="api-field-separator">

### `claims`

<p class="api-meta">
<span class="api-badge api-type">map[string]any</span>
<span class="api-badge api-required">required</span>
</p>

Custom OIDC claims to include in ID tokens for this user. Can contain any valid JSON values.

**Use cases:**

- Application-specific user attributes
- Custom authorization data
- Integration with downstream systems

```yaml
claims:
  office: "208G"
  department: "Engineering"
  clearance_level: 3
  minio_policies: "consoleAdmin"
```

Resulting JWT token claims:

```json
{
  "office": "208G",
  "department": "Engineering",
  "clearance_level": 3,
  "minio_policies": "consoleAdmin",
  ...
}
```

<hr class="api-field-separator">

### `uid`

<p class="api-meta">
<span class="api-badge api-type">integer</span>
<span class="api-badge api-optional">optional</span>
</p>

A user numerical ID. May be useful in some Linux contexts.

<hr class="api-field-separator">

### `comment`

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-optional">optional</span>
</p>

Administrative comment or description for the user. Not included in OIDC tokens.

```yaml
comment: "External consultant - expires 2025-12-31"
```

<hr class="api-field-separator">

### `disabled`

<p class="api-meta">
<span class="api-badge api-type">boolean</span>
<span class="api-badge api-optional">optional</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Whether the user account is disabled. Disabled users cannot authenticate.

```yaml
disabled: true
```

## Status Fields

The `User` resource does not currently expose status fields. The resource is ready to use immediately after creation.

## Identity Information

The user login is the resource name in the metadata section. This becomes:

- The `sub` (subject) claim in OIDC tokens
- The login for authentication

```yaml
metadata:
  name: john  # This is the login username
```

Resulting JWT token:

```json
{
  "sub": "john",
  ...
}
```

## Usage Notes

### Namespacing

Users are typically created in the `kubauth-users` namespace, though this can be configured via Helm chart values.

### Access Control

Using a dedicated namespace for users allows fine-grained access control via Kubernetes RBAC. You can grant specific users or groups the ability to manage User resources without giving them full cluster access.

### Fully Qualified Resource Name

Since `user` is a common term that may refer to various CRD types, use the fully qualified name when querying:

```bash
kubectl -n kubauth-users get users.kubauth.kubotal.io
```

Alternatively, use the provided alias:

```bash
kubectl -n kubauth-users get kusers
```

### Password Updates

To update a user's password:

1. Generate a new hash: `kc hash newpassword`
2. Update the User resource with the new `passwordHash`

```bash
kubectl patch user john -n kubauth-users --type merge -p '{"spec":{"passwordHash":"$2a$12$..."}}'
```

### Identity Provider Integration

When using external identity providers (like LDAP), user properties can be merged:

- Password validation may come from LDAP.
- Additional attributes (claims, group memberships) can be defined in the User CRD.
- See [Identity Merging](../30-user-guide/190-identity-merging.md) for details.

## Examples

### Minimal User

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: User
metadata:
  name: alice
  namespace: kubauth-users
spec:
  passwordHash: "$2a$12$..."
```

### Complete User

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: User
metadata:
  name: john
  namespace: kubauth-users
spec:
  passwordHash: "$2a$12$..."
  name: "John DOE"
  emails:
    - john.doe@example.com
    - j.doe@example.com
  claims:
    office: "208G"
    department: "Engineering"
    employee_id: "E12345"
    clearance_level: 2
  comment: "Engineering team lead"
```

### Disabled User

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: User
metadata:
  name: former-employee
  namespace: kubauth-users
spec:
  passwordHash: "$2a$12$..."
  name: "Former Employee"
  disabled: true
  comment: "Account disabled - left company 2024-01-15"
```

### User with Application-Specific Claims

```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: User
metadata:
  name: admin-user
  namespace: kubauth-users
spec:
  passwordHash: "$2a$12$..."
  name: "Admin User"
  emails:
    - admin@example.com
  claims:
    # MinIO policy
    minio_policies: "consoleAdmin"
    # Harbor role indicator
    harbor_role: "admin"
    # Custom application data
    cost_center: "IT-OPS"
    office: "HQ-Floor3"
```

## Related Resources

- [Group](./130-group.md) — Define groups with shared claims
- [GroupBinding](./140-groupbinding.md) — Associate users with groups
