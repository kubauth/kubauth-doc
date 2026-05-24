# kc hash

## Overview

The `kc hash` command generates a bcrypt hash from a plain-text value. The resulting hash is suitable for the `passwordHash` field of a Kubauth User, or as the bcrypt-hashed value to store in a Kubernetes Secret used by an OIDC client (see [`OidcClient.spec.secrets`](../60-references/110-oidcclient.md#secrets)).

The hash uses **bcrypt** with a fixed work factor of `12`.

## Syntax

```bash
kc hash <plain-text-value> [--raw] [--user]
```

## Arguments

### `<plain-text-value>` (string, required)

The plain-text password or secret to hash.

## Flags

### `-r`, `--raw`

Print only the raw hash on stdout, with no trailing newline. Useful when piping the hash into another command, for example to base64-encode it for a Kubernetes Secret:

```bash
kc hash 'my-client-secret' -r | base64
```

### `-u`, `--user`

Print the hash inside a ready-to-paste `User` manifest snippet.

## Examples

### Default output

```bash
kc hash mypassword123
```

**Output:**

```
Hash: $2a$12$nSplFbbsGoI7LXdhJrKx0erRmIv.zkTftG82sQZA0.v3l1eCf.ey.
```

### Formatted for a User manifest

```bash
kc hash mypassword123 -u
```

**Output:**

```
Use this hash in your User 'passwordHash' field

Example:
  apiVersion: kubauth.kubotal.io/v1alpha1
  kind: User
  .....
  spec:
    passwordHash: "$2a$12$nSplFbbsGoI7LXdhJrKx0erRmIv.zkTftG82sQZA0.v3l1eCf.ey."
```

### Raw, for piping

```bash
kc hash mypassword123 -r
```

Prints the hash with no newline, useful in pipelines:

```bash
kc hash 'my-client-secret' -r | base64
```

## Security Considerations

### Password Strength

The `kc hash` command will hash any input. Enforce strong password policies in your organization:

- **Minimum length:** 12+ characters recommended
- **Complexity:** Mix of letters, numbers, and symbols
- **No common passwords:** Avoid dictionary words
- **No personal information:** Don't use names, birthdates, etc.

### Hash Properties

- **Algorithm:** bcrypt
- **Cost Factor:** 12 (balanced between security and performance)
- **Unique salts:** Each hash has a unique salt
- **One-way:** Cannot be reversed to get original password

### Handling Hashes

1. **Quote in YAML:** Always quote hashes in YAML files (dollar signs have special meaning to many tools).
   ```yaml
   passwordHash: "$2a$12$..."
   ```

2. **Safe to store:** Bcrypt hashes can be safely committed to version control. Plain-text passwords cannot.

3. **Non-deterministic:** Running `kc hash` twice with the same input produces different hashes (random salt). Both validate the same input.

## Troubleshooting

### Hash Not Working

If authentication fails with a hash you generated:

1. **Verify hash was copied correctly** — include the entire hash string
2. **Check quotes** — ensure the hash is quoted in YAML
3. **Verify the user exists** — `kubectl -n kubauth-users get user <username>`
4. **Review audit logs** — `kc audit logins`

### Special Characters in Password

Passwords with special characters are supported but must be handled carefully:

```bash
# Use single quotes to prevent shell interpolation
kc hash 'P@ssw0rd$pecial!'

# Or escape special characters
kc hash "P@ssw0rd\$pecial!"
```

## See Also

- [Users Configuration](../30-user-guide/110-users-configuration.md#password-hash)
- [User Reference](../60-references/120-user.md#passwordhash)
- [OidcClient Reference](../60-references/110-oidcclient.md#secrets)
