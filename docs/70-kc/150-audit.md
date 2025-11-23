# kc audit

## Overview

The `kc audit` command queries Kubauth authentication audit logs. It provides two subcommands to view login attempts and detailed user authentication information.

## flags
### `--namespace`
string

The namespace storing the audit logs

**Default:** `kubauth-audit`

## kc audit logins
Display all login attempts with status, user information, and authentication source.

### Syntax

```bash
kc audit logins [options]
```

### Examples

#### View All Login Attempts

``` { .bash .copy }
kc audit logins
```

**Output:**
```
WHEN           LOGIN   STATUS            UID   NAME         GROUPS             CLAIMS                                      EMAILS                  AUTH
Mon 12:22:31   jim     passwordChecked   -                  []                 {}                                          []                      
Mon 12:58:29   john    passwordChecked   -     John DOE     []                 {"office":"208G"}                           [johnd@mycompany.com]   
Mon 15:34:59   john    passwordChecked   -     John DOE     []                 {"office":"208G"}                           [johnd@mycompany.com]   
Tue 18:59:16   fred    passwordChecked   -     Fred ASTER   [staff,managers]   {}                                          [fred@mycompany.com]    ldap
Tue 19:02:20   jim     userNotFound      -                  []                 {}                                          []                    
```

### Output Fields

- **WHEN** - Timestamp of the login attempt
- **LOGIN** - Username attempted
- **STATUS** - Authentication status:
    - `passwordChecked` - Successful authentication
    - `passwordFail` - Invalid password
    - `userNotFound` - User doesn't exist
- **UID** - Numerical user ID
- **NAME** - User's full name
- **GROUPS** - User's group memberships
- **CLAIMS** - Custom claims from User/Group resources
- **EMAILS** - User's email addresses
- **AUTH** - Authentication authority (identity provider name)

## kc audit detail
Display detailed authentication information for a specific user's last login, including per-provider breakdown.

### Syntax

```bash
kc audit detail <username>
```

### Arguments

#### `<username>` 
string - required)

The username to query detailed information for.

### Examples

#### View Single Provider Authentication

``` { .bash .copy }
kc audit detail john
```

**Output:**
```
WHEN           LOGIN   STATUS            UID   NAME       GROUPS       CLAIMS                                      EMAILS                  AUTH
Thu 16:14:04   john    passwordChecked   -     John DOE   [devs,ops]   {"accessProfile":"p24x7","office":"208G"}   [johnd@mycompany.com]   ucrd
Detail:
PROVIDER   STATUS            UID   NAME       GROUPS       CLAIMS                                      EMAILS
ldap       userNotFound      -                []           {}                                          []
ucrd       passwordChecked   -     John DOE   [devs,ops]   {"accessProfile":"p24x7","office":"208G"}   [johnd@mycompany.com]
```

#### View Merged Identity

``` { .bash .copy }
kc audit detail bob
```

**Output:**
```
WHEN           LOGIN   STATUS            UID   NAME         GROUPS        CLAIMS                      EMAILS                AUTH
Thu 14:15:06   bob     passwordChecked   -     Bob MORANE   [ops,staff]   {"accessProfile":"p24x7"}   [bob@mycompany.com]   ldap
Detail:
PROVIDER   STATUS            UID   NAME         GROUPS    CLAIMS                      EMAILS
ldap       passwordChecked   -     Bob MORANE   [staff]   {}                          [bob@mycompany.com]
ucrd       userNotFound      -                  [ops]     {"accessProfile":"p24x7"}   []
```

This shows that:

- User authenticated via LDAP
- Groups include `staff` from LDAP and `ops` from local CRD
- Claims `accessProfile` comes from local Group definition

### Understanding the Detail Output

The detail view shows:

1. **Summary line** - Overall authentication result after merging all providers
2. **Per-provider breakdown** - What each identity provider contributed:
   - **STATUS** - Provider's authentication result
   - **Attributes** - What information each provider supplied

This helps understand:
- Which provider authenticated the user
- How identity information is merged
- Where specific claims originate

## Data Source

Audit data is stored as Kubernetes `LoginAttempt` resources:

``` { .bash .copy }
kubectl -n kubauth-audit get loginattempts
```

**Output:**
```
NAME                           LOGIN   NAME       STATUS            AUTHORITY   AGE
jim-2025-10-27-11-22-31-017    jim                passwordChecked               3h41m
john-2025-10-27-11-58-29-588   john    John DOE   passwordChecked               3h5m
john-2025-10-27-14-34-59-923   john    John DOE   passwordChecked               28m
```

### Retention

Login attempts are automatically cleaned up based on Kubauth configuration, from helm chart:

```yaml
audit:
  cleaner:
    recordLifetime: "8h"    # Default: keep for 8 hours
    cleanupPeriod: "5m"     # Default: clean every 5 minutes
```

See [Audit Configuration](../30-user-guide/130-audit.md#configuration) for details.

## Limitations

### Claims Display

The audit logs show only custom claims from User and Group resources, not system claims like `aud`, `iss`, `exp`, etc.

### Time Window

Audit logs are retained for a limited time (default 8 hours). For longer-term audit trails, enable Kubernetes audit logging.

### Kubectl Access Required

The `kc audit` commands query Kubernetes resources, so you need:

- kubectl configured and authenticated
- Read access to the `kubauth-audit` namespace

## Troubleshooting

### No Data Displayed

If `kc audit logins` shows no data:

1. **Check audit namespace:**
   ``` { .bash .copy }
   kubectl -n kubauth-audit get loginattempts
   ```

2. **Verify Kubauth audit module is enabled:**
   ``` { .bash .copy }
   kubectl -n kubauth get pod -l app.kubernetes.io/instance=kubauth -o jsonpath='{range .items[0].spec.containers[*]}{.name}{"\n"}{end}'
   ```

3. **Check retention settings** - Data may have been cleaned up

### Permission Denied

**Error:**
```
Error from server (Forbidden): loginattempts.kubauth.kubotal.io is forbidden: User "john" cannot list resource "loginattempts"
```

**Solution:** Grant read access to audit resources:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: audit-reader
  namespace: kubauth-audit
rules:
- apiGroups: ["kubauth.kubotal.io"]
  resources: ["loginattempts"]
  verbs: ["get", "list"]
```

## Related Commands

- [`kc token`](130-token.md) - Generate login attempts to view
- [`kc token-nui`](140-token-nui.md) - Test authentication
- [`kc whoami`](170-whoami.md) - Check current user

## See Also

- [Audit Documentation](../30-user-guide/130-audit.md)
- [Identity Merging](../30-user-guide/190-identity-merging.md)
- [Multiple Identity Providers](../30-user-guide/180-several-id-providers.md)

