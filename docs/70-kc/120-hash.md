# kc hash

## Overview

The `kc hash` command generates bcrypt hashes for passwords and secrets. These hashes are used in Kubauth User and OidcClient resources for secure credential storage.

## Syntax

```bash
kc hash <plain-text-value>
```

## Arguments

### `<plain-text-value>` (string, required)
The plain-text password or secret to hash.

## Examples


```bash
kc hash mypassword123
```

**Output:**
```
Secret: mypassword123
Hash: $2a$12$nSplFbbsGoI7LXdhJrKx0erRmIv.zkTftG82sQZA0.v3l1eCf.ey.

Use this hash in your User 'passwordHash' field

Example:
  apiVersion: kubauth.kubotal.io/v1alpha1
  kind: User
  .....
  spec:
    passwordHash: "$2a$12$nSplFbbsGoI7LXdhJrKx0erRmIv.zkTftG82sQZA0.v3l1eCf.ey."

Or in your OidcClient 'hashedSecret' field

Example:
  apiVersion: kubauth.kubotal.io/v1alpha1
  kind: OidcClient
  .....
  spec:
    hashedSecret: "$2a$12$nSplFbbsGoI7LXdhJrKx0erRmIv.zkTftG82sQZA0.v3l1eCf.ey."
```

## Security Considerations

### Password Strength

The `kc hash` command will hash any input, but you should enforce strong password policies:

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

1. **Quote in YAML:** Always quote hashes in YAML files (dollar signs have special meaning)
   ```yaml
   passwordHash: "$2a$12$..."  # Quoted
   ```

2. **Safe to store:** Hashes can be safely committed to version control (not plain-text passwords)

3. **Different every time:** Running `kc hash` with the same input produces different hashes (due to random salt)

## Troubleshooting

### Hash Not Working

If authentication fails with a hash you generated:

1. **Verify hash was copied correctly** - Include entire hash string
2. **Check quotes** - Ensure hash is quoted in YAML
3. **Verify user exists** - `kubectl -n kubauth-users get user <username>`
4. **Test authentication** - `kc audit logins`

### Special Characters in Password

Passwords with special characters are supported but must be handled carefully:

```bash
# Use single quotes to prevent shell interpolation
kc hash 'P@ssw0rd$pecial!'

# Or escape special characters
kc hash "P@ssw0rd\$pecial!"
```

## See Also

- [User Configuration](../30-user-guide/110-configuration.md#password-hash)
- [User Reference](../60-references/120-user.md#passwordhash-string)
- [OidcClient Reference](../60-references/110-oidcclient.md#hashedsecret-string)

