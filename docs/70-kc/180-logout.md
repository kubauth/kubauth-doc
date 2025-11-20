# kc logout

## Overview

The `kc logout` command clears your authentication session with Kubauth. It performs two actions: clears local token cache and terminates the SSO session on the Kubauth server.

## Syntax

```bash
kc logout [options]
```

## Optional Flags

### `--issuerURL` (string)
The Kubauth OIDC issuer URL. If not provided, reads from kubectl configuration.

**Example:** `--issuerURL https://kubauth.example.com`

## Examples

### Basic Usage (from kubectl config)

```bash
kc logout
```

**Output:**
```
No OIDC configuration found in kubeconfig
Opening browser to logout endpoint: https://kubauth.example.com/oauth2/logout
```

!!! note
    The "No OIDC configuration found" message is informational and can be ignored when kubectl is configured.

### With Explicit Issuer URL

```bash
kc logout --issuerURL https://kubauth.example.com
```

## Behavior

### What It Does

1. **Clears local cache** - Removes cached tokens from the kubelogin plugin
2. **Opens browser** - Navigates to Kubauth's logout endpoint
3. **Terminates SSO session** - Clears the "Remember me" session cookie

### After Logout

The next kubectl command or `kc token` will require you to authenticate again:

```bash
# Logout
kc logout

# Next kubectl command prompts for login
kubectl get pods
# Browser opens for authentication
```

## Use Cases

### Switch Users

```bash
# Currently logged in as alice
kc whoami
# alice

# Logout
kc logout

# Next command will prompt for different user
kubectl get pods
# Login as bob
```

### End Work Session

```bash
# At end of day, clear authentication
kc logout

# Ensures no one else can use your session
```

### Testing Different Users

```bash
#!/bin/bash
USERS=("alice" "bob" "charlie")

for user in "${USERS[@]}"; do
  echo "Testing as $user..."
  
  # Login as user (using token-nui for automation)
  kc token-nui --issuerURL https://kubauth.example.com \
    --clientId public --login $user --password ${user}123 -d
  
  # Logout before next user
  kc logout --issuerURL https://kubauth.example.com
done
```

### Clear Stuck Session

If authentication seems stuck or behaving unexpectedly:

```bash
# Clear everything
kc logout

# Try again
kubectl get nodes
```

### Security After Shared Screen

```bash
# After screen sharing or presentation
kc logout

# Ensures session can't be reused
```

## SSO Session vs Local Cache

### SSO Session (Server-Side)

- Stored on Kubauth server
- Managed by "Remember me" checkbox
- Shared across all OIDC clients
- Cleared by `kc logout`

### Local Cache (Client-Side)

- Stored by kubelogin plugin
- Separate per client/context
- Not shared between applications
- Also cleared by `kc logout`

### Relationship

```
User Login → SSO Session Created → Local Tokens Cached
                    ↓
              "Remember me"
                    ↓
         Subsequent logins automatic
                    ↓
              kc logout
                    ↓
    SSO Session Cleared + Local Cache Cleared
                    ↓
         Next login requires authentication
```

## Logout Page

After logout, you'll see a page listing available applications:

![Kubauth Logout Page](../assets/kubauth-logout2.png)

This page shows OIDC clients with `displayName`, `description`, and `entryURL` configured.

## Troubleshooting

### Browser Doesn't Open

If the browser doesn't open:

1. Check the terminal output for the URL
2. Manually open the URL in your browser
3. The SSO session will still be cleared

### Still Auto-Logging In

If you're still automatically logged in after `kc logout`:

1. **Clear browser cookies** - Manually clear cookies for the Kubauth domain
2. **Check SSO sessions:**
   ```bash
   kubectl -n kubauth-sso get ssosessions
   ```
3. **Manually delete session:**
   ```bash
   kubectl -n kubauth-sso delete ssosession <session-name>
   ```

### Cannot Read kubeconfig

**Error:**
```
Error: unable to read kubeconfig
```

**Solution:** Either provide `--issuerURL` explicitly or fix kubectl configuration:
```bash
# Option 1: Explicit issuer
kc logout --issuerURL https://kubauth.example.com

# Option 2: Fix kubectl config
kc config https://kubeconfig.example.com/kubeconfig
```

### Multiple Contexts

If you have multiple kubectl contexts with different Kubauth issuers:

```bash
# Logout from current context
kc logout

# Or logout from specific issuer
kc logout --issuerURL https://kubauth-prod.example.com
kc logout --issuerURL https://kubauth-dev.example.com
```

## Security Considerations

### Always Logout on Shared Systems

```bash
# On shared workstation
kc logout

# On jump host
kc logout

# After demo/presentation
kc logout
```

### Session Lifetime

SSO sessions have a configured lifetime (default 8 hours):

```yaml
oidc:
  sso:
    lifeTime: "8h"
```

Sessions expire automatically after this period, but explicit logout is recommended.

### Local Token Cache

Even after SSO session expires, local tokens may still be valid until they expire (typically 1-30 minutes depending on configuration).

## Related Commands

- [`kc token`](130-token.md) - Authenticate and get tokens
- [`kc whoami`](170-whoami.md) - Check current authentication
- [`kc config`](190-config.md) - Configure kubectl

## See Also

- [SSO Session](../30-user-guide/140-sso.md)
- [Workstation Setup](../50-kubernetes-integration/140-workstation-setup.md#logout)

