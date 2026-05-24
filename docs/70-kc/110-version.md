# kc version

## Overview

The `kc version` command displays version information for the `kc` CLI tool.

## Syntax

```bash
kc version [--extended]
```

## Flags

### `--extended`, `-e` { #extended }

<p class="api-meta">
<span class="api-badge api-type">bool</span>
<span class="api-badge api-default">default: <code>false</code></span>
</p>

Append the build timestamp to the version string.

## Example

```
$ kc version
0.2.1

$ kc version -e
0.2.1.20260524.080310
```

The extended form is `<version>.<YYYYMMDD>.<HHMMSS>` and identifies the exact build of the binary you are running.
