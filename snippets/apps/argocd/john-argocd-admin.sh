
kubectl apply -f - <<EOF
apiVersion: kubauth.kubotal.io/v1alpha1
kind: GroupBinding
metadata:
  name: john-argocd-admin
  namespace: kubauth-users
spec:
  group: argocd-admin
  user: john
EOF
