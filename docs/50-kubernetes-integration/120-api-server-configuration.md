
# Kubernetes API Server Configuration

## Automated Configuration

Kubauth provides a Helm chart that spawns appropriate jobs to perform this configuration in a fully automated manner.

This process assumes that the API Server is managed by the Kubelet as a static pod. If your API Server is managed by another system, such as systemd, you should fall back to the manual configuration.

Additionally, this process assumes a 'standard' folder layout for the Kubernetes installation, such as those used by [kind](https://kind.sigs.k8s.io/){:target="_blank"} or [kubespray](https://github.com/kubernetes-sigs/kubespray){:target="_blank"}. If this is not the case, adjustments can be made by overriding values in the Helm chart. Refer to its [values file](https://github.com/kubauth/kubauth-apiserver/blob/main/helm/kubauth-apiserver/values.yaml){:target="_blank"}.

!!! danger

    If you are performing this task on a critical cluster, we strongly recommend reading the Manual Configuration section below. This will help you fully understand what happens under the hood, enabling you to roll back manually in case of problems.

Since several configuration variables are required, we recommend using a values file rather than command-line arguments.

In your working directory, create a file like the following:

???+ abstract "values-k8s.yaml"

    ``` { .yaml .copy }
    config:
      oidc:
        issuerURL: https://kubauth.ingress.kubo6.mbp
        issuerCaSecretName: certs-bundle  # If using trust-manager (from cert-manager)
        issuerCaName: ca.crt
        clientId: k8s
        usernamePrefix: "-" # Dash means no prefix.
        groupsPrefix: "oidc-" # A prefix is mandatory (default is 'oidc:')
    ```

- Replace `kubauth.ingress.kubo6.mbp` with your Kubauth entry point
- `issuerCaSecretName`: A secret hosting the CA of the issuer URL. In this sample, we use [trust-manager](https://cert-manager.io/docs/trust/trust-manager/){:target="_blank"}, which creates such a secret (here `certs-bundle`) in each namespace.
- `issuerCaName`: The path of the CA certificate inside the secret.
- `clientId` should match the name of the `OidcClient` declared previously. Note that a `clientSecret` value is not needed, as the API server will not connect to Kubauth.
- `usernamePrefix`: Prefix prepended to username claims to prevent clashes with existing names. A dash value means no prefix.
- `groupsPrefix`: Prefix prepended to group claims to prevent clashes with existing names. Cannot be empty for security reasons. The default is `oidc:`, but in this sample, we set it to `oidc-`.

!!! note

    This `values.yaml` file represents the minimum required configuration. Refer to the Helm chart [values file](https://github.com/kubauth/kubauth-apiserver/blob/main/helm/kubauth-apiserver/values.yaml){:target="_blank"} for additional variables.

You can now proceed with the configuration using the dedicated Helm chart:

``` { .bash .copy }
helm -n kubauth upgrade -i kubauth-apiserver --values ./values-k8s.yaml oci://quay.io/kubauth/charts/kubauth-apiserver --version 0.1.0-snapshot --create-namespace --wait
```

!!! note

    This process will take some time, so please be patient.
    
    At the end of this process, a rolling restart is performed on the API Server. If there is only a single instance of this critical pod, you will lose contact with your cluster for a certain period.

    This may trigger the restart of many other pods. Wait for your cluster to reach a stable state before proceeding further.

### Verifying Installation

If your cluster is up and running, there is good chance installation was successful. 

If you suspect something went wrong, refer to the manual installation section below to check the configuration.

Also review the API server logs and/or kubelet logs.

### Removal

Uninstalling the Helm chart should restore the original API server configuration:

``` { .bash .copy }
helm -n kubauth uninstall kubauth-apiserver --wait
```

## Manual Configuration

The API server configuration for connecting an OIDC provider is [described here](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#configuring-the-api-server){:target="_blank"} in the Kubernetes documentation.

Depending on your specific installation, the directories mentioned below may vary. For reference, the clusters used for testing and documentation purposes were built using `kind`.

Additionally, this procedure assumes that the API Server is managed by the Kubelet as a static pod. If your API Server is managed by another system, such as systemd, you should make the necessary adjustments accordingly.

!!! note

    The following operations must be executed on all nodes hosting an instance of the Kubernetes API server, typically all nodes within the control plane.

These operations require root access on these nodes. Each node must also have `kubectl` installed and an editor available.

For each node:

- Log into it:

    ```
    docker exec -it kubo6-control-plane /bin/bash
    ```
- Create a folder to store the Kubauth issuer URL certificate (`-kit` stands for Kubernetes Integration Toolkit):

    ```
    mkdir /etc/kubernetes/kubauth-kit 
    ```
  
- Fetch the Kubauth issuer URL certificate and store it in the newly created folder:

    ```
    kubectl -n kubauth get secret kubauth-oidc-server-cert \
    -o=jsonpath='{.data.ca\.crt}' | base64 -d >/etc/kubernetes/kubauth-kit/ca.crt  
    ```
  
- Edit the `kube-apiserver.yaml` manifest:

    ```
    vi /etc/kubernetes/manifests/kube-apiserver.yaml
    ```
  
    Make the following modifications:
    
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
    - In `--oidc-issuer-url`, replace `kubauth.ingress.kubo6.mbp` with your Kubauth entry point.
    - `--oidc-client-id` should match the name of the `OidcClient` declared previously. Note that a `clientSecret` value is not needed, as the API server will not connect to Kubauth.
    - `--oidc-username-prefix`: Prefix prepended to username claims to prevent clashes with existing names. A dash value means no prefix.
    - `--oidc-groups-prefix`: Prefix prepended to group claims to prevent clashes with existing names. Cannot be empty for security reasons. The default is `oidc:`, but in this sample, we set it to `oidc-`.
    - The `volumeMounts` and `volumes` sections allow the certificate to be accessible from inside the container.

- Modifying the `/etc/kubernetes/manifests/kube-apiserver.yaml` file will trigger a restart of the API server pod.
