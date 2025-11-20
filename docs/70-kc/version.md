# kc version

## Overview

The `kc version` command displays version information for the `kc` CLI tool.

## Syntax

```bash
kc version
```

## Examples

### Display Version

```bash
kc version
```

**Output:**
```
kc version: 0.3.1
```

## Use Cases

### Verify Installation

```bash
# Check if kc is properly installed
kc version
```

### Troubleshooting

When reporting issues or bugs:

```bash
# Include version information
kc version
# Output: kc version: 0.3.1
```

### Check for Updates

Compare your installed version with the [latest release on GitHub](https://github.com/kubauth/kc/releases):

```bash
kc version
# Check against https://github.com/kubauth/kc/releases/latest
```

### Script Compatibility

```bash
#!/bin/bash
VERSION=$(kc version | awk '{print $3}')
REQUIRED="0.3.0"

if [ "$(printf '%s\n' "$REQUIRED" "$VERSION" | sort -V | head -n1)" != "$REQUIRED" ]; then
  echo "Error: kc version $REQUIRED or higher required (found $VERSION)"
  exit 1
fi

echo "kc version $VERSION is compatible"
```

## Version History

The `kc` tool follows [semantic versioning](https://semver.org/):

- **Major version** - Incompatible API changes
- **Minor version** - New functionality (backward compatible)
- **Patch version** - Bug fixes (backward compatible)

## Updating kc

### Check Current Version

```bash
kc version
```

### Download Latest Release

Visit the [GitHub releases page](https://github.com/kubauth/kc/releases) and download the appropriate binary for your system.

### Replace Binary

```bash
# Backup current version
sudo cp /usr/local/bin/kc /usr/local/bin/kc.backup

# Replace with new version
sudo mv kc_<platform>_<arch> /usr/local/bin/kc
sudo chmod +x /usr/local/bin/kc

# Verify
kc version
```

## Related Commands

All `kc` commands are documented in the [kc CLI overview](index.md).

## See Also

- [GitHub Repository](https://github.com/kubauth/kc)
- [Release Notes](https://github.com/kubauth/kc/releases)
- [Installation](../20-installation.md#kc-cli-tool-installation)

