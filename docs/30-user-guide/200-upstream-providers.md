# Upstream Providers

So far, every user authenticated by Kubauth was either defined locally (`User` Custom Resources) or fetched from an LDAP directory through the built-in `ldap` connector.

Starting with version 0.3.0, Kubauth can also delegate authentication to one or more **external OIDC providers** — for example a corporate Keycloak, Okta, Google Workspace or Microsoft Entra ID realm. Each external provider is declared as a Kubernetes Custom Resource named `UpstreamProvider.kubauth.kubotal.io`.

> Do not confuse `UpstreamProvider` with the `merger` chapter. The merger combines several **internal** providers (`ucrd`, `ldap`) over a private HTTP protocol. Upstream providers are **external OIDC servers** that Kubauth talks to using the standard authorization-code flow.

## Concepts

When at least one `UpstreamProvider` is defined, the Kubauth login page becomes a **provider chooser**:

- For every active OIDC provider, a button is displayed (`Sign in with ...`).
- The internal login form (login/password) is shown only when an `internal` provider exists.
- If a single non-internal provider is configured (and no internal one), the user is redirected straight to it, bypassing the login page.
- Upon a successful upstream login, Kubauth receives the upstream ID token, applies renamings and removals, optionally enriches the resulting claims from the local user database, and finally issues its own ID/access/refresh tokens to the OIDC client application.

When no `UpstreamProvider` resource exists at all, Kubauth falls back to its historical behavior and automatically presents a single `internal` provider that authenticates users via the configured `idProvider` chain (`ucrd`, `ldap`, …).

## Where Upstream Providers Live

By default, `UpstreamProvider` resources must be created in the Kubauth release namespace. The controller only watches a single namespace, which can be customized with the Helm value `oidc.upstreamProviderNamespace`:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      ....
      upstreamProviderNamespace: kubauth-upstreams
    ```

## A Minimal Example

The following manifest declares a single upstream provider pointing at a Keycloak realm.

???+ abstract "upstream-keycloak.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: upstream-keycloak
      namespace: kubauth
    type: Opaque
    stringData:
      clientSecret: aGoodSecret
    
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: UpstreamProvider
    metadata:
      name: keycloak
      namespace: kubauth
    spec:
      type: oidc
      displayName: "Sign in with Keycloak"
      issuerURL: "https://keycloak.mycompany.com/realms/default"
      redirectURL: "https://kubauth.mycluster.mycompany.com/upstream/callback"
      clientId: kubauth-downstream
      clientSecret:
        name: upstream-keycloak
        key: clientSecret
      scopes:
        - openid
        - profile
        - groups
        - email
    ```

Apply the manifest:

``` { .bash .copy }
kubectl apply -f upstream-keycloak.yaml
```

And check the resulting status:

``` { .bash .copy }
kubectl -n kubauth get upstreamproviders
```

```
NAME       TYPE   DISPLAY_NAME            STATUS   MESSAGE   CLIENT_ID            ISSUER_URL                                          REDIRECT_URL
keycloak   oidc   Sign in with Keycloak   READY    OK        kubauth-downstream   https://keycloak.mycompany.com/realms/default       https://kubauth.mycluster.mycompany.com/upstream/callback
```

!!! note

    `upstreamprovider` also accepts the short alias `upstreams`:
    ``` { .bash .copy }
    kubectl -n kubauth get upstreams
    ```

### Counterpart on the External IdP

The settings above assume that you already declared an OIDC client in the upstream provider with:

- The same `client_id` and `clientSecret`.
- A redirect URI matching `https://<kubauth-host>/upstream/callback`.
- At least the `openid` scope enabled (plus any other scope you intend to forward).

## The Welcome Page (SSO `onDemand`)

When the global SSO mode is `onDemand` (see the [SSO Session](140-sso.md) chapter), users coming back from an upstream provider are presented with a small welcome page:

> *"Welcome, John DOE. Remember me on this device?"*

If the box is checked, an SSO session is created and subsequent logins from any OIDC client of this Kubauth instance will be performed silently. If it is left unchecked, the user is logged in only for the current OIDC flow.

In `always` mode the SSO session is created automatically, and in `never` mode no session is ever created — the welcome page is skipped in both cases.

## Internal Provider

In some scenarios you may want both an external IdP *and* the historical login form for break-glass accounts. This is achieved by declaring an explicit `internal` upstream provider:

???+ abstract "upstream-internal.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: UpstreamProvider
    metadata:
      name: internal
      namespace: kubauth
    spec:
      type: internal
      displayName: "Local administrators"
    ```

The login page will then display both the local form (with the label *"Local administrators"*) and a *"Sign in with Keycloak"* button.

The displayed label for the internal form can also be tuned globally through the Helm chart, when no explicit `internal` provider is declared:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      ....
      defaultLoginLabel: "Welcome"
    ```

## Client-Specific Providers

A provider can be hidden from the default login page and reserved for the OidcClients that explicitly request it:

???+ abstract "upstream-partner.yaml"

    ``` { .yaml .copy }
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: UpstreamProvider
    metadata:
      name: partner
      namespace: kubauth
    spec:
      type: oidc
      displayName: "Sign in with Partner SSO"
      clientSpecific: true
      issuerURL: "https://idp.partner.com"
      ....
    ```

A client willing to expose this provider must reference it through `spec.upstreamProviders` (see [OIDC Clients Configuration / Upstream Providers](115-oidc-clients-configuration.md#upstream-providers)).

## Claim Transformations

External providers rarely emit exactly the claims expected by Kubauth or by downstream applications. Two transformation steps can be applied per provider:

### Renaming and Copying

`claimRenamings` rewrites claim names before merging:

???+ abstract "claim-renamings.yaml"

    ``` { .yaml .copy }
    spec:
      claimRenamings:
        - oldName: preferred_username
          newName: sub
          operation: copy        # rename | copy
        - oldName: realm_roles
          newName: roles
          operation: rename      # this is the default
    ```

- `rename` replaces `oldName` with `newName` (the original key disappears).
- `copy` keeps the original key and adds a copy under `newName`. This is useful for example to derive a stable `sub` claim from `preferred_username` while leaving the original claim in place.

### Removals

`claimRemovals` strips a list of claims from the resulting set:

???+ abstract "claim-removals.yaml"

    ``` { .yaml .copy }
    spec:
      claimRemovals:
        - email_verified
        - session_state
    ```

In addition, Kubauth always removes the "technical" OIDC ID-Token claims (`iss`, `aud`, `exp`, `iat`, `auth_time`, `nonce`, `acr`, `amr`, `azp`, `at_hash`, `c_hash`) from the upstream payload before merging. The `sub` claim is preserved as the user identifier.

## Local Enrichment

When `localEnrichment: true` (the default), Kubauth tries to match the upstream `sub` claim against a local `User` resource and merges any extra information found there (groups, emails, claims, …).

This is the recommended way to keep central authentication while still managing cluster-specific groups and claims in Kubernetes.

To disable enrichment for a specific provider:

???+ abstract "upstream-no-enrichment.yaml"

    ``` { .yaml .copy }
    spec:
      localEnrichment: false
    ```

## Using the UserInfo Endpoint

Some upstream providers (notably Keycloak) put a richer set of claims in their UserInfo endpoint than in the ID token itself. Setting `useUserInfo: true` instructs Kubauth to call the UserInfo endpoint after the token exchange and merge the returned claims:

???+ abstract "upstream-keycloak-userinfo.yaml"

    ``` { .yaml .copy }
    spec:
      useUserInfo: true
    ```

## TLS to the Upstream

When the upstream issuer uses a private PKI, provide the CA bundle via a ConfigMap or Secret in the same namespace as the UpstreamProvider:

???+ abstract "upstream-keycloak-ca.yaml"

    ``` { .yaml .copy }
    spec:
      certificateAuthority:
        secret:
          name: certs-bundle
          key: ca.crt
    ```

For development environments only, you can also disable TLS verification:

???+ abstract "upstream-insecure.yaml"

    ``` { .yaml .copy }
    spec:
      insecureSkipVerify: true
    ```

## Helm Companion Chart

A separate Helm chart, `kubauth-upstream-providers`, packages the resources above so they can be deployed alongside the main Kubauth chart. A typical values file looks like:

???+ abstract "values-upstream.yaml"

    ``` { .yaml .copy }
    upstreamProviders:
      - name: internal
        enabled: true
        type: internal
        displayName: "Login on this cluster"
    
      - name: keycloak
        enabled: true
        type: oidc
        displayName: "Sign in on keycloak"
        issuerURL: "https://keycloak.mycompany.com/realms/default"
        certificateAuthority:
          secret:
            name: certs-bundle
            key: ca.crt
        redirectURL: "https://kubauth.mycluster.mycompany.com/upstream/callback"
        clientId: kubauth-downstream
        clientSecret: aGoodSecret
        scopes:
          - openid
          - profile
          - groups
        useUserInfo: false
        claimRenamings:
          - oldName: preferred_username
            newName: sub
            operation: copy
        claimRemovals:
          - email_verified
        localEnrichment: true
    ```

Deploy it with:

``` { .bash .copy }
helm -n kubauth upgrade -i kubauth-upstream-providers \
    --values ./values-upstream.yaml \
    oci://quay.io/kubauth/charts/kubauth-upstream-providers \
    --version 0.3.0 \
    --wait
```

The chart creates the necessary Kubernetes Secret(s) when `clientSecret` is provided inline, or reuses an existing one when `clientSecretRef` is used.

## Disabling an Upstream

As with OidcClients, the `enabled` field allows you to temporarily switch a provider off without removing the resource:

???+ abstract "upstream-disabled.yaml"

    ``` { .yaml .copy }
    spec:
      enabled: false
      ....
    ```

A disabled provider does not appear on the login page and is reported with the status `OFF`.

## Troubleshooting

For ad-hoc debugging of the upstream protocol, enable verbose dump on a single provider:

???+ abstract "upstream-debug.yaml"

    ``` { .yaml .copy }
    spec:
      dumpExchanges: true
    ```

All HTTP exchanges between Kubauth and the upstream IdP will then be logged. Remember to disable this flag in production.

To trace how claims are merged, enable the global flag:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      ....
      dumpUpstreamClaims: true
    ```

The full claim merge pipeline (upstream payload, renamings, removals, local enrichment) will be dumped to the controller logs.
