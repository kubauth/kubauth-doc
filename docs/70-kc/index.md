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

- **[`kc token`](token.md)** - Obtain OIDC tokens using the authorization code flow (with browser)
- **[`kc token-nui`](token-nui.md)** - Obtain OIDC tokens using password grant (no browser required)
- **[`kc jwt`](jwt.md)** - Decode and display JWT token contents
- **[`kc logout`](logout.md)** - Clear SSO session and local token cache

### Kubernetes Configuration

- **[`kc config`](config.md)** - Configure kubectl for OIDC authentication with Kubauth
- **[`kc whoami`](whoami.md)** - Display current authenticated user information

### Utilities

- **[`kc hash`](hash.md)** - Generate bcrypt hashes for passwords and secrets
- **[`kc audit`](audit.md)** - Query authentication audit logs
- **[`kc version`](version.md)** - Display version information

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
Skip TLS certificate verification (useful for testing with self-signed certificates).

**Example:** `--insecureSkipVerify`

### `-d, --decode`
Decode and display JWT token contents (shortcut for piping to `kc jwt`).

**Example:** `kc token --issuerURL https://kubauth.example.com --clientId public -d`

## Configuration File

The `kc` tool can read OIDC configuration from your kubectl config file when available. This eliminates the need to specify `--issuerURL` and `--clientId` for many commands after you've run `kc config`.

**Commands that use kubeconfig:**
- `kc whoami`
- `kc logout` (when no `--issuerURL` is provided)

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

## Environment Variables

Some commands support environment variables for configuration:

- `KC_ISSUER_URL` - Default issuer URL
- `KC_CLIENT_ID` - Default client ID
- `KC_CLIENT_SECRET` - Default client secret

**Example:**
```bash
export KC_ISSUER_URL=https://kubauth.example.com
export KC_CLIENT_ID=public

# Now you can omit these flags
kc token
```

## Exit Codes

`kc` uses standard exit codes:

- `0` - Success
- `1` - General error
- `2` - Authentication error
- `3` - Configuration error

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

## Troubleshooting

### Certificate Errors

If you encounter TLS certificate errors:

```bash
# Option 1: Skip verification (not recommended for production)
kc token --issuerURL https://kubauth.local --clientId public --insecureSkipVerify

# Option 2: Add CA certificate to your system trust store
# Extract CA certificate
kubectl -n kubauth get secret kubauth-oidc-server-cert \
  -o=jsonpath='{.data.ca\.crt}' | base64 -d > kubauth-ca.crt

# Add to system trust store (OS-specific)
```

### Browser Not Opening

If the browser doesn't open automatically with `kc token`:

1. Check the console output for the localhost URL
2. Manually open the URL in your browser
3. Or use `kc token-nui` for terminal-based authentication

### Authentication Failures

```bash
# Check detailed error messages
kc token --issuerURL https://kubauth.example.com --clientId public

# Verify user exists and password is correct
kc audit logins

# Check user details
kc audit detail username
```

## Best Practices

1. **Use `kc config` for kubectl** - Automates kubeconfig setup correctly
2. **Secure password hashes** - Never commit plain-text passwords
3. **Use `--insecureSkipVerify` carefully** - Only for development/testing
4. **Leverage `kc whoami`** - Verify your identity before operations
5. **Check audit logs** - Use `kc audit` to troubleshoot authentication issues
6. **Use environment variables** - Simplify repetitive commands
7. **Pipe tokens carefully** - Be cautious when piping tokens in scripts

## Related Documentation

- [Installation](../20-installation.md#kc-cli-tool-installation)
- [User Configuration](../30-user-guide/110-configuration.md)
- [Kubernetes Integration](../50-kubernetes-integration/140-workstation-setup.md)
- [API Reference](../60-references/index.md)

