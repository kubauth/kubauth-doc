
```
helm -n kubauth upgrade -i kubauth-apiserver --values ./values-k8s.yaml oci://quay.io/kubauth/charts/kubauth-apiserver --version 0.1.0-snapshot --create-namespace --wait
```

