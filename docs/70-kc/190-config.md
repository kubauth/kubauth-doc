# kc config

## Overview

The `kc config` command configures `kubectl` for OIDC authentication against Kubauth. It calls a Kubauth **kubeconfig service** endpoint, retrieves all the values needed (API server URL, cluster CA, OIDC issuer URL, client id/secret, default namespace, …), then adds a cluster + user + context to the local kubeconfig file (`$KUBECONFIG`, or `$HOME/.kube/config` if not set).

The command is also available as `kc init`, which is an alias of `kc config`.

By default, kubectl is configured to use the [`kubelogin`](https://github.com/int128/kubelogin){:target="_blank"} exec-plugin (`kubectl oidc-login get-token`). With `--standalone`, kubectl is configured to use the built-in `oidc` auth provider directly (no exec plugin).

## Syntax

```bash
kc config <kubeconfig-service-url> [options]
kc init   <kubeconfig-service-url> [options]
```

## Arguments

### `<kubeconfig-service-url>` { #kubeconfig-service-url }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-required">required</span>
</p>

URL of the Kubauth kubeconfig service endpoint. If the scheme is omitted, `https://` is assumed.

**Format:** `https://<host>/kubeconfig`

**Example:** `https://kubeconfig.example.com/kubeconfig`

## Output / Context Flags

### `--force` { #force }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Overwrite any existing cluster, user or context in the kubeconfig with the same names. Without this flag, the command fails if the target entries already exist.

<hr class="api-field-separator">

### `--noContextSwitch` { #nocontextswitch }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Do not change the `current-context`. Without this flag, the newly created context is set as the default context (unless the kubeconfig already had one — in which case it is replaced).

<hr class="api-field-separator">

### `--kubeconfig` { #kubeconfig }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>$KUBECONFIG</code> or <code>$HOME/.kube/config</code></span>
</p>

Path to the kubeconfig file to update.

## Override Flags

These flags override the corresponding fields returned by the kubeconfig service.

### `--contextNameOverride` { #contextnameoverride }

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Use this name for the new context. It is also used as the base for the cluster name (`<name>-cluster`) and user name (`<name>-user`).

<hr class="api-field-separator">

### `--apiServerURLOverride` { #apiserverurloverride }

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Override the Kubernetes API server URL.

<hr class="api-field-separator">

### `--issuerURLOverride` { #issuerurloverride }

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Override the OIDC issuer URL.

<hr class="api-field-separator">

### `--namespaceOverride` { #namespaceoverride }

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Override the default namespace stored in the context.

## Authentication Mode Flags

### `--standalone` { #standalone }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Configure kubectl to use the **built-in `oidc` auth provider** instead of the `kubelogin` exec-plugin. In this mode the tokens are stored in the kubeconfig itself (under the `oidc` auth provider entry) and renewed in-place. Use this when you cannot install the `kubelogin` plugin on the workstation.

!!! note

    The standalone `oidc` auth provider in `client-go` does not support PKCE.

<hr class="api-field-separator">

### `--grantType` { #granttype }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>auto</code></span>
</p>

OAuth2 grant type used by `kubelogin` (ignored when `--standalone` is set).

Accepted values:

- `auto` — Authorization Code flow (browser-based) with a sensible fallback
- `authcode` — Authorization Code flow only
- `authcode-keyboard` — Authorization Code with keyboard interactive code paste (`kubelogin` listens on `http://localhost:8000`)
- `password` — Resource Owner Password Credentials (no browser)
- `device-code` — OAuth2 Device Authorization Grant
- `client-credentials` — Client Credentials flow

<hr class="api-field-separator">

### `--pkce` { #pkce }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-default">default: <code>auto</code></span>
</p>

PKCE strategy passed to `kubelogin`. One of `auto`, `no`, `S256`.

<hr class="api-field-separator">

### `--scope` { #scope }

<p class="api-meta">
<span class="api-badge api-type">string</span>
<span class="api-badge api-repeatable">repeatable</span>
</p>

Extra OAuth2 scopes appended to the request. `openid` and `offline_access` are always added by `kubelogin`/`kc`.

## Connection Flags

| Flag                                   | Type   | Default                               |
|----------------------------------------|--------|---------------------------------------|
| `--insecureSkipVerify`                 | bool   | `false`                               |
| `--caFile` <small>(repeatable)</small> | string | —                                     |
| `--logMode`                            | string | `text`                                |
| `--logLevel`, `-l`                     | string | `INFO`                                |
| `--dumpExchanges`                      | bool   | `false`                               |

!!! info

    `--insecureSkipVerify` and `--caFile` apply to the call against the **kubeconfig service** URL.

## Examples

### Basic Usage

```bash
kc config https://kubeconfig.example.com/kubeconfig
```

Output:

```
Setup new context 'oidc-cluster1' in kubeconfig file '/Users/john/.kube/config'
```

`kc init` is equivalent:

```bash
kc init https://kubeconfig.example.com/kubeconfig
```

### Overwrite Existing Context

```bash
kc config https://kubeconfig.example.com/kubeconfig --force
```

### Standalone Mode (no kubelogin plugin)

```bash
kc config https://kubeconfig.example.com/kubeconfig --standalone
```

### Configure for Password Grant (No Browser)

```bash
kc config https://kubeconfig.example.com/kubeconfig --grantType password
```

Useful for remote servers without browser access.

### Override the Context Name

```bash
kc config https://kubeconfig.example.com/kubeconfig --contextNameOverride staging-cluster
```

### Skip TLS Verification (Testing Only)

```bash
kc config https://kubeconfig.local/kubeconfig --insecureSkipVerify
```

## Behavior

### What It Does

- **Fetches configuration** — Retrieves OIDC and cluster information from the kubeconfig service running in the cluster.
- **Updates kubeconfig** — Adds or updates:
     - Cluster definition (API server URL, CA certificate)
     - User definition (OIDC authentication settings, either via the `kubelogin` exec-plugin or the standalone `oidc` auth provider)
     - Context definition (cluster + user + default namespace)
- **Sets current context** — Makes the new context active (unless `--noContextSwitch` is given).

### Resulting Kubeconfig (default — exec plugin)

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTi...
    server: https://api.cluster.example.com:6443
  name: oidc-cluster1-cluster
contexts:
- context:
    cluster: oidc-cluster1-cluster
    user: oidc-cluster1-user
  name: oidc-cluster1
current-context: oidc-cluster1
kind: Config
users:
- name: oidc-cluster1-user
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1
      args:
      - oidc-login
      - get-token
      - --oidc-issuer-url=https://kubauth.example.com
      - --oidc-client-id=k8s
      - --oidc-client-secret=k8s123
      - --certificate-authority-data=LS0tLS1CRUdJTi...
      - --insecure-skip-tls-verify=false
      - --grant-type=auto
      - --oidc-extra-scope=offline_access
      - --oidc-pkce-method=auto
      command: kubectl
      env: null
      interactiveMode: IfAvailable
      provideClusterInfo: false
```

### Resulting Kubeconfig (`--standalone`)

```yaml
users:
- name: oidc-cluster1-user
  user:
    auth-provider:
      name: oidc
      config:
        idp-issuer-url: https://kubauth.example.com
        client-id: k8s
        client-secret: k8s123
        idp-certificate-authority-data: LS0tLS1CRUdJTi...
        extra-scopes: offline_access
```

## Prerequisites

### kubelogin Plugin (default mode)

Unless `--standalone` is used, the resulting kubeconfig invokes `kubectl oidc-login get-token`. Install the [`kubelogin`](https://github.com/int128/kubelogin){:target="_blank"} plugin:

```bash
# Homebrew (macOS and Linux)
brew install kubelogin

# Krew (cross-platform)
kubectl krew install oidc-login

# Chocolatey (Windows)
choco install kubelogin
```

Verify the installation:

```bash
kubectl oidc-login --version
```

### Kubeconfig Service

The Kubauth kubeconfig service must be deployed and accessible. See [Kubeconfig Service](../50-kubernetes-integration/130-kubeconfig-service.md) for setup instructions.

## Troubleshooting

### Context Already Exists

Error:

```
context 'oidc-cluster1' already exists in this config file (...). Use --force to override
```

Solution: re-run with `--force`:

```bash
kc config https://kubeconfig.example.com/kubeconfig --force
```

### Cannot Reach Service

Error:

```
Error: failed to fetch Kubeconfig configuration: Get "https://kubeconfig.example.com/kubeconfig": dial tcp: lookup kubeconfig.example.com: no such host
```

Solutions:

- Verify the URL is correct.
- Check network connectivity.
- Ensure the kubeconfig service is running and reachable via ingress:
  ```bash
  kubectl -n kubauth get pods
  kubectl -n kubauth get ingress kubauth-kubeconfig
  ```

### TLS Certificate Error

Error:

```
Error: x509: certificate signed by unknown authority
```

Solutions:

- Use `--insecureSkipVerify` for testing (not recommended for production).
- Provide a CA: `--caFile ./ca.crt`. To extract it:
   ```bash
   kubectl -n kubauth get secret kubauth-oidc-server-cert \
     -o=jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
   ```
- Or add the CA to the system trust store.

### kubelogin Not Found

Error:

```
Error: exec plugin: invalid apiVersion "client.authentication.k8s.io/v1"
```

Solution: install the `kubelogin` plugin (see Prerequisites above), or re-run `kc config` with `--standalone` to use the built-in `oidc` auth provider instead.

## Security Considerations

1. **Protect kubeconfig** — `~/.kube/config` contains sensitive information.
   ```bash
   chmod 600 ~/.kube/config
   ```

2. **Verify TLS** — Only use `--insecureSkipVerify` for testing.

3. **Review configuration** — Inspect the resulting kubeconfig:
   ```bash
   kubectl config view
   ```

4. **Client secrets** — Client secrets in kubeconfig are stored in clear text (not encrypted).

## Related Commands

- [`kc whoami`](170-whoami.md) — Verify the resulting configuration
- [`kc logout`](180-logout.md) — Clear authentication session
- [`kc token`](130-token.md) — Test OIDC authentication directly (without kubectl)

## See Also

- [Kubeconfig Service](../50-kubernetes-integration/130-kubeconfig-service.md)
- [Workstation Setup](../50-kubernetes-integration/140-workstation-setup.md)
- [Kubernetes Integration Overview](../50-kubernetes-integration/110-overview.md)
