# OpenLDAP Deployment


If you do not have easy access to an LDAP server and want to test Kubauth with this configuration, one solution is to deploy an OpenLDAP server on your Kubernetes cluster.

We can use the following Helm chart [https://github.com/jp-gouin/helm-openldap](https://github.com/jp-gouin/helm-openldap){:target="_blank"} for such a deployment.

## Configuration

Here is a sample values file:

???+ abstract "values-openldap.yaml"

    ``` { .yaml .copy }
    replicaCount: 2
    replication:
      enabled: true
      tls_reqcert: never
    global:
      adminPassword: admin123
      adminUser: admin
      configPassword: admin123
      configUser: admin
      ldapDomain: mycompany.com
    initTLSSecret:
      tls_enabled: false
    persistence:
      storageClass: standard
    ltb-passwd:
      enabled : false
    phpldapadmin:
      enabled: true
      ingress:
        enabled: true
        ingressClassName: nginx
        hosts:
          - phpldapadmin.ingress.kubo6.mbp
    service:
      type: ClusterIP
    ```
If you want to use the phpldapadmin frontend, you will need to adjust at least the `phpldapadmin.ingress.hosts` value.

This deployment is simplified to fulfill our testing requirements only. It is far from production-ready:

- There is no encryption. Connections are in clear text.
- There is no LoadBalancer. LDAP is only accessible from inside the cluster using the appropriate service.

## Sample Dataset

The following values file will create two groups and three users in a fictitious company.

???+ abstract "values-ldap-init.yaml"

    ``` { .yaml .copy }
    customLdifFiles:
      00-root.ldif: |-
        # Root creation
        dn: dc=mycompany,dc=com
        objectClass: dcObject
        objectClass: organization
        o: MyCompany
      01-base-ou.ldif: |-
        dn: ou=Users,dc=mycompany,dc=com
        objectClass: organizationalUnit
        ou: Users
    
        dn: ou=Groups,dc=mycompany,dc=com
        objectClass: organizationalUnit
        ou: Groups
      03-first-groups.ldif: |-
        dn: cn=staff,ou=Groups,dc=mycompany,dc=com
        objectclass: posixGroup
        objectclass: top
        gidnumber: 500
        cn: staff
        memberUid: alice
        memberUid: fred
        memberUid: bob
    
        dn: cn=managers,ou=Groups,dc=mycompany,dc=com
        objectclass: posixGroup
        objectclass: top
        gidnumber: 501
        cn: managers
        memberUid: alice
        memberUid: fred
      05-first-users.ldif: |-
        dn: uid=alice,ou=Users,dc=mycompany,dc=com
        cn: Alice SMITH
        objectclass: inetOrgPerson
        objectclass: top
        sn: SMITH
        uid: alice
        mail: alice@mycompany.com
        userpassword: alice123
    
        dn: uid=bob,ou=Users,dc=mycompany,dc=com
        cn: Bob MORANE
        objectclass: inetOrgPerson
        objectclass: top
        sn: MORANE
        uid: bob
        mail: bob@mycompany.com
        userpassword: bob123
    
        dn: uid=fred,ou=Users,dc=mycompany,dc=com
        cn: Fred ASTER
        objectclass: inetOrgPerson
        objectclass: top
        sn: ASTER
        uid: fred
        mail: fred@mycompany.com
        userpassword: fred123
    ```

As you can see, passwords are in clear text.

> OpenLDAP allows you to provide them as hashed values.

## Deployment

You can now proceed with a standard Helm deployment.

First, register the Helm repository:

``` { .bash .copy }
helm repo add helm-openldap https://jp-gouin.github.io/helm-openldap/
```

Then, deploy using the two values files:

``` { .copy }
helm -n openldap upgrade -i openldap helm-openldap/openldap-stack-ha \
    --values ./values-openldap.yaml --values ./values-ldap-init.yaml \
    --version 4.3.3 --create-namespace --wait
```

You should now be able to log in to the phpldapadmin frontend. Use `cn=admin,dc=mycompany,dc=com` as the Login DN and `admin123` as the password.


## Update / Removal

If you want to update the configuration, you can issue another `helm upgrade -i ...` command. **However, if you intend to modify the dataset (users, groups), this will be ineffective.**

The Helm chart is designed such that the dataset is used only on initial deployment.

Therefore, apart from using the frontend, the easiest way to modify the dataset is to uninstall everything and reinstall.

``` { .bash .copy }
helm -n openldap uninstall openldap &&  kubectl delete ns openldap
```

Deleting the namespace is important, as it will clean up the associated Persistent Volumes. Not doing so will preserve the old data.
