# Introduction

This chapter describe how to integrate Kubauth OIDC server to the Kubernetes Authentication system and RBAC.

Aim is to authenticate users interacting with the cluster through tools like `kubectl`.

There will be several parts on this topic

- We first need to register Kubernetes as an OIDC client application. This is performed right below.

- We need to configure the Kubernetes API server to interact with Kubauth. This configuration can be performed manually, but a tool to fully automate this configuration is provided. 

- A service is deployed on the cluster to publish configuration parameters for users.

- Each user will need to perform a local configuration on its workstation. Here also, a tool is provided to automate this.

## Oidc client creation

From OIDC server point of view, Kubernetes is perceived as a Client application, and must be defined as such. 
As stated in [Configuration](../30-user-guide/110-configuration.md/#oidc-client-creation), a client application is defined as a Kubernetes Custom Resource.

So, a manifest like the following should be created:

???+ abstract "client-k8s.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: k8s
      namespace: kubauth-oidc
    spec:
      hashedSecret: "$2a$12$Aq5uKhYmMBZ3GDKykgSrT.0Rq1.s81VBwHgQP/cozdP3SBkQAbxv2"
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
    ``` 

- The sample password is 'k8s123'. Thus, the `hashedSecret` value is the result of a <br>`kc hash k8s123` command. 
> The Client can also be defined as `public`.
- As client application will be the kubectl/kubelogin running on user's workstation, `redirectURIs` refers to `localhost`.


Apply this manifest:

``` { .bash .copy }
kubectl apply -f client-k8s.yaml
```

You can now move on to the API Server configuration