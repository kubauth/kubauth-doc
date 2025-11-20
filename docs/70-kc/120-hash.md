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

### Basic Usage

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

### Generate Hash for User Password

```bash
$ kc hash alice123
Secret: alice123
Hash: $2a$12$.WUyue3xr.nKuH8Tu0q.T.WF.PKHLZ92g9ewnLoB.27CuMQIdvuza
```

**Use in User resource:**
```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: User
metadata:
  name: alice
  namespace: kubauth-users
spec:
  passwordHash: "$2a$12$.WUyue3xr.nKuH8Tu0q.T.WF.PKHLZ92g9ewnLoB.27CuMQIdvuza"
  name: "Alice Smith"
```

### Generate Hash for Client Secret

```bash
$ kc hash argocd123
Secret: argocd123
Hash: $2a$12$.34NOSBLz9cfW9PD/yjj6uhrvys42Xb4euwKy6UFx9YLYEwxIICAK
```

**Use in OidcClient resource:**
```yaml
apiVersion: kubauth.kubotal.io/v1alpha1
kind: OidcClient
metadata:
  name: argocd
  namespace: kubauth-oidc
spec:
  hashedSecret: "$2a$12$.34NOSBLz9cfW9PD/yjj6uhrvys42Xb4euwKy6UFx9YLYEwxIICAK"
  redirectURIs:
    - "https://argocd.example.com/auth/callback"
  ...
```

## Use Cases

### Creating New Users

```bash
# Generate hash for new user
kc hash strongpassword456

# Copy the hash into user manifest
kubectl apply -f - <<EOF
apiVersion: kubauth.kubotal.io/v1alpha1
kind: User
metadata:
  name: newuser
  namespace: kubauth-users
spec:
  passwordHash: "$2a$12$..."
  name: "New User"
EOF
```

### Updating User Password

```bash
# Generate new hash
NEW_HASH=$(kc hash newpassword789 | grep "Hash:" | awk '{print $2}')

# Update user
kubectl patch user john -n kubauth-users --type merge \
  -p "{\"spec\":{\"passwordHash\":\"$NEW_HASH\"}}"
```

### Creating OIDC Clients

```bash
# Generate client secret hash
kc hash clientsecret123

# Use in client manifest
kubectl apply -f client-myapp.yaml
```

### Batch User Creation

```bash
#!/bin/bash
USERS=("alice" "bob" "charlie")

for user in "${USERS[@]}"; do
  PASSWORD="${user}123"
  HASH=$(kc hash $PASSWORD | grep "Hash:" | awk '{print $2}')
  
  kubectl apply -f - <<EOF
apiVersion: kubauth.kubotal.io/v1alpha1
kind: User
metadata:
  name: $user
  namespace: kubauth-users
spec:
  passwordHash: "$HASH"
  name: "$(echo $user | sed 's/.*/\u&/')"
EOF
done
```

## Security Considerations

### Password Strength

The `kc hash` command will hash any input, but you should enforce strong password policies:

- **Minimum length:** 12+ characters recommended
- **Complexity:** Mix of letters, numbers, and symbols
- **No common passwords:** Avoid dictionary words
- **No personal information:** Don't use names, birthdates, etc.

**Example of strong passwords:**
```bash
kc hash 'Tr0ng!P@ssw0rd#2024'
kc hash 'MyC0mplex&SecureP@ss'
```

### Don't Log Plain-Text Passwords

```bash
# Bad - password visible in shell history
kc hash mypassword123

# Better - read from stdin
read -s PASSWORD && kc hash "$PASSWORD"

# Or use password manager
kc hash "$(pass show kubauth/alice)"
```

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

### Empty Output

If `kc hash` produces no output:

```bash
# Ensure you provide an argument
kc hash           # Wrong
kc hash mypass    # Correct
```

## Related Commands

- [`kc token`](130-token.md) - Test authentication with hashed passwords
- [`kc token-nui`](140-token-nui.md) - Authenticate with username/password

## See Also

- [User Configuration](../30-user-guide/110-configuration.md#password-hash)
- [User Reference](../60-references/120-user.md#passwordhash-string)
- [OidcClient Reference](../60-references/110-oidcclient.md#hashedsecret-string)

