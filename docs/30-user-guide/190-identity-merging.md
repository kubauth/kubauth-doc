# Identity Merging

In previous chapters, each user was defined within a specific provider database. However, Kubauth allows properties of a user defined in two (or more) identity providers to be merged.

This enables you to, for example, enrich a user profile from a central repository with local (cluster-specific) properties.

> This is especially useful if you have read-only access to your LDAP server.

## Sample Setup

Here is an example manifest to demonstrate this capability:

> This assumes Kubauth is configured with both LDAP and local CRD user databases as described in the previous chapter, with Users and Groups sample datasets, and that `alice` and `bob` are existing users defined in the LDAP server.

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

- Create a user `alice` in the Kubernetes CRD user storage (`ucrd`), duplicating the one in the LDAP directory. The `name`, `claims`, and `emails` properties are provided.
- Bind the user `bob` to the group `ops`. Note that this user does not exist in the `ucrd` provider.

Apply this manifest:

``` { .bash .copy }
kubectl apply -f ldap-addon.yaml 
```

## Logins

> To simplify testing, we will use the 'no User Interface' mode of the `kc token` tool. Remember, this requires [specific configuration](./160-password-grant.md).

### Bob

First, log in as the `bob` user:

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

You can verify that:

- We received a JWT token, so authentication was successful.
- There is an `authority` claim. This is added by Kubauth and indicates which provider validated the user's credentials.
- The `groups` claim is the concatenation of the group lists from each provider, with de-duplication.
- There is an `accessProfile: p24x7` claim. This is a claim granted to all members of the `ops` group defined in the `ucrd` provider.

Since it can be difficult to determine where each value originates, Kubauth provides a tool to look up user details:

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

This tool looks up the last login for the specified user. It first displays a line in the same format as the `kc audit logins` command. Then it displays a table showing what information each provider contributed.


### alice

Now, log in as the `alice` user:

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

We can verify that:

- We are logged in using credentials from the LDAP server.
- The `authority` claim is set to `ldap`.
- The `office: 312R` claim from the `ucrd` provider is present.
- The `emails` claim is the concatenation of the email lists from each provider, with de-duplication.
- The `name` claim is from the LDAP definition. While there is a different value in the `ucrd` database, the LDAP value takes precedence because the LDAP provider is listed first. The CRD value would be used if LDAP did not provide a value.

You can also use `kc audit detail ...` to understand what happened:

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

Now, let's try to log in with the password defined in the `ucrd` user database:

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

Although the password was validated by the `ucrd` provider, the login failed. This is intentional behavior: for a user defined in a higher-priority provider, we don't want a secondary provider to allow password changes.

In other words, the first provider in the list that defines a password for a given user will validate it (either successfully or not).

!!! note
    
    This is why **the provider list order is important**.

This also means the password definition in the Kubernetes CR database for `alice` is unused.


### john

Now, let's try to log in with the `john` user:

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
```
```
WHEN           LOGIN   STATUS            UID   NAME       GROUPS       CLAIMS                                      EMAILS                  AUTH
Thu 16:14:04   john    passwordChecked   -     John DOE   [devs,ops]   {"accessProfile":"p24x7","office":"208G"}   [johnd@mycompany.com]   ucrd
Detail:
PROVIDER   STATUS            UID   NAME       GROUPS       CLAIMS                                      EMAILS
ldap       userNotFound      -                []           {}                                          []
ucrd       passwordChecked   -     John DOE   [devs,ops]   {"accessProfile":"p24x7","office":"208G"}   [johnd@mycompany.com]
```

This time, the login is successful. This is because `john` does not exist in LDAP, so authentication by the `ucrd` provider is effective.

In other words, with this configuration, an administrator who has access to Kubernetes cluster resources but no access to the central LDAP server will be able to create local users, but will be unable to change a global user's password.

## Identity Provider Configuration

### Provider Properties

As stated above, provider order is important. However, you can also control what type of information each provider contributes to the user profile.

Here is an extract from the Helm chart values file, which by default configures a single `ucrd` provider with default values:


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

- **`credentialAuthority`**: Setting this to `false` prevents this provider from authenticating any user.
- **`groupAuthority`**: Setting this to `false` prevents groups from this provider from being added to user profiles.
- **`groupPattern`**: Allows you to decorate all groups from this provider with a prefix or suffix. See the example below.
- **`claimAuthority`**: Setting this to `false` prevents claims from this provider from being added to user profiles.
- **`claimPattern`**: Allows you to decorate all claims from this provider with a prefix or suffix. This applies only to the first level if the claim is itself a map.
- **`nameAuthority`**: Setting this to `false` prevents the name from this provider from being added to user profiles.
- **`emailAuthority`**: Setting this to `false` prevents emails from this provider from being added to user profiles.
- **`critical`**: Defines behavior if this provider is down or unavailable (e.g., LDAP server is down).
    - If `true`, all authentication will fail.
    - If `false`, the provider is skipped and authentication proceeds as if it didn't exist.
- **`uidOffset`**: This value is added to the UID if this provider is the authority for the user.

!!! note

    These properties are provided in the Helm chart for documentation purposes. Since they match built-in defaults, the previous snippet is equivalent to:
    
    ``` { .yaml .copy }
    merger:
      .....
      idProviders:
        - name: ucrd
          httpConfig:
            baseURL: http://localhost:6802
    ```



### Example

Given the following requirements:

- We want to ensure all users are referenced in a central, corporate repository (no local users)
- We still want to enrich users with local attributes (group bindings, claims, ...)
- We want to identify all groups issued from LDAP

Therefore:

- The first requirement means we must prevent local user authentication
- The second requirement means we still need a `ucrd` Kubernetes CR database to be active
- The third requirement will be solved by adding a prefix to groups provided through LDAP

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

After applying the Helm update:

``` { .bash .copy }
helm -n kubauth upgrade -i kubauth --values ./values-merger.yaml oci://quay.io/kubauth/charts/kubauth --version 0.1.2-snapshot --create-namespace --wait
```

we can now verify that:

- Users `jim` and `john` now appear to be non-existent:
    ``` { .bash .copy }
    kc token-nui --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public --login john --password john123 -d
    ```
    ```
    token request failed with status 400: {"error":"invalid_grant", ......... Unable to authenticate the provided username and password credentials."}
    ```


- Enrichment of LDAP user attributes is still effective, and groups from LDAP have been prefixed:
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


!!! note
    
    Since we may use the `jim` and `john` users later in this manual, we recommend restoring them by setting `merger.idProviders["ucrd"].credentialAuthority: true` and reapplying the Helm chart.
