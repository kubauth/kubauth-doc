# kc whoami

## Overview

The `kc whoami` command displays the currently authenticated user information from your kubectl configuration. It extracts and shows the username and optionally the full JWT token payload.

## Syntax

```bash
kc whoami [options]
```

## Optional Flags

### `-d, --detailed`
Display the full decoded JWT token payload with all claims.

## Examples

### Basic Usage

``` { .bash .copy }
kc whoami
```

**Output:**
```
john
```

### With Token Decoding

``` { .bash .copy }
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

``` { .bash .copy }
# Configure kubectl for OIDC
kc config https://kubeconfig.example.com/kubeconfig

# Trigger initial authentication
kubectl get nodes

# Now whoami will work
kc whoami
```

## Comparison with kubectl

| Command | Purpose | Output |
|---------|---------|--------|
| `kc whoami` | Show OIDC username | `john` |
| `kc whoami -d` | Show full token | Username + all claims |
| `kubectl auth whoami` | Show Kubernetes identity | Full auth info including groups |

## Related Commands

- [`kc config`](190-config.md) - Configure kubectl for OIDC
- [`kc logout`](180-logout.md) - Clear authentication session
- [`kc token`](130-token.md) - Get OIDC tokens
- [`kc jwt`](160-jwt.md) - Decode JWT tokens

## See Also

- [Workstation Setup](../50-kubernetes-integration/140-workstation-setup.md)
- [Kubernetes Integration](../50-kubernetes-integration/110-overview.md)

