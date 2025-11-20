
# Kubeconfig Service

## Configuration

To configure your local kubeconfig, certain information is required (API server address, Certificate Authority, OIDC issuer URL, etc.). Kubauth provides a service to publish this information for use by a local tool that configures the `kubeconfig` file.

This service is deployed using a Helm chart. Since its configuration includes numerous parameters, create a values file like the following:

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
          namespace:  # Left blank to allow default context for users
        oidc:
          issuerURL: https://kubauth.ingress.kubo6.mbp
          issuerCaSecretName: certs-bundle
          issuerCaName: ca.crt
          clientId: k8s
          clientSecret: k8s123
    ```

Several fields must be adjusted depending on your environment:

- `ingress.host`: The FQDN used for accessing the service from outside the cluster.
- `server.tls`: Enables secure communication (recommended).
- `certificateIssuer`: The `ClusterIssuer` from your Certificate Manager for ingress certificate provisioning.
- `networkPolicies.enabled`: Must be set to `true` if your cluster enforces network policies. A rule will be generated to allow access to the service by the ingress controller.
- `kubeconfigs.default.cluster.apiServerURL`: The URL to access the API Server from the client workstation. Set to 127.0.0.1 in this sample, as we target a local kind cluster.
- `kubeconfigs.default.context.name`: The local name of this context. Useful when managing multiple clusters.
- `kubeconfigs.default.context.namespace`: Optional. Sets a specific default namespace on user login.
- `kubeconfigs.default.oidc.issuerURL`: Set to your Kubauth entry point.
- `kubeconfigs.default.oidc.issuerCaSecretName`: A secret hosting the CA of the issuer URL. In this sample, we use [trust-manager](https://cert-manager.io/docs/trust/trust-manager/){:target="_blank"}, which creates such a secret (here `certs-bundle`) in each namespace.
- `kubeconfigs.default.oidc.issuerCaName`: The path of the CA certificate inside the secret.
- `kubeconfigs.default.oidc.clientId`: Should match the name of the `OidcClient` declared previously.
- `kubeconfigs.default.oidc.clientSecret`: The secret defined in the `OidcClient` declared previously. Leave blank if the `OidcClient` is `public`.

## Deployment

Deploy the Helm chart:

``` { .shell .copy}
helm -n kubauth upgrade -i kubauth-kubeconfig --values ./values-kubeconfig.yaml \ 
    oci://quay.io/kubauth/charts/kubauth-kubeconfig --version 0.1.0-snapshot \
    --create-namespace --wait
```

## Validation

Verify the correct deployment of this new pod:

``` { .bash .copy}
kubectl -n kubauth get pods
```
```
NAME                                  READY   STATUS    RESTARTS   AGE
kubauth-549b9b46c8-mlnhv              5/5     Running   0          24h
kubauth-kubeconfig-7d6949666c-zrhvl   1/1     Running   0          36s
```

Test the retrieval of information:

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
