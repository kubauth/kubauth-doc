# Overview

This chapter describes how to integrate the Kubauth OIDC server with the Kubernetes authentication system and RBAC.

The goal is to authenticate users interacting with the cluster through tools like `kubectl`.

This integration consists of several parts:

- First, we need to register Kubernetes as an OIDC client application. This is covered immediately below.

- We need to configure the Kubernetes API server to interact with Kubauth. This configuration can be performed manually, but a tool to fully automate the process is provided.

- A service is deployed on the cluster to publish configuration parameters for users.

- Each user needs to perform local configuration on their workstation. Here also, a tool is provided to automate this process.

## OIDC Client Creation

From the OIDC server's perspective, Kubernetes is perceived as a client application and must be defined as such. As described in [Configuration](../30-user-guide/110-configuration.md/#oidc-client-creation), an OIDC client application is defined as a Kubernetes Custom Resource.

Create a manifest like the following:

???+ abstract "client-k8s.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: k8s-oidc-client-secret
      namespace: kubauth
    type: Opaque
    stringData:
      clientSecret: "k8s123"
    
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: k8s
      namespace: kubauth
    spec:
      description: For kubernetes kubectl access
      grantTypes: ["refresh_token", "authorization_code", "password"]
      redirectURIs:
        - http://localhost:8000
        - http://localhost:18000
      responseTypes: [ "id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token" ]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access" ]
      accessTokenLifespan: 1m0s
      idTokenLifespan: 1m0s
      refreshTokenLifespan: 30m0s
      secrets:
        - name: k8s-oidc-client-secret
          key: clientSecret
    ```


- We set a `client_secret`, but client can also be defined as `public`. 
  > This secret will be stored in plain text in the local user's kubeconfig file.
- Since the client application will be kubectl/kubelogin running on the user's workstation, `redirectURIs` refers to `localhost`.


Apply this manifest:

``` { .bash .copy }
kubectl apply -f client-k8s.yaml
```

You can now proceed to the API Server configuration.
