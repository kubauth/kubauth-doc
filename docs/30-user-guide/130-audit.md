# Audit

Kubauth records all login attempts. You can display them using the following `kc` subcommand:

``` { .bash .copy }
kc audit logins
```

```
WHEN           LOGIN   STATUS            UID   NAME       GROUPS   CLAIMS              EMAILS                  AUTH
Mon 12:22:31   jim     passwordChecked   -                []       {}                  []                      
Mon 12:58:29   john    passwordChecked   -     John DOE   []       {"office":"208G"}   [johnd@mycompany.com]   
Mon 15:34:59   john    passwordChecked   -     John DOE   []       {"office":"208G"}   [johnd@mycompany.com]   
```

!!! note

    The claims stored in audit records are only those defined in the User Custom Resource.

Each attempt is stored as a Kubernetes resource `LoginAttempt.kubauth.kubotal.io` in the `kubauth-audit` namespace:

``` { .bash .copy }
kubectl -n kubauth-audit get loginattempts
```

```bash
NAME                           LOGIN   NAME       STATUS            AUTHORITY   AGE
jim-2025-10-27-11-22-31-017    jim                passwordChecked               3h41m
john-2025-10-27-11-58-29-588   john    John DOE   passwordChecked               3h5m
john-2025-10-27-14-34-59-923   john    John DOE   passwordChecked               28m
```

## Configuration

The audit history is cleaned every 5 minutes by removing all records older than 8 hours. This can be modified using Helm chart configuration:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      issuer: https://kubauth.ingress.kubo6.mbp
      postLogoutURL: https://kubauth.ingress.kubo6.mbp/index
      ...
    audit:
      namespace: kubauth-audit
      createNamespace: true
      cleaner:
        recordLifetime: "8h"
        cleanupPeriod: "5m"
    ```
