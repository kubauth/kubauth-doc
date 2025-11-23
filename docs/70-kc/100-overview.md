# kc CLI Tool

## Overview

`kc` is the companion CLI tool for Kubauth, providing essential utilities for working with the Kubauth OIDC server and Kubernetes authentication.

**GitHub Repository:** [https://github.com/kubauth/kc](https://github.com/kubauth/kc)

## Purpose

The `kc` CLI tool serves multiple purposes:

1. **Authentication Testing** - Quickly test OIDC authentication flows
2. **Token Management** - Obtain and inspect OIDC tokens
3. **Kubeconfig Setup** - Automate kubectl configuration for OIDC authentication
4. **User Management** - Generate password hashes for users and clients
5. **Audit Queries** - View authentication attempts and user details
6. **JWT Inspection** - Decode and display JWT token contents

## Installation

Download the latest release from the [GitHub releases page](https://github.com/kubauth/kc/releases) and install it on your system.

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

- **[`kc token`](130-token.md)** - Obtain OIDC tokens using the authorization code flow (with browser)
- **[`kc token-nui`](140-token-nui.md)** - Obtain OIDC tokens using password grant (no browser required)
- **[`kc jwt`](160-jwt.md)** - Decode and display JWT token contents
- **[`kc logout`](180-logout.md)** - Clear SSO session and local token cache

### Kubernetes Configuration

- **[`kc config`](190-config.md)** - Configure kubectl for OIDC authentication with Kubauth
- **[`kc whoami`](170-whoami.md)** - Display current authenticated user information

### Utilities

- **[`kc hash`](120-hash.md)** - Generate bcrypt hashes for passwords and secrets
- **[`kc audit`](150-audit.md)** - Query authentication audit logs
- **[`kc version`](110-version.md)** - Display version information

## Quick Start

### 1. Test Authentication

```bash
kc token --issuerURL https://kubauth.example.com --clientId public
```

### 2. Generate a Password Hash

```bash
kc hash mypassword123
```

### 3. Configure kubectl

```bash
kc config https://kubeconfig.example.com/kubeconfig
```

### 4. Check Who You Are

```bash
kc whoami
```

### 5. View Audit Logs

```bash
kc audit logins
```

## Common Options

Many `kc` commands share common options:

### `--issuerURL` (string)
The Kubauth OIDC issuer URL.

**Example:** `--issuerURL https://kubauth.example.com`

### `--clientId` (string)
The OIDC client ID.

**Example:** `--clientId public`

### `--insecureSkipVerify`
Skip TLS certificate verification for `ìssuerURL` (useful for testing with self-signed certificates).

**Example:** `--insecureSkipVerify`

### `--caFile`
Provide a CA file for TLS certificate verification of `ìssuerURL`

### `-d, --detailed`
Decode and display JWT token contents (shortcut for piping to `kc jwt`).

**Example:** `kc token --issuerURL https://kubauth.example.com --clientId public -d`

## Kubeconfig configuration File

The `kc` tool can read OIDC configuration from your kubectl config file when available. This eliminates the need to specify `--issuerURL` and `--clientId` for many commands after you've run `kc config`.


## Environment Variables

Some commands support environment variables for configuration:

- `KC_ISSUER_URL` - Default issuer URL
- `KC_CLIENT_ID` - Default client ID
- `KC_CLIENT_SECRET` - Default client secret
- `KC_USER_LOGIN` - Default user login for `token-nui`
- `KC_USER_PASSWORD` - Default user password for `token-nui`

**Example:**
```bash
export KC_ISSUER_URL=https://kubauth.example.com
export KC_CLIENT_ID=public

# Now you can omit these flags
kc token
```

## Getting Help

For help with any command:

```bash
# General help
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

# Decode token to inspect claims
kc token --issuerURL https://kubauth.local --clientId test -d

# Test with different users
kc token-nui --issuerURL https://kubauth.local --clientId test \
  --login alice --password alice123 -d
```

### User Management

```bash
# Generate password hash for a new user
kc hash strongpassword456

# Check user's groups and claims
kc audit detail username
```

### Kubernetes Integration

```bash
# Configure kubectl for OIDC
kc config https://kubeconfig.example.com/kubeconfig

# Verify configuration
kc whoami

# Log out to switch users
kc logout
```

### CI/CD & Automation

```bash
# Non-interactive authentication for scripts
kc token-nui --issuerURL https://kubauth.example.com \
  --clientId automation \
  --login serviceaccount \
  --password $SERVICE_PASSWORD \
  --onlyIDToken
```

## Troubleshooting

### Certificate Errors

If you encounter TLS certificate errors:

- Option 1: Skip verification (not recommended for production)
    ```
    kc token --issuerURL https://kubauth.local --clientId public --insecureSkipVerify
    ```

- Option 2: Add CA certificate to your system trust store

    Extract CA certificate
    ```
    kubectl -n kubauth get secret kubauth-oidc-server-cert \
      -o=jsonpath='{.data.ca\.crt}' | base64 -d > kubauth-ca.crt
    ```

    Add to system trust store (OS-specific)


### Browser Not Opening

If the browser doesn't open automatically with `kc token`:

1. Check the console output for the localhost URL
2. Manually open the URL in your browser
3. Or use `kc token-nui` for terminal-based authentication


