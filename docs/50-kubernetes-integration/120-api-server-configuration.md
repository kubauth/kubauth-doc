
# K8S API Server configuration

## Automated configuration

Kubauth provide an Helm chart which will spawn appropriate jobs to perform this configuration in a fully automated way.

This process assume that the API Server is managed by the Kubelet as a static pod. If your API Server is managed by 
another system, such as systemd, you should fallback to the manual configuration.

Also, this process assume some 'standard' folder layout on kubernetes installation, 
such as used by [kind](https://kind.sigs.k8s.io/){:target="_blank"} or [kubespray](https://github.com/kubernetes-sigs/kubespray){:target="_blank"}. 
If this is not the case, some adjustment can be performed by overwriting values in the Helm chart. Refer to 
its [values file](https://github.com/kubauth/kubauth-apiserver/blob/main/helm/kubauth-apiserver/values.yaml){:target="_blank"} 

!!! danger

    If you perform this task on a 'critical' cluster, we strongly engage you to read the Manual configuration chapter below. 
    This to fully understand what's append under the hood, to be able to rollback manually in case of problem.

As there are several required configuration variable, we suggest to use a 'values file' instead of setting variable on the command line.

So, in your working folder, create a file like the following:

???+ abstract "values-k8s.yaml"

    ``` { .yaml .copy }
    config:
      oidc:
        issuerURL: https://kubauth.ingress.kubo6.mbp
        issuerCaSecretName: certs-bundle  # If we use trust-manager (from certificate-server)
        issuerCaName: ca.crt
        clientId: k8s
        usernamePrefix: "-" # Dash is no prefix.
        groupsPrefix: "oidc-" # A prefix is mandatory (Default to 'oidc:')
    ```

- `kubauth.ingress.kubo6.mbp` must be replaced by your Kubauth entry point
- `issuerCaSecretName`: A secret hosting the CA of the issuerURL. In this sample, we use [trust manager](https://cert-manager.io/docs/trust/trust-manager/){:target="_blank"}
  which create such secret (here `certs-bundle`) in each namespace.
- `issuerCaName`: The path of the CA certificate inside the secret.
- `clientId` should match the name of the `OidcClient` declared previously. Note there is no need to a `clientSecret` value, as the API server will not connect to Kubauth.
- `usernamePrefix`: Prefix prepended to username claims to prevent clashes with existing names. Dash value means no prefix.
- `groupsPrefix`: Prefix prepended to group claims to prevent clashes with existing names. Could not be empty for security reasons. Default is `oidc:` but in this sample, we set to `oidc-`.

!!! notes

    This `values.yaml` file is the bare minimum configuration set. Refer to the Helm chart 
    [values file](https://github.com/kubauth/kubauth-apiserver/blob/main/helm/kubauth-apiserver/values.yaml){:target="_blank"} for more variables.

You can now proceed with the configuration, using the adhoc Helm chart

``` { .bash .copy }
helm -n kubauth upgrade -i kubauth-apiserver --values ./values-k8s.yaml oci://quay.io/kubauth/charts/kubauth-apiserver --version 0.1.0-snapshot --create-namespace --wait
```

!!! Notes

    Note this process will take some time. So, be patient. 
    
    Also, At the end of this process, a rolling restart is performed on the API Server.
    In case there will be a single instance of this critical pod, this means you will lost contact with your cluster for a certain amount of time.

    And this may trigger the restart of many other pods. So, wait for all your cluster to reach a stable state before moving one.

### Varifying installation

If you suspect things goes wrong, you can refer to the manual installation below to check the configuration.

Have a look also on API server logs and/or kubelet logs. 

### Removal

Uninstalling the Helm chart should restore the original API server configuration 

``` { .bash .copy }
helm -n kubauth uninstall kubauth-apiserver --wait
```

## Manual configuration

The API server configuration to connect an OIDC provider is
[described here](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#configuring-the-api-server){:target="_blank"} in Kubernetes documentation.

Depending on your specific installation, the directory mentioned below may vary. For reference, the clusters used for testing and documentation purposes were built using kind.

Additionally, this procedure assumes that the API Server is managed by the Kubelet as a static Pod. If your API Server is managed by another system, such as systemd, you should make the necessary adjustments accordingly.

!!! notes

    Please note that the following operations must be executed on all nodes hosting an instance of the Kubernetes API server, typically encompassing all nodes within the control plane.

These operations require 'root' access on these nodes. Also each node must have `kubectl` installed and an editor available.

For each node:

- Log on it

    ```
    docker exec -it kubo6-control-plane /bin/bash
    ```
- Create a folder to store the Kubauth issuerURL certificate (-kit stands for K8s Integration Toolkit)

    ```
    mkdir /etc/kubernetes/kubauth-kit 
    ```
  
- Fetch the Kubauth issuerURL certificate and store it in our newly created folder:

    ```
    kubectl -n kubauth get secret kubauth-oidc-server-cert \
    -o=jsonpath='{.data.ca\.crt}' | base64 -d >/etc/kubernetes/kubauth-kit/ca.crt  
    ```
  
- And edit the `kube-apiserver.yaml` manifest

    ```
    vi /etc/kubernetes/manifests/kube-apiserver.yaml
    ```
  
    With the following modifications:
    
    ```
    spec:
      containers:
      - command:
        - kube-apiserver
        - "--oidc-ca-file=/etc/kubernetes/kubauth-kit/ca.crt"
        - "--oidc-groups-prefix=oidc-"
        - --oidc-groups-claim=groups
        - "--oidc-username-prefix=-"
        - --oidc-username-claim=sub
        - --oidc-client-id=k8s
        - "--oidc-issuer-url=https://kubauth.ingress.kubo6.mbp"
        ..........
        ..........
        volumeMounts:
        - mountPath: /etc/kubernetes/kubauth-kit
          name: kubauth-kit-config
        ..........
      ..........
      volumes:
      - hostPath:
          path: /etc/kubernetes/kubauth-kit
          type: ""
        name: kubauth-kit-config
      ..........
    ```
  
    - Quotes (`"`) are important.
    - In `--oidc-issuer-url`, `kubauth.ingress.kubo6.mbp` must be replaced by your Kubauth entry point
    - `--oidc-client-id` should match the name of the `OidcClient` declared previously. Note there is no need to a `clientSecret` value, as the API server will not connect to Kubauth.
    - `--oidc-username-prefix`: Prefix prepended to username claims to prevent clashes with existing names. Dash value means no prefix.
    - `--oidc-groups-prefix`: Prefix prepended to group claims to prevent clashes with existing names. Could not be empty for security reasons. Default is `oidc:` but in this sample, we set to `oidc-`.
    - `volumeMounts` and `volumes` sections allow the certificate to be reachable from inside the container.

- The fact than `/etc/kubernetes/manifests/kube-apiserver.yaml` file is modified will trigger a restart or the API server pod.