
```
helm -n kubauth upgrade -i kubauth --values ./values.yaml oci://quay.io/kubauth/charts/kubauth --version 0.2.0 --create-namespace --wait --set oidc.image.pullPolicy=Always

```

https://squidfunk.github.io/mkdocs-material/reference/admonitions/




## Other Helm configuration variables


oidc.allowPasswordGrant

oidc.jwtAccessToken

oidc.clientPrivilegedNamespace


```

helm -n kubauth upgrade -i kubauth --values ./values.yaml oci://quay.io/kubauth/charts/kubauth --version 0.2.0 --create-namespace --wait

helm -n kubauth uninstall kubauth

curl https://kubauth.ingress.kubo2.mbp/.well-known/openid-configuration
```

```
kc token --issuerURL https://kubauth.ingress.kubo2.mbp --clientId public

kc token --issuerURL https://kubauth.ingress.kubo2.mbp --clientId private --clientSecret secret1


kc token --issuerURL https://kubauth.ingress.kubo2.mbp --clientId public --onlyIdToken | kc jwt


kc token --issuerURL https://kubauth.ingress.kubo2.mbp --clientId public -d



kc token --issuerURL https://kubauth.ingress.kubo2.mbp --clientId public --onlyAccessToken | kc jwt

kc logout --issuerURL https://kubauth.ingress.kubo2.mbp



kc token-nui --issuerURL https://kubauth.ingress.kubo2.mbp --clientId public

kc token-nui --issuerURL https://kubauth.ingress.kubo2.mbp --clientId public \
    --login jim --password jim123 --onlyIdToken



```