# kc config

## Overview

The `kc config` command configures `kubectl` for OIDC authentication with Kubauth. 
It fetches configuration from the Kubauth kubeconfig service and automatically 
sets up your local `~/.kube/config` file (Or the file set by `KUBECONFIG` environment variable) with the necessary OIDC settings.

## Syntax

```bash
kc config <kubeconfig-service-url> [options]
```

## Arguments

### `<kubeconfig-service-url>`
string - required

The URL of the Kubauth kubeconfig service endpoint.

**Format:** `https://<host>/kubeconfig`

**Example:** `https://kubeconfig.example.com/kubeconfig`

## Flags

### `--force`
Overwrite existing context if it already exists in your kubeconfig.

-----
### `--insecureSkipVerify`
Skip TLS certificate verification. Use only for testing with self-signed certificates.

Example: --insecureSkipVerify

-----
### `--grantType` (string)
Specify the OAuth2 grant type to use.

**Values:**
- `auto` (default) - Authorization code flow with browser
- `password` - Resource Owner Password Credentials flow (no browser)

**Example:** `--grantType password`

## Examples

### Basic Usage

```bash
kc config https://kubeconfig.example.com/kubeconfig
```

**Output:**
```
Setup new context 'oidc-cluster1' in kubeconfig file '/Users/john/.kube/config'
```

### Overwrite Existing Context

```bash
kc config https://kubeconfig.example.com/kubeconfig --force
```

### Configure for Password Grant (No Browser)

```bash
kc config https://kubeconfig.example.com/kubeconfig --grantType password
```

This is useful for remote servers without browser access

### Skip TLS Verification (Testing Only)

```bash
kc config https://kubeconfig.local/kubeconfig --insecureSkipVerify
```

## Behavior

### What It Does

- **Fetches Configuration** - Retrieves OIDC and cluster configuration from the kubeconfig service running on the cluster
- **Updates ~/.kube/config** - Adds or updates:
     - Cluster definition (API server URL, CA certificate)
     - Context definition (links cluster and user)
     - User definition (OIDC authentication settings)
- **Sets Current Context** - Makes the new context active

### Configuration Retrieved

The kubeconfig service provides:

- **Cluster information:**
    - API server URL
    - API server CA certificate
- **OIDC settings:**
    - Issuer URL
    - Client ID
    - Client secret (if any)
    - Issuer CA certificate
- **Context settings:**
    - Context name
    - Default namespace (optional)

### Resulting Kubeconfig

After running `kc config`, your kubeconfig will contain:

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
      - --oidc-extra-scope=offline
      - --oidc-pkce-method=auto
      command: kubectl
      env: null
      interactiveMode: IfAvailable
      provideClusterInfo: false
```

## Prerequisites

### kubelogin Plugin

The `kc config` command configures kubectl to use the `kubectl oidc-login` plugin. Ensure the [kubelogin plugin](https://github.com/int128/kubelogin){:target="_blank"} is installed:

```bash
# Homebrew (macOS and Linux)
brew install kubelogin

# Krew (cross-platform)
kubectl krew install oidc-login

# Chocolatey (Windows)
choco install kubelogin
```

Verify installation:

```bash
kubectl oidc-login --version
```

### Kubeconfig Service

The Kubauth kubeconfig service must be deployed and accessible. See [Kubeconfig Service](../50-kubernetes-integration/130-kubeconfig-service.md) for setup instructions.

## Troubleshooting

### Context Already Exists

**Error:**
```
Error: context 'oidc-cluster1' already exists in kubeconfig
```

**Solution:** Use `--force` to overwrite:
```bash
kc config https://kubeconfig.example.com/kubeconfig --force
```

### Cannot Reach Service

**Error:**
```
Error: failed to fetch configuration: Get "https://kubeconfig.example.com/kubeconfig": dial tcp: lookup kubeconfig.example.com: no such host
```

**Solutions:**

- Verify the URL is correct
- Check network connectivity
- Ensure the kubeconfig service is running and ingress is correctly set:
  ```bash
  kubectl -n kubauth get pods
  kubectl -n kubauth get ingress kubauth-kubeconfig
  ```

### TLS Certificate Error

**Error:**
```
Error: x509: certificate signed by unknown authority
```

**Solutions:**

- Use `--insecureSkipVerify` for testing (not recommended for production)
 - Add CA certificate to system trust store. To extract the CA:
    ```bash
    kubectl -n kubauth get secret kubauth-oidc-server-cert \
      -o=jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
    ```

### kubelogin Not Found

**Error:**
```
Error: exec plugin: invalid apiVersion "client.authentication.k8s.io/v1"
```

**Solution:** Install the kubelogin plugin (see Prerequisites above).

## Security Considerations

1. **Protect kubeconfig** - Your `~/.kube/config` file contains sensitive information
   ```bash
   chmod 600 ~/.kube/config
   ```

2. **Verify TLS** - Only use `--insecureSkipVerify` for testing

3. **Review configuration** - After running `kc config`, inspect your kubeconfig:
   ```bash
   kubectl config view
   ```

4. **Client secrets** - Client secrets in kubeconfig are base64-encoded, not encrypted

## Related Commands

- [`kc whoami`](170-whoami.md) - Verify your configuration
- [`kc logout`](180-logout.md) - Clear authentication session
- [`kc token`](130-token.md) - Test OIDC authentication

## See Also

- [Kubeconfig Service](../50-kubernetes-integration/130-kubeconfig-service.md)
- [Workstation Setup](../50-kubernetes-integration/140-workstation-setup.md)
- [Kubernetes Integration Overview](../50-kubernetes-integration/110-overview.md)

