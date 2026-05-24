# kc logout

## Overview

The `kc logout` command clears your authentication state with Kubauth. It can perform two independent actions:

- **SSO logout** — Open the browser on the Kubauth `end_session_endpoint` to drop the cross-application "Remember me" cookie.
- **Kubernetes logout** — Clear the local kubectl OIDC cache (`kubelogin` cache for exec-plugin contexts, or the `id-token`/`refresh-token` fields of the `oidc` auth provider for standalone contexts).

If neither `--sso` nor `--k8s` is given, **both** actions are performed.

## Syntax

```bash
kc logout [--sso] [--k8s] [options]
```

## Flags

### Action selection

#### `-s`, `--sso`

Perform only the SSO logout (opens a browser on the Kubauth `end_session_endpoint`).

#### `-k`, `--k8s`

Perform only the kubectl/Kubernetes logout (clears the local kubectl OIDC cache).

> When neither flag is set, both actions are performed.

### Connection flags

#### `-i`, `--issuerURL` (string)

Kubauth OIDC issuer URL. Required for the SSO logout (used to discover the `end_session_endpoint`). May also be set via `KC_ISSUER_URL`.

When the value is omitted, `kc` falls back to the issuer URL recorded in the current kubeconfig.

#### `--insecureSkipVerify`

Skip TLS certificate verification of the issuer URL.

#### `--caFile <path>` (repeatable)

Trusted CA certificate(s) for the issuer URL.

#### `--kubeconfig` (string)

Path to the kubeconfig file. Defaults to `$KUBECONFIG`, then `$HOME/.kube/config`.

#### `--context` (string)

Override the kubeconfig context. Defaults to the file's `current-context`.

### Browser

#### `--browser` (string)

Override the default browser used for the SSO logout. Possible values: `chrome`, `firefox`, `safari`.

### Logging

- `--logMode <text|json>`
- `-l`, `--logLevel <DEBUG|INFO|WARN|ERROR>`
- `--dumpClientExchanges` — Dump HTTP requests/responses against the issuer

## Examples

### Full logout (default)

```bash
kc logout --issuerURL https://kubauth.example.com
```

If a kubectl OIDC context is configured:

```
CLeaning kubelogin OIDC configuration if any
Opening browser to logout endpoint: https://kubauth.example.com/oauth2/sessions/logout
```

If no kubectl OIDC context is configured:

```
No OIDC configuration found in kubeconfig
Opening browser to logout endpoint: https://kubauth.example.com/oauth2/sessions/logout
```

!!! note
    The "No OIDC configuration found in kubeconfig" message simply means kubectl has not been configured via `kc config` / `kc init`. Pass `--sso` to skip the kubectl-side logout entirely (and suppress that message).

### SSO logout only

```bash
kc logout --issuerURL https://kubauth.example.com --sso
```

### Kubectl logout only

```bash
kc logout --k8s
```

This does not open a browser. It uses the current kubeconfig to locate the OIDC configuration and clears the local cached tokens.

### Issuer URL inferred from kubeconfig

When kubectl was previously configured with `kc config` / `kc init`, the issuer URL can be omitted:

```bash
kc logout
```

## Behavior

### What it does

1. **kubectl logout** (`--k8s`, default) — Based on the kind of OIDC context:
    - **Exec-plugin context (default mode):** runs `kubectl oidc-login clean` to drop the `kubelogin` cache.
    - **Standalone context (`kc config --standalone`):** removes the `id-token` and `refresh-token` fields from the kubeconfig `oidc` auth provider entry.
2. **SSO logout** (`--sso`, default) — Discovers the `end_session_endpoint` from `/.well-known/openid-configuration` and opens it in the browser. This clears the cross-application Kubauth SSO session cookie.

### SSO Session vs Local Cache

#### SSO session (server-side, cross application)

- Stored as a cookie on the Kubauth domain
- Created when the user ticks "Remember me"
- Shared by all OIDC clients of the same Kubauth server
- Cleared by `kc logout --sso`

#### Local cache (client-side, kubectl only)

- Stored locally (kubelogin cache or kubeconfig fields)
- Only used by `kubectl` exec-plugin
- Cleared by `kc logout --k8s`

## Logout Page

After SSO logout, Kubauth displays a page listing available applications:

![Kubauth Logout Page](../assets/kubauth-logout2.png)

This page lists the OIDC clients that have `displayName`, `description`, and `entryURL` configured.

## Troubleshooting

### TLS Certificate Errors

**Error:**

```
Error: x509: certificate signed by unknown authority
```

**Solutions:**

- Use `--insecureSkipVerify` for testing (not recommended for production).
- Provide a CA: `--caFile ./ca.crt`. To extract it:
   ```bash
   kubectl -n kubauth get secret kubauth-oidc-server-cert \
     -o=jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
   ```
- Or add the CA to the system trust store.

## Related Commands

- [`kc token`](130-token.md) — Authenticate and get tokens
- [`kc whoami`](170-whoami.md) — Check current authentication
- [`kc config`](190-config.md) — Configure kubectl

## See Also

- [SSO Session](../30-user-guide/140-sso.md)
- [Workstation Setup](../50-kubernetes-integration/140-workstation-setup.md#logout)
