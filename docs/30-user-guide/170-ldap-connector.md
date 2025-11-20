# LDAP Connector

## Kubauth Architecture

If you inspect the `kubauth` pod, you will find it currently consists of 3 containers:

``` { .bash .copy }
kubectl -n kubauth get pod -l app.kubernetes.io/instance=kubauth
```
```bash
NAME                       READY   STATUS    RESTARTS   AGE
kubauth-65dbdbb447-bl4qz   3/3     Running   0          17m
```

List the containers:

``` { .bash .copy }
kubectl -n kubauth get pod -l app.kubernetes.io/instance=kubauth -o jsonpath='{range .items[0].spec.containers[*]}{.name}{"\n"}{end}'
```
```bash
oidc
audit
ucrd
```

Kubauth is built on a modular architecture. The following diagram describes the default configuration:

![containers](../assets/archi-default.png){ align=left width="40%" }

All modules communicate using the same simple identity protocol with a single exchange type:

- The Request provides a login and optionally a password
- The Response provides a status (NotFound, PasswordFail, PasswordChecked, ...) and all available user-related information (Name, Emails, Claims, ...)

All communication between modules (containers) uses `localhost`, keeping it private and not exposed outside the pod.

Each module (container) listens on a specific port:

- The `oidc` module handles all user interaction and initiates identity requests
- The `audit` module is a transparent pass-through for the protocol, logging all requests to provide the audit feature described previously
- The `ucrd` module accesses the User, Group, and GroupBinding Custom Resources to build the response

All these modules are built into the kubauth image. Assembly is performed by the Helm chart.


![](../assets/empty.png){width="100%"}


There is another built-in module: `ldap`, which implements the identity protocol by connecting to an external LDAP server.

Here is the new configuration:

![containers](../assets/archi-ldap.png){ align=left width="40%" }

To switch to this configuration, you must:

- Disable the `ucrd` module
- Enable the `ldap` module
- Configure the `audit` module to request the `ldap` module (listening on port 6803) instead of `ucrd` (which listened on port 6802)
- Configure the `ldap` module for your target LDAP server

![](../assets/empty.png){width="100%"}

The `values-ldap.yaml` file below implements this configuration.

The LDAP configuration itself is tailored for an OpenLDAP server deployed as described in [Appendix/OpenLDAP Deployment](../80-appendix/100-openldap.md).

???+ abstract "values-ldap.yaml"

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
        baseURL: http://localhost:6803  # ldap provider listening port
    
    ucrd:
      enabled: false
    
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

## LDAP Configuration

If you need to configure a different type of LDAP server, each property is documented in the Helm chart values file. For convenience, the relevant extract is provided below:


???- abstract "values-ldap-commented.yaml"

    ``` { .yaml .copy }
    .......
    ldap:
      enabled: true
      ldap:
        # The host and port of the LDAP server.
        host:
        #  If port isn't supplied, it will be guessed based on the TLS configuration. (389 or 636).
        port:
    
        # Timeout on connection to ldap server. Default to 10
        timeoutSec:
        # Required if LDAP host does not use TLS.
        insecureNoSSL:
        # Don't verify the CA.
        insecureSkipVerify:
        # Connect to the insecure port then issue a StartTLS command to negotiate a
        # secure connection. If unsupplied secure connections will use the LDAPS protocol.
        startTLS:
    
        # Only one of rootCaData, rootCaPath or rootCaSecret must be defined
        # Path to a trusted root certificate file.
        rootCaPath:
        # Base64 encoded PEM data containing root CAs.
        rootCaData:
        # A secret hosting the CA, as base64 encoded value, at the 'rootCaSecretPath' location.
        # The secret can be generated using trust-manager from cert-manager
        rootCaSecret:
        rootCaSecretPath:  # Default to 'ca.crt'
    
        # Path to a client cert file. If LDAP server require a certificate based client authentication
        clientCert:
        # Path to a client private key file. If LDAP server require a certificate based client authentication
        clientKey:
    
        # BindDN and BindPW for an application service account. The connector uses these
        # credentials to search for users and groups.
        bindDN:
        bindPW:
    
        groupSearch:
          # BaseDN to start the search from. For example "cn=groups,dc=example,dc=com"
          baseDN:
          # Optional filter to apply when searching the directory. For example "(objectClass=posixGroup)"
          filter:
          # The filter for group/user relationship will be: (<linkGroupAttr>=<Value of LinkUserAttr for the user>)
          # If there is several value for LinkUserAttr, we will loop on.
          linkGroupAttr:
          linkUserAttr:
          # The attribute of the group that represents its name.
          nameAttr:
          # Defaults to "sub"
          scope:
        userSearch:
          # BaseDN to start the search from. For example "cn=users,dc=example,dc=com"
          baseDN:
          #  Optional filter to apply when searching the directory. For example "(objectClass=person)"
          filter:
          # Attribute to match against the login. This will be translated and combined with the other filter as "(<loginAttr>=<login>)".
          loginAttr:
          # Can either be:
          #	  "sub" - search the whole sub tree
          #	  "one" - only search one level
          scope:
          # The attribute providing the numerical user ID
          numericalIdAttr:
          # The attribute providing the user's email
          emailAttr:
          # The attribute providing the user's common name
          cnAttr:
    ```

## Deployment

Once your configuration is ready, proceed with deployment by running the `helm upgrade ...` command:

``` { .bash .copy }
helm -n kubauth upgrade -i kubauth --values ./values-ldap.yaml oci://quay.io/kubauth/charts/kubauth --version 0.1.2-snapshot --create-namespace --wait
```

Verify which containers have been deployed:

``` { .bash .copy }
kubectl -n kubauth get pod -l app.kubernetes.io/instance=kubauth -o jsonpath='{range .items[0].spec.containers[*]}{.name}{"\n"}{end}'
```
```bash
oidc
audit
ldap
```

Test authentication:


``` { .bash .copy }
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public -d
```
```bash
If browser doesn't open automatically, visit: http://127.0.0.1:9921
```

If you enter `jim/jim123`, the login will fail.

However, if you enter credentials for a user defined in your LDAP server, the login should succeed. For example, using `fred/fred123` (if using the sample LDAP configuration defined in the [appendix](../80-appendix/100-openldap.md#sample-dataset)):


```bash
Access token: ory_at_2vDnbRl0-cazsy2ZkIV_3bG8blZzgA5Cc0FxKXg5g6g.IvAqwgU04BnmBBoO_IPNt3UtIkiAWfJlgcj5WyMPsPk
Refresh token: ory_rt_UQQoBvf3Pkk1Yr6W3JCO_aShfX_28e8tAnxcMUQGjJE.I-P_3XJxVwPRmrUDVOXtt0ofS_G2MISSVRMoL48ZIAg
ID token: eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0Y2NkNDU0LWYzYTgtNDQ3Zi1hN2MzLTY3ZmY5MzUxMzZiMSIsInR5cCI6IkpXVCJ9.eyJhdF9oYXNoIjoiM0RMYWZJMzdNZnNGZjVWOUN6QU1hUSIsImF1ZCI6WyJwdWJsaWMiXSwiYXV0aF90aW1lIjoxNzYxNjc0MzU2LCJhenAiOiJwdWJsaWMiLCJlbWFpbCI6ImZyZWRAbXljb21wYW55LmNvbSIsImVtYWlscyI6WyJmcmVkQG15Y29tcGFueS5jb20iXSwiZXhwIjoxNzYxNjc3OTU2LCJncm91cHMiOlsibWFuYWdlcnMiLCJzdGFmZiJdLCJpYXQiOjE3NjE2NzQzNTYsImlzcyI6Imh0dHBzOi8va3ViYXV0aC5pbmdyZXNzLmt1Ym82Lm1icCIsImp0aSI6IjE3YjQxMzk1LTU4MmUtNDM3ZC05YTA2LWNkYWY5NjM1NjdjZiIsIm5hbWUiOiJGcmVkIEFTVEVSIiwicmF0IjoxNzYxNjc0MzU2LCJzdWIiOiJmcmVkIn0.ZSnv4godrQOkrYNaEteOi85N-M9b4UKOI8zj0sorrD5Az1_xezINWiSRkrN2vLq9DtMKXZUBNjr41m4dW83xTsex8Tq_lEtisJP8woZzXzUpv1HnK2_RJiX_euGM2RSUJNaih4vpeDOPBhZQPUTkCIqnH_kus2dLuh84KGmcpLFC7vG60JW1lqRlx1Wb5ggmZmSFHC6k44Lx0bkihhpofiJg0QL1UoxmN1elixOegxOs0g_vxjdoDC3jNVOWONR6qVpvG7YRa25FgNPvfIV1XWeIP9upq0Yn_LNxLXuNFY_ysdw4lIQH2aEO58118KwB5eB8UQRnZJXmnAyKF-OU5Q
Expire in: 1h0m0s
JWT Payload:
{
  "at_hash": "3DLafI37MfsFf5V9CzAMaQ",
  "aud": [
    "public"
  ],
  "auth_time": 1761674356,
  "auth_time_human": "2025-10-28 17:59:16 UTC",
  "azp": "public",
  "email": "fred@mycompany.com",
  "emails": [
    "fred@mycompany.com"
  ],
  "exp": 1761677956,
  "exp_human": "2025-10-28 18:59:16 UTC",
  "groups": [
    "managers",
    "staff"
  ],
  "iat": 1761674356,
  "iat_human": "2025-10-28 17:59:16 UTC",
  "iss": "https://kubauth.ingress.kubo6.mbp",
  "jti": "17b41395-582e-437d-9a06-cdaf963567cf",
  "name": "Fred ASTER",
  "rat": 1761674356,
  "rat_human": "2025-10-28 17:59:16 UTC",
  "sub": "fred"
}
```

Check the audit trail:

``` { .bash .copy }
kc audit logins
```
```
WHEN           LOGIN   STATUS            UID   NAME         GROUPS             CLAIMS                                      EMAILS                  AUTH
Tue 18:59:16   fred    passwordChecked   -     Fred ASTER   [staff,managers]   {}                                          [fred@mycompany.com]    
Tue 19:02:20   jim     userNotFound      -                  []                 {}                                          []                    
```
