
```
cd .../nih

git clone https://github.com/argoproj/argo-helm.git

cd ...../nih/argo-helm/charts/argo-cd
helm repo add redis-ha https://dandydeveloper.github.io/charts/
helm dependency build

```




```
cd ..../argocd

helm -n argocd upgrade -i argocd --values ./values-base.yaml --values values-kubauth.yaml ../../../../../nih/argo-helm/charts/argo-cd --create-namespace

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

```

```
helm -n argocd uninstall argocd && kubectl delete ns argocd

```