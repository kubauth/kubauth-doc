# kc hash

## Overview

The `kc hash` command generates a bcrypt hash from a plain-text value. The resulting hash is suitable for the `passwordHash` field of a Kubauth User, or as the bcrypt-hashed value to store in a Kubernetes Secret used by an OIDC client (see [`OidcClient.spec.secrets`](../60-references/110-oidcclient.md#secrets)).

The hash uses **bcrypt** with a fixed work factor of `12`.

## Syntax

```bash
kc hash <plain-text-value> [--raw] [--user]
```

## Arguments

### `<plain-text-value>` { #plain-text-value }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required</span>
</p>

The plain-text password or secret to hash.

## Flags

### `--raw`, `-r` { #raw }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Print only the raw hash on stdout, with no trailing newline. Useful when piping the hash into another command, for example to base64-encode it for a Kubernetes Secret:

```bash
kc hash 'my-client-secret' -r | base64
```

<hr class="api-field-separator">

### `--user`, `-u` { #user }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Print the hash inside a ready-to-paste `User` manifest snippet.

## Examples

### Default Output

```bash
kc hash mypassword123
```

Output:

```
Hash: $2a$12$nSplFbbsGoI7LXdhJrKx0erRmIv.zkTftG82sQZA0.v3l1eCf.ey.
```

### Formatted for a User Manifest

```bash
kc hash mypassword123 -u
```

Output:

```
Use this hash in your User 'passwordHash' field

Example:
  apiVersion: kubauth.kubotal.io/v1alpha1
  kind: User
  .....
  spec:
    passwordHash: "$2a$12$nSplFbbsGoI7LXdhJrKx0erRmIv.zkTftG82sQZA0.v3l1eCf.ey."
```

### Raw, for Piping

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

- **Minimum length:** 12+ characters recommended.
- **Complexity:** mix of letters, numbers, and symbols.
- **No common passwords:** avoid dictionary words.
- **No personal information:** don't use names, birthdates, etc.

### Hash Properties

- **Algorithm:** bcrypt.
- **Cost factor:** 12 (balanced between security and performance).
- **Unique salts:** each hash has a unique salt.
- **One-way:** cannot be reversed to get the original password.

### Handling Hashes

1. **Quote in YAML:** always quote hashes in YAML files (dollar signs have special meaning to many tools).
   ```yaml
   passwordHash: "$2a$12$..."
   ```

2. **Safe to store:** bcrypt hashes can be safely committed to version control. Plain-text passwords cannot.

3. **Non-deterministic:** running `kc hash` twice with the same input produces different hashes (random salt). Both validate the same input.

## Troubleshooting

### Hash Not Working

If authentication fails with a hash you generated:

1. **Verify the hash was copied correctly** — include the entire hash string.
2. **Check quotes** — ensure the hash is quoted in YAML.
3. **Verify the user exists** — `kubectl -n kubauth-users get user <username>`.
4. **Review audit logs** — `kc audit logins`.

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
