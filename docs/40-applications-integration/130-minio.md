# MinIO integration

!!! Warning

    At the time of writing this manuel, there is some change on the way MinIO is distributed.

    The configuration provided here is validated on the the latest OSS MinIO version integrating a fully functional Console Admin.

    It should also apply on MinIO AIStor, the proprietary version of MinIO.

## Oidc client creation

As stated in [Configuration](../30-user-guide/110-configuration.md/#oidc-client-creation), a client application is defined as a Kubernetes Custom Resource.

So, a manifest like the following should be created:

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
      displayName: Minio
      description: S3 Server
      entryURL: "https://minio-console-minio1.ingress.kubo6.mbp"
    ```


- `minio-console-minio1.ingress.kubo6.mbp` must be replaced by your MinIO console entry point (In 2 locations)
- The sample password is 'minio123'. Thus, the `hashedSecret` value is the result of a <br>`kc hash minio123` command.
- `scopes` contains `address` and `phone`. This seems to be required by MinIO default configuration.
- `displayName`, `description` and `entryURL` attributes are optionals. Aim is to integrate MinIO in a list of available applications. 
  This list will be displayed on a specific page (`https://kubauth.ingress.kubo6.mbp/index`) or an the Logout page.

Apply this manifest:

``` { .bash .copy }
kubectl apply -f client-minio.yaml
```

## Minio Configuration

We will assume here you have a fully functional MinIO deployment.

We also assume you have an `mc` command configured with an alias (`myminio` below) granting full admin rights.

One method to configure an OIDC connection for minio is by issuing a specific command:


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

- `minio-console-minio1.ingress.kubo6.mbp` must be replaced by your MinIO console entry point
- `kubauth.ingress.kubo6.mbp` must be replaced by your Kubauth entry point.
- The `claim_name` Specify the name of the JWT Claim MinIO uses to identify the policies to attach to the authenticated user. 
  The claim can contain one or more comma-separated policy names to attach to the user. 
  The claim must contain at least one policy for the user to have any permissions on the MinIO server. Defaults value is `policy`, 
  but we set it to `minio_policies` to be more specific and highlight it can be a list. 

The server need to be restarted after this setting:

``` { .bash .copy }
mc admin service restart myminio
```

## Usage

After this configuration, a button `KUBAUTH` must appear on the MinIO console login page.

It you try to log in, using a valid OIDC user, you should have an error such as:<br> `Minio_policies claim missing from the JWT token, credentials will not be generated`

To be able to login on the Console with full admin rights, the easiest solution is to associate the existing policy `consoleAdmin` to the user by setting it in the claim `minio_policies`.

This can be achieved by adding the claim in the user definition:


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

> This will also works if the user's primary source is another identity provider, such as LDAP. See [Identity merging](../30-user-guide/190-identity-merging.md)

But, another, cleaner way is to use an intermediate Group to ease management.

Create a group `minio-admins` with the appropriate Claim:

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

And set a user in this newly create group:


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


