# kc CLI Tool

## Overview

`kc` is the companion CLI tool for Kubauth. It exercises OIDC flows against a Kubauth server, manages kubectl OIDC configuration, and provides a few utilities to ease day-to-day operations.

**GitHub Repository:** [https://github.com/kubauth/kc](https://github.com/kubauth/kc)

**Documented version:** `v0.2.1`

## Purpose

The `kc` CLI tool serves multiple purposes:

1. **OIDC flow testing** — Exercise Authorization Code, ROPC and Client Credentials flows
2. **Token inspection** — Obtain, decode and verify ID/access tokens
3. **Kubeconfig setup** — Automate kubectl configuration for OIDC authentication
4. **Audit queries** — List login attempts and inspect per-provider authentication details
5. **Utilities** — Generate bcrypt hashes, decode arbitrary JWTs, logout, etc.

## Installation

Download the latest release from the [GitHub releases page](https://github.com/kubauth/kc/releases/tag/v0.2.1){:target="_blank"} and install it on your system.

### macOS and Linux

```bash
# Download the appropriate binary for your system
# For example, on macOS:
mv kc_darwin_amd64 kc
chmod +x kc
sudo mv kc /usr/local/bin/
```

### Windows

```powershell
# Rename and move to a directory in your PATH
mv kc_windows_amd64.exe kc.exe
# Move to a directory in your PATH, e.g., C:\Windows\System32\
```

### Verify Installation

```bash
kc version
```

## Available Commands

### Authentication & Tokens

- **[`kc token`](130-token.md)** — Authorization Code flow (browser-based)
- **[`kc token-nui`](140-token-nui.md)** — Resource Owner Password Credentials flow (no browser)
- **[`kc client`](145-client.md)** — Client Credentials flow (machine-to-machine)
- **[`kc jwt`](160-jwt.md)** — Decode and pretty-print a JWT
- **[`kc logout`](180-logout.md)** — Clear the Kubauth SSO session and/or the local kubectl OIDC cache

### Kubernetes Configuration

- **[`kc config`](190-config.md)** (alias **`kc init`**) — Configure kubectl for OIDC authentication
- **[`kc whoami`](170-whoami.md)** — Display the current authenticated user (from kubeconfig)

### Utilities

- **[`kc hash`](120-hash.md)** — Generate a bcrypt hash for a User password
- **[`kc audit`](150-audit.md)** — Query Kubauth authentication audit logs
- **[`kc version`](110-version.md)** — Display version information

## Quick Start

### 1. Test authentication

```bash
kc token --issuerURL https://kubauth.example.com --clientId public
```

### 2. Generate a password hash

```bash
kc hash mypassword123
```

### 3. Configure kubectl

```bash
kc config https://kubeconfig.example.com/kubeconfig
# Same as: kc init https://kubeconfig.example.com/kubeconfig
```

### 4. Check who you are

```bash
kc whoami
```

### 5. View audit logs

```bash
kc audit logins
```

## Common Options

`kc token`, `kc token-nui` and `kc client` share a common set of OIDC connection flags (and `kc logout` and `kc whoami` share most of them too).

### `-i, --issuerURL` (string)

The Kubauth OIDC issuer URL.

**Example:** `--issuerURL https://kubauth.example.com`

May also be set via the `KC_ISSUER_URL` environment variable, or fetched automatically from kubeconfig (see [Kubeconfig integration](#kubeconfig-integration)).

### `-c, --clientId` (string)

The OIDC client ID. May also be set via `KC_CLIENT_ID`.

### `-s, --clientSecret` (string)

Client secret for confidential clients. May also be set via `KC_CLIENT_SECRET`.

### `--insecureSkipVerify`

Skip TLS certificate verification of the issuer URL.

> Use only for testing with self-signed certificates.

### `--caFile` (string, repeatable)

Path to a root CA certificate used to validate the issuer URL. Can be repeated.

### `--scope` (string, repeatable)

OAuth2 scope requested in the authorization/token request. Repeat the flag for multiple scopes.

**Default:** `openid`, `profile`, `groups`

When `--ttl` is used (token renewal loop), `offline_access` is automatically appended if missing.

### `--onlyIdToken` / `--onlyAccessToken`

Print only the corresponding token on stdout (everything else goes to stderr). Useful for piping.

### `-d, --detailIdToken` / `-a, --detailAccessToken`

Print the decoded JWT (header + payload) of the ID token / access token, in addition to the regular output. With `kc token` (browser flow), the success page in the browser always shows token details regardless of these flags; `-d` / `-a` only control the terminal output.

### `--userInfo`

Call the provider `userinfo` endpoint with the obtained access token and print the result (terminal output for all subcommands; the browser success page for `kc token`).

### `--logMode` (string), `-l, --logLevel` (string)

Logging configuration.

- `--logMode`: `text` (default) or `json`
- `--logLevel`: `DEBUG`, `INFO` (default), `WARN`, `ERROR`

### `--dumpClientExchanges`

Dump every outgoing HTTP request and incoming response performed by the `kc` HTTP client (useful for debugging).

## Kubeconfig integration

When `--issuerURL` (and/or the root CA) is omitted, `kc` automatically tries to fetch it from the current kubeconfig (the file pointed to by `--kubeconfig`, the `KUBECONFIG` environment variable, or `$HOME/.kube/config`, in that order). The context defaults to the kubeconfig `current-context`; use `--context` to pick another one.

This works when the kubeconfig was previously initialized with `kc config` / `kc init`, so that the OIDC issuer URL and CA are recorded in the `user` entry.

The flags are accepted on `kc token`, `kc token-nui`, `kc client`, `kc logout` and `kc whoami`:

- `--kubeconfig <path>` — Override the kubeconfig file to read from
- `--context <name>` — Override the kubeconfig context

## Environment Variables

Several commands honor the following environment variables when their command-line flag is not explicitly set:

- `KC_ISSUER_URL` — Default issuer URL
- `KC_CLIENT_ID` — Default client ID
- `KC_CLIENT_SECRET` — Default client secret
- `KC_USER_LOGIN` — Default user login (`kc token-nui`)
- `KC_USER_PASSWORD` — Default user password (`kc token-nui`)
- `KUBECONFIG` — kubeconfig file location

**Example:**

```bash
export KC_ISSUER_URL=https://kubauth.example.com
export KC_CLIENT_ID=public

kc token   # Both --issuerURL and --clientId are now optional
```

## Getting Help

```bash
# Top-level help
kc --help

# Command-specific help
kc token --help
kc config --help
kc audit --help
```

## Use Cases

### Development & Testing

```bash
# Quick authentication test
kc token --issuerURL https://kubauth.local --clientId test

# Decode the resulting ID and access tokens
kc token --issuerURL https://kubauth.local --clientId test -d -a

# Same with a non-browser flow
kc token-nui --issuerURL https://kubauth.local --clientId test \
  --login alice --password alice123 -d
```

### User Management

```bash
# Generate a bcrypt hash for a User password
kc hash strongpassword456

# Inspect the user's last login and merged identity
kc audit detail alice
```

### Kubernetes Integration

```bash
# Configure kubectl for OIDC
kc config https://kubeconfig.example.com/kubeconfig

# Verify configuration
kc whoami

# Log out everywhere (SSO session + local kubectl OIDC cache)
kc logout
```

### CI/CD & Automation

```bash
# Non-interactive authentication for scripts (ROPC must be allowed)
kc token-nui --issuerURL https://kubauth.example.com \
  --clientId automation \
  --login serviceaccount \
  --password "$SERVICE_PASSWORD" \
  --onlyIdToken
```

## Troubleshooting

### Certificate Errors

If you encounter TLS certificate errors against the issuer URL:

- Option 1: Skip verification (not recommended for production)
    ```
    kc token --issuerURL https://kubauth.local --clientId public --insecureSkipVerify
    ```

- Option 2: Provide the CA explicitly

    ```
    kubectl -n kubauth get secret kubauth-oidc-server-cert \
      -o=jsonpath='{.data.ca\.crt}' | base64 -d > kubauth-ca.crt

    kc token --issuerURL https://kubauth.local --clientId public --caFile ./kubauth-ca.crt
    ```

- Option 3: Add the CA to the system trust store (OS-specific).

### Browser Not Opening

If the browser doesn't open automatically with `kc token`:

1. Check the terminal output for the localhost URL.
2. Manually open the URL in your browser.
3. Or use `kc token-nui` for terminal-based authentication.
