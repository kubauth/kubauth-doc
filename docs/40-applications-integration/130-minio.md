# MinIO Integration

!!! warning

    At the time of writing this manual, there are changes underway in how MinIO is distributed.

    The configuration provided here has been validated on the latest OSS MinIO version that includes a fully functional Console Admin.

    It should also apply to MinIO AIStor, the proprietary version of MinIO.

## OIDC Client Creation

As described in [Configuration](../30-user-guide/110-configuration.md/#oidc-client-creation), a client application is defined as a Kubernetes Custom Resource.

Create a manifest like the following:

???+ abstract "client-minio.yaml"

    ``` { .yaml .copy }
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: minio
      namespace: kubauth-oidc
    spec:
      hashedSecret: "$2a$12$mll9UA1oefLGY0KcAbvrG.Jvssjqlt8wSDtb2DNvEK4Oc/YYaJ8iy"
      redirectURIs:
        - "https://minio-console-minio1.ingress.kubo6.mbp/oauth_callback"
      grantTypes: [ "refresh_token", "authorization_code" ]
      responseTypes: ["id_token", "code", "token", "id_token token", "code id_token", "code token", "code id_token token"]
      scopes: [ "openid", "offline", "profile", "groups", "email", "offline_access", "address", "phone"]
      # Following are optional
      displayName: MinIO
      description: S3 Server
      entryURL: "https://minio-console-minio1.ingress.kubo6.mbp"
    ```


- Replace `minio-console-minio1.ingress.kubo6.mbp` with your MinIO console entry point (in 2 locations)
- The sample password is 'minio123'. The `hashedSecret` value is the result of the `kc hash minio123` command.
- The `scopes` include `address` and `phone`, which appear to be required by MinIO's default configuration.
- The `displayName`, `description`, and `entryURL` attributes are optional. They enable MinIO to appear in a list of available applications displayed on a specific page (`https://kubauth.ingress.kubo6.mbp/index`) or the logout page.

Apply this manifest:

``` { .bash .copy }
kubectl apply -f client-minio.yaml
```

## MinIO Configuration

We assume you have a fully functional MinIO deployment.

We also assume you have the `mc` command configured with an alias (`myminio` below) that grants full admin rights.

One method to configure an OIDC connection for MinIO is by issuing a specific command:


``` { .bash .copy }
mc idp openid add myminio kubauth \
    client_id=minio \
    client_secret=minio123 \
    config_url="https://kubauth.ingress.kubo6.mbp/.well-known/openid-configuration" \
    redirect_uri="https://minio-console-minio1.ingress.kubo6.mbp/oauth_callback" \
    claim_name="minio_policies" \
    display_name=KUBAUTH \
    claim_userinfo="on"
```

- Replace `minio-console-minio1.ingress.kubo6.mbp` with your MinIO console entry point
- Replace `kubauth.ingress.kubo6.mbp` with your Kubauth entry point
- The `claim_name` specifies the JWT claim MinIO uses to identify the policies to attach to the authenticated user. 
  The claim can contain one or more comma-separated policy names to attach to the user. 
  The claim must contain at least one policy for the user to have any permissions on the MinIO server. The default value is `policy`, 
  but we set it to `minio_policies` to be more specific and highlight that it can be a list.

The server needs to be restarted after this configuration:

``` { .bash .copy }
mc admin service restart myminio
```

!!! tip

    This configuration can also be achieved using environment variables. Refer to the MinIO documentation.


## Usage

After this configuration, a `KUBAUTH` button should appear on the MinIO console login page.

If you try to log in using a valid OIDC user, you should receive an error such as:<br> `minio_policies claim missing from the JWT token, credentials will not be generated`

To be able to log in to the Console with full admin rights, the easiest solution is to associate the existing `consoleAdmin` policy to the user by setting it in the `minio_policies` claim.

This can be achieved by adding the claim to the user definition:


``` { .yaml .copy }
.......
---
apiVersion: kubauth.kubotal.io/v1alpha1
kind: User
metadata:
  name: john
  namespace: kubauth-users
spec:
  ......
  claims:
    office: 208G
    minio_policies: consoleAdmin
  ......
```

> This will also work if the user's primary source is another identity provider, such as LDAP. See [Identity merging](../30-user-guide/190-identity-merging.md).

However, a cleaner approach is to use an intermediate Group to simplify management.

Create a `minio-admins` group with the appropriate claim:

``` { .bash .copy }
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
```

Add a user to this newly created group:


``` { .bash .copy }
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
```

Now, `john` can log in as a full MinIO administrator.


