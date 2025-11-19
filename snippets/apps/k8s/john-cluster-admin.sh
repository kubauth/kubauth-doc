
kubectl apply -f - <<EOF
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-cluster-admin
  namespace: kubauth-users
spec:
  group: cluster-admin
  user: john
EOF


