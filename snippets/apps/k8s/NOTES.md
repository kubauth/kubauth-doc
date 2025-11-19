
```
helm -n kubauth upgrade -i kubauth-apiserver --values ./values-k8s.yaml oci://quay.io/kubauth/charts/kubauth-apiserver --version 0.1.0-snapshot --create-namespace --wait
```


```
helm -n kubauth uninstall kubauth-apiserver --wait
```

```
helm -n kubauth upgrade -i kubauth-kubeconfig --values ./values-kubeconfig.yaml oci://quay.io/kubauth/charts/kubauth-kubeconfig --version 0.1.0-snapshot --create-namespace --wait
```


```
helm -n kubauth uninstall kubauth-kubeconfig --wait
```


```
kc config https://kubeconfig.ingress.kubo6.mbp/kubeconfig

```