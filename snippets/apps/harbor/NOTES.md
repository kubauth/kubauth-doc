



# harbor


```
cd .../nih

git clone https://github.com/goharbor/harbor-helm.git 

```

```
cd ..../harbor



helm -n harbor upgrade -i harbor --values ./values-base.yaml  --values ./values-kubauth.yaml ../../../../../nih/harbor-helm/ --create-namespace --wait

```

```
helm -n harbor uninstall harbor && kubectl delete ns harbor

```

If you did not change them in harbor. yml , the default administrator username and password are admin and Harbor12345 .


