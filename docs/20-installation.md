# Installation

## Prerequisites

Before you begin, ensure the following components are in place:

- **Kubectl Configuration:** A local Kubernetes client configuration with full cluster administrator privileges on the target cluster.

- **Certificate Manager:** The Certificate Manager must be deployed on your target Kubernetes cluster with a `ClusterIssuer` configured for certificate management.

- **Ingress Controller:** An NGINX ingress controller must be deployed on your target Kubernetes cluster.

- **Helm:** Helm must be installed on your local workstation.

!!! tip
    If you don't have a suitable Kubernetes cluster available, you can deploy a [Kind cluster](https://kind.sigs.k8s.io/){:target="_blank"} on your local workstation.

## Kubauth Deployment

The recommended method for installing Kubauth is using the provided OCI Helm chart.

Since several configuration parameters are required, we recommend using a values file rather than command-line arguments.

In your working directory, create a file with the following content:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      issuer: https://kubauth.ingress.kubo6.mbp
      postLogoutURL: https://kubauth.ingress.kubo6.mbp/index
    
      ingress:
        host: kubauth.ingress.kubo6.mbp
    
      server:
        certificateIssuer: cluster-odp
    ```

Replace the placeholder values with your environment-specific configuration:

- **`kubauth.ingress.kubo6.mbp`**: The hostname which will be used to access the Kubauth service from outside the cluster.<br>
  > Ensure this hostname is registered in your DNS.
- **`cluster-odp`**: The `ClusterIssuer` name from your Certificate Manager for ingress certificate provisioning.

!!! note

    This `values.yaml` represents the minimum required configuration. Additional parameters may be introduced in subsequent chapters.

Deploy Kubauth using the following command:

``` { .bash .copy }
helm -n kubauth upgrade -i kubauth --values ./values.yaml oci://quay.io/kubauth/charts/kubauth --version 0.1.2-snapshot --create-namespace --wait
```

After a few seconds, verify that the Kubauth server pod is running:

``` { .bash .copy }
kubectl -n kubauth get pods
```
```bash
NAME                       READY   STATUS    RESTARTS   AGE
kubauth-5d4fdc6bc8-7rlb6   3/3     Running   0          55s
```

Confirm that the Kubauth issuer URL is accessible:

```
curl https://kubauth.ingress.kubo6.mbp/.well-known/openid-configuration
```

## `kc` CLI Tool Installation

Download the `kc` CLI from the [GitHub releases page](https://github.com/kubauth/kc/releases/tag/0.1.2){:target="_blank"}, rename it to `kc`, make it executable, and move it to your system path:

```{ .bash .copy }
mv kc_*_* kc
chmod +x kc
sudo mv kc /usr/local/bin/
```

Verify the installation:

```{ .bash .copy }
kc version
```
