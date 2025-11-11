# OpenLDAP deployment


If you do not have an easy access to an LDAP server and if you want to exercise **Kubauth** with this configuration, 
one solution could be to deploy an OpenLDAP server on your Kubernetes cluster

We may use the following helm chart [https://github.com/jp-gouin/helm-openldap](https://github.com/jp-gouin/helm-openldap){:target="_blank"} for such deployment.

## Configuration

Here is a sample 'values file': 

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
If you want to use the phpldapadmin front end, you will have to adjust at least the `phpldapadmin.ingress.host`

This deployment is simplified to just fulfill our test requirement. Far to be 'production ready' 

- There is no encryption. Connection is in clear text.
- There is no LoadBalancer. LDAP is only accessible from inside the cluster using appropriate service.

## Sample dataset

The following other 'values file' will create two groups and three users in a fictitious company.

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

As you can see, password are in clear text. 

> OpenLDAP allow to provide them as hashed values

## Deployment

You can now proceed as usual for an Helm deployment.

First, you need to register the helm repo: 

``` { .bash .copy }
helm repo add helm-openldap https://jp-gouin.github.io/helm-openldap/
```

Then, you can deploy using the two values files.

``` { .copy }
helm -n openldap upgrade -i openldap helm-openldap/openldap-stack-ha \
    --values ./values-openldap.yaml --values ./values-ldap-init.yaml \
    --version 4.3.3 --create-namespace --wait
```

You should now being able to log on the phpldapadmin front end. Use `cn=admin,dc=mycompany,dc=com` as Login DN and `admin123` as password.


## Update / Removal

If you want to update the configuration, you can issue again an `helm update -i .....` command. **But, if you intend to modify the data set (Users, Groups), this will be uneffective.**

The Helm chart is build such a way than the dataset is used only on the initial deployment. 

So, apart from using the frontend, the easiest way to modify it is to uninstall everythings and re-install.

``` { .bash .copy }
helm -n openldap uninstall openldap &&  kubectl delete ns openldap
```

The deletion of the namespace is important, as it will cleanup the associated Persistant Volumes. Not doing so will preserve old data.
