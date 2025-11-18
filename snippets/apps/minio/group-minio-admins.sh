
kubectl apply -f - <<EOF
apiVersion: kubauth.kubotal.io/v1alpha1
kind: Group
metadata:
  name: minio-admins
  namespace: kubauth-users
spec:
  claims:
    minio_policies: "consoleAdmin"
EOF

