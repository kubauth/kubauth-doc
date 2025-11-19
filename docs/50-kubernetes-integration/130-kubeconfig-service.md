
# Kubeconfig service

## Configuration

To configure your local kubeconfig, some information are required (API server adresse, Certificate Authority, OIDC Issuer URL, ....).
Kubauth provide a service to publish these information, at the intention of a local tool which will set up the local `kubeconfig` file.

This service will be deployed with an Helm chart.
As its configuration include a bunch of parameters, create a values file like the following:

???+ abstract "values-kubeconfig.yaml"

    ``` { .yaml .copy }
    ingress:
      host: kubeconfig.ingress.kubo6.mbp
    server:
      tls: true
      certificateIssuer: cluster-odp
    networkPolicies:
      enabled: true
    kubeconfigs:
      default:
        description: Default OIDC client configuration
        cluster:
          apiServerURL: https://127.0.0.1:5452
        context:
          name: oidc-kubo6
          namespace:  # Left blank. Will allow default context for users
        oidc:
          issuerURL: https://kubauth.ingress.kubo6.mbp
          issuerCaSecretName: certs-bundle
          issuerCaName: ca.crt
          clientId: k8s
          clientSecret: k8s123
    ```

Several fields must be adjusted, depending of your context:

- `ingress.host`: The fqdn used for accessing the service from outside the cluster.
- `server.tls`: Secure communication (Recommended)
- `certificateIssuer`: The `ClusterIssuer` from your Certificate Manager for ingress certificate creation.
- `networkPolicies.enabled`: Must be set to `true` if your cluster enforce some networkPolicies. A rule will be generated to allow access to the service by the ingress controller.
- `kubeconfigs.default.cluster.apiServerURL`: The URL to access the API Server from the client workstation. Set to 127.0.0.1 in this sample, as we target a local kind cluster.
- `kubeconfigs.default.context.name`: The local name of this context. Useful if you manage several clusters.
- `kubeconfigs.default.context.namespace`: Set a specific default context on user login.
- `kubeconfigs.default.oidc.issuerURL`: Set to your Kubauth entry point
- `kubeconfigs.default.oidc.issuerCaSecretName`: A secret hosting the CA of the issuerURL. In this sample, we use [trust manager](https://cert-manager.io/docs/trust/trust-manager/){:target="_blank"}
  which create such secret (here `certs-bundle`) in each namespace.
- `kubeconfigs.default.oidc.issuerCaName`: The path of the CA certificate inside the secret.
- `kubeconfigs.default.oidc.clientId`: should match the name of the `OidcClient` declared previously.
- `kubeconfigs.default.oidc.clientSecret`: The secret defined in the `OidcClient` declared previously. Leave blank if the `OidcClient` is `public`.

## Deployment

The Helm chart can now be deployed

``` { .bash .copy}
helm -n kubauth upgrade -i kubauth-kubeconfig --values ./values-kubeconfig.yaml \ 
    oci://quay.io/kubauth/charts/kubauth-kubeconfig --version 0.1.0-snapshot \
    --create-namespace --wait
```

## Validation

You can verify the correct deployment of this new pod:

``` { .bash .copy}
kubectl -n kubauth get pods
```
```
NAME                                  READY   STATUS    RESTARTS   AGE
kubauth-549b9b46c8-mlnhv              5/5     Running   0          24h
kubauth-kubeconfig-7d6949666c-zrhvl   1/1     Running   0          36s
```

And you can test the retrieval of information

``` { .bash .copy}
curl  https://kubeconfig.ingress.kubo6.mbp/kubeconfig | jq
```
```json
{
  "description": "Default OIDC client configuration",
  "cluster": {
    "apiServerURL": "https://127.0.0.1:5452",
  ......
```