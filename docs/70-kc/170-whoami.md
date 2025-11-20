# kc whoami

## Overview

The `kc whoami` command displays the currently authenticated user information from your kubectl configuration. It extracts and shows the username and optionally the full JWT token payload.

## Syntax

```bash
kc whoami [options]
```

## Optional Flags

### `-d, --decode`
Display the full decoded JWT token payload with all claims.

## Examples

### Basic Usage

```bash
kc whoami
```

**Output:**
```
john
```

### With Token Decoding

```bash
kc whoami -d
```

**Output:**
```
john
JWT Payload:
{
  "accessProfile": "p24x7",
  "at_hash": "xevWqv4MaZ_ft1nYs-wCcg",
  "aud": ["k8s"],
  "auth_time": 1763573723,
  "auth_time_human": "2025-11-19 17:35:23 UTC",
  "authority": "ucrd",
  "azp": "k8s",
  "email": "john@example.com",
  "emails": ["john@example.com"],
  "exp": 1763577323,
  "exp_human": "2025-11-19 18:35:23 UTC",
  "groups": ["developers", "ops"],
  "iat": 1763573723,
  "iat_human": "2025-11-19 17:35:23 UTC",
  "iss": "https://kubauth.example.com",
  "name": "John DOE",
  "office": "208G",
  "rat": 1763573723,
  "rat_human": "2025-11-19 17:35:23 UTC",
  "sub": "john"
}
```

## Prerequisites

### kubectl Configuration

The `kc whoami` command requires:

1. **kubectl configured** - With valid kubeconfig
2. **OIDC authentication** - Configured via `kc config`
3. **Active session** - You must have authenticated at least once

### Setup

```bash
# Configure kubectl for OIDC
kc config https://kubeconfig.example.com/kubeconfig

# Trigger initial authentication
kubectl get nodes

# Now whoami will work
kc whoami
```

## Use Cases

### Verify Identity

```bash
# Check who you're authenticated as
kc whoami

# Before running sensitive operations
kc whoami && kubectl delete namespace production
```

### Check Group Memberships

```bash
# See what groups you belong to
kc whoami -d | grep groups
```

**Output:**
```json
  "groups": ["developers", "ops", "cluster-admins"]
```

### Verify Claims

```bash
# Check custom claims in your token
kc whoami -d | grep -E '"office"|"department"'
```

### Debugging RBAC

```bash
# Check your identity when troubleshooting permissions
kubectl get pods
# Error: forbidden

# Verify who kubectl thinks you are
kc whoami -d

# Check if you're in the expected groups
kc whoami -d | grep groups
```

### Script Validation

```bash
#!/bin/bash
# Ensure we're running as the correct user
CURRENT_USER=$(kc whoami)
EXPECTED_USER="admin"

if [ "$CURRENT_USER" != "$EXPECTED_USER" ]; then
  echo "Error: Must run as $EXPECTED_USER, currently: $CURRENT_USER"
  exit 1
fi

# Proceed with admin operations...
```

### Multi-Cluster Management

```bash
# Check identity in current context
echo "Current context: $(kubectl config current-context)"
echo "Current user: $(kc whoami)"

# Switch context and verify
kubectl config use-context production
echo "Switched to: $(kubectl config current-context)"
echo "User: $(kc whoami)"
```

## How It Works

The command:

1. **Reads kubeconfig** - Finds the current context and user
2. **Extracts OIDC config** - Locates the exec plugin configuration
3. **Retrieves token** - Calls the oidc-login plugin to get current token
4. **Decodes JWT** - Extracts the `sub` (subject) claim
5. **Displays result** - Shows username (and full payload with `-d`)

## Comparison with kubectl

| Command | Purpose | Output |
|---------|---------|--------|
| `kc whoami` | Show OIDC username | `john` |
| `kc whoami -d` | Show full token | Username + all claims |
| `kubectl auth whoami` | Show Kubernetes identity | Full auth info including groups |

## Troubleshooting

### No OIDC Configuration

**Error:**
```
No OIDC configuration found in kubeconfig
```

**Solution:** Configure kubectl for OIDC:
```bash
kc config https://kubeconfig.example.com/kubeconfig
```

### Token Expired

**Error:**
```
Error: failed to get token: token expired
```

**Solution:** Authenticate again:
```bash
kubectl get nodes
# This will trigger re-authentication

# Then try again
kc whoami
```

### Wrong Context

If `kc whoami` shows unexpected results:

```bash
# Check current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch to correct context
kubectl config use-context oidc-cluster1
```

### kubectl Not Configured

**Error:**
```
Error: unable to read kubeconfig
```

**Solution:** Ensure kubectl is configured:
```bash
kubectl config view
```

## Related Commands

- [`kc config`](190-config.md) - Configure kubectl for OIDC
- [`kc logout`](180-logout.md) - Clear authentication session
- [`kc token`](130-token.md) - Get OIDC tokens
- [`kc jwt`](160-jwt.md) - Decode JWT tokens

## See Also

- [Workstation Setup](../50-kubernetes-integration/140-workstation-setup.md)
- [Kubernetes Integration](../50-kubernetes-integration/110-overview.md)

