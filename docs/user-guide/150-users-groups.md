# Users Groups

For most application, a Key attribute of a user is the groups this user belong to. To handle this, 
Kubauth user management support a Custom Resource: `GroupBinding.kubauth.kubotal.io`

## GroupBinding

Here is a sample manifest

???+ abstract "group1.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: GroupBinding
    metadata:
      name: jim-dev
      namespace: kubauth-users
    spec:
      user: jim
      group: devs
    ```

This will associate the user `jim` to the group `devs`. Note there is no explicit creation of a `dev` group. 
With Kubauth, a group can exist only because it is referenced by a `GroupBinding`.


!!! notes

    Generally, Kubernetes does not check referential integrity when creating a resource that references another one.
    For example, the following will work:
    
    ```shell
    kubectl -n ldemo create rolebinding missing-integrity --role=unexisting-role --group=unexisting-group

    rolebinding.rbac.authorization.k8s.io/missing-integrity created
    ```
    
    Maybe the referenced resource will be created later, or the link will be useless. This is evidently a design choice in Kubernetes, and Kubauth follows the same logic.

Now, apply the manifest:

``` { .bash .copy }
kubectl apply -f group1.yaml
```
```bash
groupbinding.kubauth.kubotal.io/jim-dev created
```

Now, login with the `jim` account:

``` { .bash .copy }
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public -d
```

When looking at the decoded JWT token, you should now find a `groups` claim:

```bash
.....
JWT Payload:
{
  "at_hash": "bHHRRCaQSInJLqDviiW4Ag",
  "aud": [
    "public"
  ],
  "auth_time": 1761643474,
  "auth_time_human": "2025-10-28 09:24:34 UTC",
  "azp": "public",
  "exp": 1761647074,
  "exp_human": "2025-10-28 10:24:34 UTC",
  "groups": [
    "devs"
  ],
  "iat": 1761643474,
  "iat_human": "2025-10-28 09:24:34 UTC",
  "iss": "https://kubauth.ingress.kubo6.mbp",
  "jti": "4a3aed23-e2df-474c-9c26-d8f275d0f51f",
  "rat": 1761643474,
  "rat_human": "2025-10-28 09:24:34 UTC",
  "sub": "jim"
}

```

This claim has been added by Kubauth, based on `GroupBinding` resource.

!!! question

    What if a `groups` claim has already being defined in the `spec.claims` set of the user entity ? 
    
    Answer: The `User.spec.claims.groups` is overwritten. 

## Group Custom Resource

Kubauth also allow the explicit creation of `Group.kubauth.kubotal.io` entity.

There will be two reason to do so:

- Documentation, by setting a `spec.comment` attribut on the `Group` resource.
- Define a set of 'Claims', which will be applied to all members of the group.

For example, the following manifest will:

- Associate user `john` to the group `devs` defined previously.
- Associate user `john` to the group `ops`, newly create.
- Create explicitly the group `ops`
  - with a `spec.comment` 
  - and a `spec.claims.accessProfile`, which will be set for all members. 


???+ abstract "group2.yaml"

    ``` { .yaml .copy }
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: GroupBinding
    metadata:
      name: john-dev
      namespace: kubauth-users
    spec:
      user: john
      group: devs
    
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: GroupBinding
    metadata:
      name: john-ops
      namespace: kubauth-users
    spec:
      user: john
      group: ops
    
    ---
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: Group
    metadata:
      name: ops
      namespace: kubauth-users
    spec:
      comment:
      claims:
        accessProfile: p24x7
    
    ```

Apply it

``` { .bash .copy }
kubectl apply -f group2.yaml
```
```bash
groupbinding.kubauth.kubotal.io/john-dev created
groupbinding.kubauth.kubotal.io/john-ops created
group.kubauth.kubotal.io/ops created
```


And now, login with the `john` account:

``` { .bash .copy }
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public -d
```

```bash
.....
JWT Payload:
{
  "accessProfile": "p24x7",
  "at_hash": "jUGx994P_ESx3KtujtlFLA",
  "aud": [
    "public"
  ],
  "auth_time": 1761647376,
  "auth_time_human": "2025-10-28 10:29:36 UTC",
  "azp": "public",
  "email": "johnd@mycompany.com",
  "emails": [
    "johnd@mycompany.com"
  ],
  "exp": 1761650976,
  "exp_human": "2025-10-28 11:29:36 UTC",
  "groups": [
    "devs",
    "ops"
  ],
  "iat": 1761647376,
  "iat_human": "2025-10-28 10:29:36 UTC",
  "iss": "https://kubauth.ingress.kubo6.mbp",
  "jti": "629164c8-75b5-4e16-850f-0975f0afc508",
  "name": "John DOE",
  "office": "208G",
  "rat": 1761647376,
  "rat_human": "2025-10-28 10:29:36 UTC",
  "sub": "john"
}
```

When looking at the decoded JWT token, you should check than:

- The `groups` claim now list two values.
- The `accessProfile` claims is set with appropriate value.

