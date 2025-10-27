
```
helm -n kubauth upgrade -i kubauth --values ./values.yaml oci://quay.io/kubauth/charts/kubauth --version 0.1.2-snapshot --create-namespace --wait --set oidc.image.pullPolicy=Always

```

https://squidfunk.github.io/mkdocs-material/reference/admonitions/

