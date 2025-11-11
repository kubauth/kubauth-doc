# Several ID Providers

In previous chapter, we substitute our local user database by an external LDAP server. But what if we want to have both.

## Configuration

Kubauth provide another built-in module: the `merger`. 

Here is our target architecture:

![containers](../assets/archi-merge.png){ .center width="60%" }

And here is a `values file` to implement it:

???+ abstract "values-merger.yaml"

    ``` { .yaml .copy }
    oidc:
      issuer: https://kubauth.ingress.kubo6.mbp
      postLogoutURL: https://kubauth.ingress.kubo6.mbp/index
      allowPasswordGrant: true
    
      ingress:
        host: kubauth.ingress.kubo6.mbp
    
      server:
        certificateIssuer: cluster-odp
    
    audit:
      idProvider:
        baseURL: http://localhost:6804 # Merger listening port
    
    merger:
      enabled: true
      idProviders:
        - name: ldap
          httpConfig:
            baseURL: http://localhost:6803 # ldap provider listening port
        - name: ucrd
          httpConfig:
            baseURL: http://localhost:6802 # ucrd provider listening port
    
    ucrd:
      enabled: true
    
    ldap:
      enabled: true
      ldap:
        host: openldap.openldap.svc
        insecureNoSSL: true
        bindDN: cn=admin,dc=mycompany,dc=com
        bindPW: admin123
        timeoutSec: 10
        groupSearch:
          baseDN: ou=Groups,dc=mycompany,dc=com
          filter: (objectClass=posixgroup)
          linkGroupAttr: memberUid
          linkUserAttr: uid
          nameAttr: cn
        userSearch:
          baseDN: ou=Users,dc=mycompany,dc=com
          cnAttr: cn
          emailAttr: mail
          filter: (objectClass=inetOrgPerson)
          loginAttr: uid
          numericalIdAttr: uidNumber
    ```

- The `audit` module is now connected to the `merger` module.
- This `merger` module is configured with a list of two ID provider. We will see in next chapter than order is important.
- The `ucrd` module is enabled.
- The `ldap` module configuration os the same as in previous chapter.

One your configuration is ready, you can proceed with its deployment, by launching an `helm update ....` command:

``` { .bash .copy }
helm -n kubauth upgrade -i kubauth --values ./values-merger.yaml oci://quay.io/kubauth/charts/kubauth --version 0.1.2-snapshot --create-namespace --wait
```

And you can check which containers has now been deployed:

``` { .bash .copy }
kubectl -n kubauth get pod -l app.kubernetes.io/instance=kubauth -o jsonpath='{range .items[0].spec.containers[*]}{.name}{"\n"}{end}'
```
```bash
oidc
audit
merger
ucrd
ldap
```

If you have followed this manual, the `ucrd` module has been previously removed. So all its content is gone. You must restore it:

``` { .bash .copy }
kubectl apply -f users.yaml
kubectl apply -f group1.yaml
kubectl apply -f group2.yaml 
```

## Logins

And you can now test authentication:


``` { .bash .copy }
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public -d
```

Launch this command twice, one with `bob/bob123` and another with `john/john123`

You can check with the result both user's claims are properly populated.


## Audit

If you issue some login command:

``` { .bash .copy }
kc audit logins
```
```
WHEN           LOGIN   STATUS            UID   NAME         GROUPS       CLAIMS                                      EMAILS                  AUTH
Thu 12:14:32   bob     passwordChecked   -     Bob MORANE   [staff]      {}                                          [bob@mycompany.com]     ldap
Thu 12:14:18   john    passwordChecked   -     John DOE     [devs,ops]   {"accessProfile":"p24x7","office":"208G"}   [johnd@mycompany.com]   ucrd
```

You can see the rightmost column `AUTH` for AUTHORITY with is now fulfilled with the name of the ID Provider which validate the password. 
