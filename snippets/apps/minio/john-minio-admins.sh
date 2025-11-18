
kubectl apply -f - <<EOF
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-minio-admins
  namespace: kubauth-users
spec:
  group: minio-admins
  user: john
EOF

