# Installation

## Prerequisite

Before you begin, make sure you meet the following prerequisites:
 
- **Kubectl Configuration:** You should have a local client Kubernetes configuration with full administrative
  rights on the target cluster.

- **Certificate Manager:** Ensure that the Certificate Manager is deployed in your target Kubernetes cluster, and a `ClusterIssuer` is defined for certificate management.

- **Ingress Controller:** An NGINX ingress controller should be deployed in your target Kubernetes cluster. With of course an upfront load balancer.

- **Helm:** Helm must be installed locally on your system.

!!! tip
    If you don't have an appropriate Kubernetes cluster at your disposal, you can deploy a [Kind cluster](https://kind.sigs.k8s.io/){:target="_blank"} on your local workstation

## Kubauth Deployment

The most straightforward and recommended method for installing Kubauth is by using the provided OCI Helm chart.

As there are several required configuration variable, we suggest to use a 'values file' instead of setting variable on the command line.

So, in your working folder, create a file like the following:

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

Replace the values with your specific configuration:

- **`kubauth.ingress.kubo6.mbp`**: Replace by the hostname used for accessing the `kubauth` service from outside the cluster.<br>
  > Make sure to define this hostname in your DNS.
- **`cluster-odp`**: Replace by the `ClusterIssuer` from your Certificate Manager for ingress certificate creation.

!!! notes

    This `values.yaml` file is the bare minimum configuration set. In subsequent chapters, more variables may be added. 

Then, you can deploy Kubauth with the following command.


``` { .bash .copy }
helm -n kubauth upgrade -i kubauth --values ./values.yaml oci://quay.io/kubauth/charts/kubauth --version 0.1.2-snapshot --create-namespace --wait
```

After few seconds, verify the Kubauth server pod is running:

``` { .bash .copy }
kubectl -n kubauth get pods
```
```bash
NAME                       READY   STATUS    RESTARTS   AGE
kubauth-5d4fdc6bc8-7rlb6   3/3     Running   0          55s
```

And check the Kubauth issuer URL is reachable:


```
curl https://kubauth.ingress.kubo6.mbp/.well-known/openid-configuration
```

## `kc` CLI tool installation

Download the `kc` CLI from the [GitHub releases page](https://github.com/kubauth/kc/releases/tag/0.1.2){:target="_blank"}
and rename it to `kc`. Then make it executable and move it to your path:

```{ .bash .copy }
mv kc_*_* kc
chmod +x kc
sudo mv kc /usr/local/bin/
```

Verify the installation:

```{ .bash .copy }
kc version
```
