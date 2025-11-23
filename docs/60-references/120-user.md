# User Reference

## Overview

A `User` represents a user account in Kubauth. Users are stored as Kubernetes Custom Resources, providing a cloud-native, scalable authentication solution.

**API Group:** `kubauth.kubotal.io/v1alpha1`

**Kind:** `User`

**Namespaced:** Yes (typically `kubauth-users`)

**Aliases:** `kuser` (for easier kubectl access)

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
string - optional

The full name of the user. This appears in the `name` claim in OIDC ID tokens.

**Example:**
```yaml
name: "John DOE"
```
**Resulting JWT Token Claim:**
```json
{
  "name": "John DOE",
  ...
}
```

-----
### `emails`
[]string - optional

List of email addresses associated with the user.

**Behavior:**
- The `emails` claim in the ID token contains the complete list
- The `email` claim contains the first email in the list

**Example:**
```yaml
emails:
  - john.doe@example.com
  - j.doe@example.com
```

**JWT Token Claims:**
```json
{
  "email": "john.doe@example.com",
  "emails": ["john.doe@example.com", "j.doe@example.com"],
  ...
}
```

---
### `passwordHash`
string - optional

The bcrypt hash of the user's password. 

**Generation:** Use the `kc hash <password>` command to generate the hash from a plain-text password.

**Security:** Passwords are stored as bcrypt hashes (never in plain text), providing strong protection against password database compromise.

**Behavior:** A user definition without password is useful on case of multiple Identity Providers.

**Example:**
```yaml
passwordHash: "$2a$12$yJEo9EoYn/ylGS4PCamfNe8PReYH9IPumsw7rMTDi3glZjuA7dXMm"
```

**Generating a hash:**
```bash
$ kc hash mypassword123
Secret: mypassword123
Hash: $2a$12$yJEo9EoYn/ylGS4PCamfNe8PReYH9IPumsw7rMTDi3glZjuA7dXMm
```

Use this hash in your User 'passwordHash' field

---
### `claims` 
map[string]any - required

Custom OIDC claims to include in ID tokens for this user. Can contain any valid JSON values.

**Use Cases:**

- Application-specific user attributes
- Custom authorization data
- Integration with downstream systems

**Example:**
```yaml
claims:
  office: "208G"
  department: "Engineering"
  clearance_level: 3
  minio_policies: "consoleAdmin"
```

**JWT Token Claims:**
```json
{
  "office": "208G",
  "department": "Engineering",
  "clearance_level": 3,
  "minio_policies": "consoleAdmin",
  ...
}
```

-----
### `uid`
integer - optional

A user numerical ID. May be useful in some Linux context

-----
### `comment`
string - optional

Administrative comment or description for the user. Not included in OIDC tokens.

**Example:**
```yaml
comment: "External consultant - expires 2025-12-31"
```

---
### `disabled`
boolean - optional default false

Whether the user account is disabled. Disabled users cannot authenticate.

**Default:** `false`

**Example:**
```yaml
disabled: true
```

## Status Fields


The `User` resource does not currently expose status fields. The resource is ready to use immediately after creation.

## Identity Information

The user login is the resource name in the metadata section. This becomes:

- The `sub` (subject) claim in OIDC tokens
- The login for authentication

**Example:**
```yaml
metadata:
  name: john  # This is the login username
```

**JWT Token:**
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

- Password validation may come from LDAP
- Additional attributes (claims, group memberships) can be defined in the User CRD
- See [Identity Merging](../30-user-guide/190-identity-merging.md) for details

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

- [Group](./130-group.md) - Define groups with shared claims
- [GroupBinding](./140-groupbinding.md) - Associate users with groups

