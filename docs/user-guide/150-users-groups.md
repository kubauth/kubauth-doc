# Users Groups

TODO



### Kubernetes RBAC referential integrity

Kubernetes does not check referential integrity when creating a resource that references another one.
For example, the following will work:

```shell
kubectl -n ldemo create rolebinding missing-integrity --role=unexisting-role --group=unexisting-group
> rolebinding.rbac.authorization.k8s.io/missing-integrity created

$ kubectl sk user bind unexisting-user unexisting-group
> GroupBinding 'unexisting-user.unexisting-group' created in namespace 'skas-system'.
```

Maybe the referenced resource will be created later, or the link will be useless.

This is evidently a design choice in Kubernetes, and SKAS follows the same logic.
