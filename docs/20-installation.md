# Installation

## Prerequisites

Before you begin, ensure the following components are in place:

- **Kubectl Configuration:** A local Kubernetes client configuration with full cluster administrator privileges on the target cluster.

- **Certificate Manager:** The Certificate Manager must be deployed on your target Kubernetes cluster with a `ClusterIssuer` configured for certificate management.

- **Ingress Controller:** An ingress controller must be deployed on your target Kubernetes cluster. The provided Helm chart can configure an ingress for either NGINX or HAProxy.
  If you use another controller, you can disable the built-in ingress and bring your own (see [below](#ingress-configuration)).

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
      issuer: https://kubauth.mycluster.mycompany.com
      postLogoutURL: https://kubauth.mycluster.mycompany.com/index
    
      ingress:
        enabled: true
        host: kubauth.mycluster.mycompany.com
    
      server:
        certificateIssuer: my-issuer
    ```

Replace the placeholder values with your environment-specific configuration:

- **`kubauth.mycluster.mycompany.com`**: The hostname used to access the Kubauth service from outside the cluster.<br>
  > Ensure this hostname is registered in your DNS.
- **`my-issuer`**: The `ClusterIssuer` name from your Certificate Manager for ingress certificate provisioning.

!!! note

    This `values.yaml` represents the minimum required configuration. Additional parameters may be introduced in subsequent chapters.

Deploy Kubauth using the following command:

``` { .bash .copy }
helm -n kubauth upgrade -i kubauth --values ./values.yaml oci://quay.io/kubauth/charts/kubauth --version 0.3.0 --create-namespace --wait
```

> The release name (here `kubauth`) is important, as most created objects use it as a base name. 
  If you change it, you will need to adjust most of the manifests and commands in this manual accordingly.
  The same applies to the namespace.

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
curl https://kubauth.mycluster.mycompany.com/.well-known/openid-configuration
```




## `kc` CLI Tool Installation

Download the `kc` CLI from the [GitHub releases page](https://github.com/kubauth/kc/releases/tag/v0.2.1){:target="_blank"}, rename it to `kc`, make it executable, and move it to your system path:

```{ .bash .copy }
mv kc_*_* kc
chmod +x kc
sudo mv kc /usr/local/bin/
```

Verify the installation:

```{ .bash .copy }
kc version
```

## Ingress Configuration

The Helm chart can generate the `Ingress` resource for either NGINX or HAProxy. When this is not enough, you can disable the built-in ingress and configure your own.

### Ingress Class

By default, the chart targets the `nginx` ingress class. To target HAProxy instead, override `oidc.ingress.class`:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      ......
      ingress:
        enabled: true
        class: haproxy        # nginx (default) or haproxy
        host: kubauth.mycluster.mycompany.com
      ......
    ```

### SSL Passthrough vs SSL Backend

Kubauth terminates TLS inside the pod, so the chart configures the ingress in **SSL passthrough** mode by default. The relevant annotations are emitted automatically for both `nginx` and `haproxy`.

If your controller cannot run in passthrough mode, set `oidc.ingress.passthrough: false`. The ingress will then terminate TLS itself and forward HTTPS traffic to the Kubauth backend:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      ......
      ingress:
        enabled: true
        class: nginx          # or haproxy
        host: kubauth.mycluster.mycompany.com
        passthrough: false
      ......
    ```

In this mode the chart automatically:

- adds the `nginx.ingress.kubernetes.io/backend-protocol: HTTPS` and `haproxy.org/server-ssl: "true"` annotations,
- declares a `spec.tls` entry pointing at the certificate issued for the Kubauth host (so the controller can present a valid certificate at the edge).

### Using a Different Ingress Controller

For any other ingress controller (Traefik, Contour, ...), disable the built-in ingress:

???+ abstract "values.yaml"

    ``` { .yaml .copy }
    oidc:
      ......
      ingress:
        enabled: false
      ......
    ```

Then configure your controller to:

- route traffic to the `kubauth-oidc-server` Service on port `443`,
- use SSL passthrough, since TLS is terminated by the Kubauth pod itself.
