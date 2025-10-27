
```
helm -n kubauth upgrade -i kubauth --values ./values.yaml oci://quay.io/kubauth/charts/kubauth --version 0.1.2-snapshot --create-namespace --wait --set oidc.image.pullPolicy=Always

```

https://squidfunk.github.io/mkdocs-material/reference/admonitions/



Installation
User guide
  - Configuration
  - login and claims
  - Audit
  - SSO
  - Groups
  - Password grant
  - LDAP setup
  - Identity providers chaining
Kubernetes integration
  - apiserver
  - kubeconfig
  - Deploying as regular user
Apps Configuration
  - Harbor
  - ArgoCD
Appendix
  - OpenLDAP deployment
