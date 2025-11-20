# User Groups

For most applications, a key attribute of a user is the groups they belong to. To handle this, Kubauth user management supports a Custom Resource: `GroupBinding.kubauth.kubotal.io`

## GroupBinding

Here is a sample manifest:

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

This associates the user `jim` with the group `devs`. Note that there is no explicit creation of a `devs` group. With Kubauth, a group exists simply by being referenced in a `GroupBinding`.


!!! note

    Generally, Kubernetes does not enforce referential integrity when creating resources that reference other resources. For example, the following will succeed:
    
    ```shell
    kubectl -n mynamespace create rolebinding missing-integrity --role=unexisting-role --group=unexisting-group

    rolebinding.rbac.authorization.k8s.io/missing-integrity created
    ```
    
    The referenced resource might be created later, or the reference might never be used. This is by design in Kubernetes, and Kubauth follows the same pattern.

Apply the manifest:

``` { .bash .copy }
kubectl apply -f group1.yaml
```
```bash
groupbinding.kubauth.kubotal.io/jim-dev created
```

Now, log in with the `jim` account:

``` { .bash .copy }
kc token --issuerURL https://kubauth.ingress.kubo6.mbp --clientId public -d
```

When inspecting the decoded JWT token, you should now find a `groups` claim:

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

This claim has been added by Kubauth based on the `GroupBinding` resource.

!!! question

    What if a `groups` claim is already defined in the `spec.claims` of the user entity?
    
    Answer: The `User.spec.claims.groups` value is overwritten.

## Group Custom Resource

Kubauth also allows explicit creation of `Group.kubauth.kubotal.io` entities.

There are two reasons to do this:

- Documentation, by setting a `spec.comment` attribute on the `Group` resource.
- Define a set of claims that will be applied to all group members.

For example, the following manifest will:

- Associate user `john` with the `devs` group defined previously.
- Associate user `john` with a newly created `ops` group.
- Explicitly create the `ops` group:
  - With a `spec.comment`
  - With a `spec.claims.accessProfile` that will be applied to all members.


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

Apply it:

``` { .bash .copy }
kubectl apply -f group2.yaml
```
```bash
groupbinding.kubauth.kubotal.io/john-dev created
groupbinding.kubauth.kubotal.io/john-ops created
group.kubauth.kubotal.io/ops created
```


Now, log in with the `john` account:

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

When inspecting the decoded JWT token, you should verify that:

- The `groups` claim now lists two values.
- The `accessProfile` claim is set with the appropriate value.

