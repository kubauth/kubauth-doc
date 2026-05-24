# kc whoami

## Overview

The `kc whoami` command displays the currently authenticated user, as recorded in your kubectl configuration. It reads the cached ID token (either from the `kubelogin` cache or from the `oidc` auth provider entry when using standalone mode) and shows the `sub` claim — and, optionally, the full decoded JWT payload.

If no OIDC configuration is found, the command prints `unknown`.

## Syntax

```bash
kc whoami [options]
```

## Flags

### `--detailed`, `-d` { #detailed }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Display the full decoded JWT payload (all claims) in addition to the username.

<hr class="api-field-separator">

### `--kubeconfig` { #kubeconfig }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>$KUBECONFIG</code> or <code>$HOME/.kube/config</code></span>
</p>

Path to the kubeconfig file to read from.

<hr class="api-field-separator">

### `--context` { #context }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: kubeconfig <code>current-context</code></span>
</p>

Override the kubeconfig context.

<hr class="api-field-separator">

### `--logMode` { #logmode }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>text</code></span>
</p>

Logging output mode. One of `text`, `json`.

<hr class="api-field-separator">

### `--logLevel`, `-l` { #loglevel }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>INFO</code></span>
</p>

Logging verbosity. One of `DEBUG`, `INFO`, `WARN`, `ERROR`.

## Examples

### Basic Usage

```bash
kc whoami
```

Output:

```
john
```

If the cached ID token is expired, the username is suffixed with `  (expired)`:

```
john  (expired)
```

### With Token Decoding

```bash
kc whoami -d
```

Output:

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

1. **kubectl configured** — with valid kubeconfig.
2. **OIDC authentication** — configured via `kc config`.
3. **Active session** — you must have authenticated at least once.

### Setup

```bash
# Configure kubectl for OIDC
kc config https://kubeconfig.example.com/kubeconfig
# (or equivalently: kc init https://kubeconfig.example.com/kubeconfig)

# Trigger initial authentication
kubectl get nodes

# Now whoami will work
kc whoami
```

## Comparison with kubectl

| Command               | Purpose                  | Output                                       |
|-----------------------|--------------------------|----------------------------------------------|
| `kc whoami`           | Show OIDC username       | `john`                                       |
| `kc whoami -d`        | Show full token          | Username + all claims                        |
| `kubectl auth whoami` | Show Kubernetes identity | Full auth info including groups              |

## Related Commands

- [`kc config`](190-config.md) — Configure kubectl for OIDC
- [`kc logout`](180-logout.md) — Clear authentication session
- [`kc token`](130-token.md) — Get OIDC tokens
- [`kc jwt`](160-jwt.md) — Decode JWT tokens

## See Also

- [Workstation Setup](../50-kubernetes-integration/140-workstation-setup.md)
- [Kubernetes Integration](../50-kubernetes-integration/110-overview.md)
