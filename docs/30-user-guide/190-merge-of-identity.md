# Merge of Identity

In previous chapters, each user was defined inside a specific provider database. But Kubauth allow properties of a given user defined in two (or more) ID provider to be merged. 

This will allow, for example, to enrich a user profile from a central user repository by local (cluster wide) specific properties.

> This is specially useful if you have a READ ONLY access to your LDAP server.

## Sample setup

Here is an example manifest to exercise this capability:

> It is assumed here than Kubauth is configured with an LDAP and an local CRD user database, 
  as described in previous chapter, with Users and Groups sample dataset.
  And than `alice` and `bob` are existing user defined in the LDAP Server.

???+ abstract "ldap-addon.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: User
    metadata:
      name: alice
      namespace: kubauth-users
    spec:
      passwordHash: "$2a$12$.WUyue3xr.nKuH8Tu0q.T.WF.PKHLZ92g9ewnLoB.27CuMQIdvuza" # smith123
      name: Alice SMITH-WESSON
      claims:
        office: 312R
      emails:
        - alice@mycompany.com
        - alice.smith@mycompany.com
    
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: GroupBinding
    metadata:
      name: bob-ops
      namespace: kubauth-users
    spec:
      user: bob
      group: ops
    ```

This will:

- Create a user `alice` in the k8S CRD user storage (`ucrd`). As a duplicate of the existing one in LDAP referential. `name`, `claims` and `emails` properties are provided.
- Bind the user `bob` to the group `ops`. Note than this user does not exist in the `ucrd` provider.

Apply this manifest:

``` { .bash .copy }
kubectl apply -f ldap-addon.yaml 
```

## Logins

> To ease testing we will use the 'no User Interface' of the `kc token` tool. Remember, this will use a [specific configuration](./160-password-grant.md)

### Bob

First, log as `bob` user

``` { .bash .copy }
kc token-nui --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public --login bob --password bob123 -d
```

```
JWT Payload:
{
  "accessProfile": "p24x7",
  "aud": [
    "public"
  ],
  "auth_time": 1761830106,
  "auth_time_human": "2025-10-30 13:15:06 UTC",
  "authority": "ldap",
  "azp": "public",
  "email": "bob@mycompany.com",
  "emails": [
    "bob@mycompany.com"
  ],
  "exp": 1761833706,
  "exp_human": "2025-10-30 14:15:06 UTC",
  "groups": [
    "ops",
    "staff"
  ],
  "iat": 1761830106,
  "iat_human": "2025-10-30 13:15:06 UTC",
  "iss": "https://kubauth.ingress.kubo6.mbp",
  "jti": "39600b39-267b-4f31-9179-3f698418e85c",
  "name": "Bob MORANE",
  "rat": 1761830106,
  "rat_human": "2025-10-30 13:15:06 UTC",
  "sub": "bob"
}
```

One can check here than:

- We got a JWT token, so authentication is successful.
- We have a `autority` claim. This is added by Kubauth and is the provider name which validate the user's credentials.
- The `groups` claim is made of the concatenation of the group list of each provider. With de-duplication
- There is an `accessProfile": p24x7` claim. This is a Claim granted to all members of the group `ops` defined in the `ucrd` provider.

As it can be tricky to check from where a value is coming from, Kubauth provide a tool to lookup user details:

``` { .bash .copy }
kc audit detail bob
```
```
WHEN           LOGIN   STATUS            UID   NAME         GROUPS        CLAIMS                      EMAILS                AUTH
Thu 14:15:06   bob     passwordChecked   -     Bob MORANE   [ops,staff]   {"accessProfile":"p24x7"}   [bob@mycompany.com]   ldap
Detail:
PROVIDER   STATUS            UID   NAME         GROUPS    CLAIMS                      EMAILS
ldap       passwordChecked   -     Bob MORANE   [staff]   {}                          [bob@mycompany.com]
ucrd       userNotFound      -                  [ops]     {"accessProfile":"p24x7"}   []
```

This tool will lookup the last login for the user provided as parameter. It first display a line with the same format as the `kc audit logins` command.
Then, it display another array with, for each provider, which information is provided


### alice

Now, login as `alice` user:

``` { .bash .copy }
kc token-nui --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public --login alice --password alice123 -d
```

```
.....
JWT Payload:
{
  "aud": [
    "public"
  ],
  "auth_time": 1761834557,
  "auth_time_human": "2025-10-30 14:29:17 UTC",
  "authority": "ldap",
  "azp": "public",
  "email": "alice@mycompany.com",
  "emails": [
    "alice@mycompany.com",
    "alice.smith@mycompany.com"
  ],
  "exp": 1761838157,
  "exp_human": "2025-10-30 15:29:17 UTC",
  "groups": [
    "managers",
    "staff"
  ],
  "iat": 1761834557,
  "iat_human": "2025-10-30 14:29:17 UTC",
  "iss": "https://kubauth.ingress.kubo6.mbp",
  "jti": "76a841c2-43fa-4635-9702-55c856f75f45",
  "name": "Alice SMITH",
  "office": "312R",
  "rat": 1761834557,
  "rat_human": "2025-10-30 14:29:17 UTC",
  "sub": "alice"
}
```

We can check than:

- We are logged using credentials from the LDAP server.
- The `authority` claim is set to `ldap`.
- The claim `office: 312R` from the `ucrd` provider is present
- The `emails` claim is made of the concatenation of the emails list of each provider. With de-duplication
- The `name` claim is the one from the LDAP definition. While there is another value in the `ucrd` database, 
  the value from LDAP take precedence, as the LDAP provider is before in the list. 
  The value from CRD based definition would have been used if LDAP did not provide any value. 

You can also use `kc audit detail...` to figure out what happen:

``` { .bash .copy }
kc audit detail alice
```
```
WHEN           LOGIN   STATUS            UID   NAME          GROUPS             CLAIMS              EMAILS                                            AUTH
Thu 15:29:17   alice   passwordChecked   -     Alice SMITH   [managers,staff]   {"office":"312R"}   [alice@mycompany.com,alice.smith@mycompany.com]   ldap
Detail:
PROVIDER   STATUS            UID   NAME                 GROUPS             CLAIMS              EMAILS
ldap       passwordChecked   -     Alice SMITH          [staff,managers]   {}                  [alice@mycompany.com]
ucrd       passwordFail      -     Alice SMITH-WESSON   []                 {"office":"312R"}   [alice@mycompany.com,alice.smith@mycompany.com]
```


### alice (2)

Now, let's try to login with the password defined in the `ucrd` user database: 

``` { .bash .copy }
kc token-nui --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public --login alice --password smith123 -d
```

```
token request failed with status 400: {"error":"invalid_grant","error_description":"The provided authorization grant \
(e.g., authorization code, resource owner credentials) or refresh token is invalid, expired, revoked, \
does not match the redirection URI used in the authorization request, or was issued to another client. \
Unable to authenticate the provided username and password credentials."}
```

``` { .bash .copy }
kc audit detail alice
```
```
WHEN           LOGIN   STATUS         UID   NAME          GROUPS             CLAIMS              EMAILS                                            AUTH
Thu 16:06:32   alice   passwordFail   -     Alice SMITH   [managers,staff]   {"office":"312R"}   [alice@mycompany.com,alice.smith@mycompany.com]   ldap
Detail:
PROVIDER   STATUS            UID   NAME                 GROUPS             CLAIMS              EMAILS
ldap       passwordFail      -     Alice SMITH          [staff,managers]   {}                  [alice@mycompany.com]
ucrd       passwordChecked   -     Alice SMITH-WESSON   []                 {"office":"312R"}   [alice@mycompany.com,alice.smith@mycompany.com]
```

Although this password was validated by the `ucrd` provider, the login fail. 
This is intended behavior, as, for a user defined in a prioritized provider, we don't want a secondary one to allow a password change.

In other words, the first provider in the list which define a password for a given user will validate it. (either successfully or not).

> The providers list order is important

This also means the password definition in the k8s CR database for `alice` is useless.


### john

Now, let's try to login with `john` user.

``` { .bash .copy }
kc token-nui --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public --login john --password john123 -d
```

```
.......
JWT Payload:
{
  "accessProfile": "p24x7",
  "aud": [
    "public"
  ],
    .......
  "sub": "john"
}
```

``` { .bash .copy }
kc audit detail john
WHEN           LOGIN   STATUS            UID   NAME       GROUPS       CLAIMS                                      EMAILS                  AUTH
```
```
Thu 16:14:04   john    passwordChecked   -     John DOE   [devs,ops]   {"accessProfile":"p24x7","office":"208G"}   [johnd@mycompany.com]   ucrd
Detail:
PROVIDER   STATUS            UID   NAME       GROUPS       CLAIMS                                      EMAILS
ldap       userNotFound      -                []           {}                                          []
ucrd       passwordChecked   -     John DOE   [devs,ops]   {"accessProfile":"p24x7","office":"208G"}   [johnd@mycompany.com]
```

This time, the login is successful. This because `john` does not exists on the LDAP side, So the authentication by the `ucrd` provider is effective.

In other words, with the configuration, an administrator which have access to a Kubernetes cluster resource but no access to a central 
LDAP server will be able to create local users, but will be unable to change a global user password. 

## ID Provider configuration

### Provider properties

As stated above, provider's order is important. But there is also a way to control which kind of information each provider will add to the user profile.

Here is an extract of the values file of the Helm chart, which, by default, configure a single `ucrd` provider with default values:


???+ abstract "values.yaml"

    ``` { .yaml .copy }
    merger:
      .....
      idProviders:
        - name: ucrd
          httpConfig:
            baseURL: http://localhost:6802
          credentialAuthority: true
          groupAuthority: true
          groupPattern: "%s"
          claimAuthority: true
          claimPattern: "%s"
          nameAuthority: true
          emailAuthority: true
          critical: true
          uidOffset: 0
      ....
    ```

- **`credentialAuthority`**: Setting this attribute to 'false' will prevent this provider from authenticating any user.
- **`groupAuthority`**: Setting this attribute to false will prevent the `groups` from this provider from being added to each user.
- **`groupPattern`**: Allows you to decorate with prefix or postfix all groups provided by this provider. See the example below
- **`claimAuthority`**: Setting this attribute to false will prevent the `claims` from this provider from being added to each user.
- **`claimPattern`**: Allows you to decorate with prefix or postfix all claims provided by this provider. This apply only on first level, if the claim is itself a map.
- **`nameAuthority`**: Setting this attribute to false will prevent the name from this provider from being added to each user.
- **`emailAuthority`**: Setting this attribute to false will prevent `emails` from this provider from being added to each user.
- **`critical`**: Defines the behavior of the chain if this provider is down or out of order (e.g., LDAP server is down). 
    - If true, then all authentication will fail. 
    - If false, provider is skipped and authentication is performed as if ot was not existing.
- **`uidOffset`**: This will be added to the UID value if this provider is the authority for this user.

!!! notes

    The properties are provided in the helm chart for documentation purpose. 
    As they match built-in values, the previous snippet is equivalent to 
    
    ```
    merger:
      .....
      idProviders:
        - name: ucrd
          httpConfig:
            baseURL: http://localhost:6802
    ```



### Example

Given the following requirement:

- We want to ensure all users are referenced in a central, corporate repository. (No local users anymore)
- We still want to be able to enrich users with local attributes (Groups binding, claims, ...)
- We want to identify all groups which where issued from LDAP.

So:

- First point means must prevent local user authentication.
- Second point means we still need a `ucrd` K8S CR database to be effective.
- Third point will be solved by adding a prefix to the groups provided through LDAP.

This can be achieved by modifying the `merger` configuration in the Helm values file:

???+ abstract "values-merger.yaml"

    ``` { .yaml .copy }
    
    .....
    
    merger:
      enabled: true
      idProviders:
        - name: ldap
          groupPattern: "ldap-%s"
          httpConfig:
            baseURL: http://localhost:6803 # ldap provider listening port
        - name: ucrd
          credentialAuthority: false
          httpConfig:
            baseURL: http://localhost:6802 # ucrd provider listening port
    .....
    ```

After using an Helm update

``` { .bash .copy }
helm -n kubauth upgrade -i kubauth --values ./values-merger.yaml oci://quay.io/kubauth/charts/kubauth --version 0.1.2-snapshot --create-namespace --wait
```

we can now check than:

- Users `jim` and `john` seems now unexisting.
    ``` { .bash .copy }
    kc token-nui --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public --login john --password john123 -d
    ```
    ```
    token request failed with status 400: {"error":"invalid_grant", ......... Unable to authenticate the provided username and password credentials."}
    ```


- Enrichment of LDAP users attribute are still effective. And the group from LDAP has been prefixed.
    ``` { .bash .copy }
    kc token-nui --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public --login bob --password bob123 -d
    ```
    ```
    JWT Payload:
    {
      "accessProfile": "p24x7",
      ....
      "authority": "ldap",
      ......
      "groups": [
        "ops",
        "ldap-staff"
      ],
      ....
    }
    ```
  and:
    ```
    kc audit detail bob
    ```
    ```
    WHEN           LOGIN   STATUS            UID   NAME         GROUPS             CLAIMS                      EMAILS                AUTH
    Sat 10:43:42   bob     passwordChecked   -     Bob MORANE   [ldap-staff,ops]   {"accessProfile":"p24x7"}   [bob@mycompany.com]   ldap
    Detail:
    PROVIDER   STATUS            UID   NAME         GROUPS         CLAIMS                      EMAILS
    ldap       passwordChecked   -     Bob MORANE   [ldap-staff]   {}                          [bob@mycompany.com]
    ucrd       N/A               N/A                [ops]          {"accessProfile":"p24x7"}   []
    ```


!!! notes
    
    As we may use users 'jim' and 'john' later in this manuel, we suggest you bring them alive, 
    by setting back `merger.idProviders["ucrd'].credentialAuthority: true` and applying again the Helm chart.
