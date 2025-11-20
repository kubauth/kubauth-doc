# Workstation setup


## kubelogin installation

On the `kubectl` client side, we will use the [kubelogin](https://github.com/int128/kubelogin) kubectl plugin to manage user authentication.

To install it, from the Kubelogin README:

Install the latest release from Homebrew, Krew, Chocolatey or GitHub Releases.

```
# Homebrew (macOS and Linux)
brew install kubelogin

# Krew (macOS, Linux, Windows and ARM)
kubectl krew install oidc-login

# Chocolatey (Windows)
choco install kubelogin
```

If you install via GitHub releases, save the binary as the name `kubectl-oidc_login` on your path. When you invoke kubectl oidc-login,
kubectl finds it by the naming convention of kubectl plugins. The other install methods do this for you.

Next step would be to setup your local `kubeconfig`. Kubauth provide a tool to automate this tedious task.

## Configuration

The [`kc` CLI](../20-installation.md#kc-cli-tool-installation) tool provide a subcommand aimed to setup your local kubeconfig from the service we previously installed:

``` { .bash .copy}
kc config https://kubeconfig.ingress.kubo6.mbp/kubeconfig
```

> Of course, adjust the URL to your local context, but keep the `/kubeconfig` path

You should see a message like the following 

```bash
Setup new context 'oidc-kubo6' in kubeconfig file '/Users/john/.kube/config'
```

!!! Notes

    If such a context already exists in you config file, it will not be overwritten and you will get an error message. Use the `--force` option to override.


!!! tip

    If you encounter an error like `tls: failed to verify certificate: x509:...`, the CA associated with your ClusterIssuer is not recognized on your local workstation.

    - Add the `--insecureSkipVerify` option to the `kc config` command. You will also need to configure your browser to accept the certificate.
    - Add the CA as a trusted certificate on your local workstation. You can extract it with:
      ``` { .bash .copy }
      kubectl -n kubauth get secret kubauth-oidc-server-cert \
        -o=jsonpath='{.data.ca\.crt}' | base64 -d >./ca.crt 
      ```




For information, here is a sample of a local config file resulting of this operation

???- abstract "config.yaml"

    ``` { .yaml .copy }
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: LS0tLS1CRUdJTi........FUlRJRklDQVRFLS0tLS0K
        server: https://127.0.0.1:5452
      name: oidc-kubo6-cluster
    contexts:
    - context:
        cluster: oidc-kubo6-cluster
        user: oidc-kubo6-user
      name: oidc-kubo6
    current-context: oidc-kubo6
    kind: Config
    users:
    - name: oidc-kubo6-user
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1
          args:
          - oidc-login
          - get-token
          - --oidc-issuer-url=https://kubauth.ingress.kubo6.mbp
          - --oidc-client-id=k8s
          - --oidc-client-secret=k8s123
          - --certificate-authority-data=LS0tLS1CR.........tRU5EIENFUlRJRklDQVRFLS0tLS0=
          - --insecure-skip-tls-verify=false
          - --grant-type=auto
          - --oidc-extra-scope=offline
          - --oidc-pkce-method=auto
          command: kubectl
          env: null
          interactiveMode: IfAvailable
          provideClusterInfo: false
    ```


## First login attempt

You can now issue a kubectl command to trigger an authentication:

``` { .bash .copy}
kubectl explain pods
```

Your browser should open on the kubauth login page. Once logged, this operation will complete successfully, as it does not require any specific permissions.

```bash
KIND:       Pod
VERSION:    v1

DESCRIPTION:
    Pod is a collection of containers that can run on a host. This resource is
    created by clients and scheduled onto hosts.
.....
```

No, try another request:

``` { .bash .copy}
kubectl get ns
```

This time, you will get an error, as such operation require some Kubernetes permissions.

```bash
Error from server (Forbidden): namespaces is forbidden: User "john" cannot list resource "namespaces" in API group "" at the cluster scope
```

But, you can check you are authenticated with the user you use on the login page.

Another way to find out who we are is the use the following `kc` subcommand:

``` { .bash .copy}
kc whoami
```
```bash
john
```
You can also have more information by using an option to dump the JWT token:

```{ .bash .copy}
kc whoami -d
```
```json
john
JWT Payload:
{
  "accessProfile": "p24x7",
  "at_hash": "xevWqv4MaZ_ft1nYs-wCcg",
  "aud": [
    "k8s"
  ],
  "auth_time": 1763573723,
  "auth_time_human": "2025-11-19 17:35:23 UTC",
  "authority": "ucrd",
  .....
}
```

## Session duration

You may also notice the system does not required authentication on each call, but manage some kind of session.

Remember the end of [Kubauth OIDC client creation](../50-kubernetes-integration/110-introduction.md#oidc-client-creation) 

```
  ....
  accessTokenLifespan: 1m0s
  idTokenLifespan: 1m0s
  refreshTokenLifespan: 30m0s
```

- On initial login, the server grant a token with a lifespan of `1mn`, and a renewal token
- During this minute, all operation will be performed without OIDC interaction.
- After this duration, if the refresh token is not expired, the API server use it to get a new token of `1mn` and a new refresh token.

As a result, in this configuration, the session will expire after `30mn` of inactivity.

## logout

If you need to cancel a session before this timeout (For example to login under another account), you can issue the following command:

```
kc logout
```

This will perform two actions:

- Cleanup the local storage.
- Launch a browser on the Kubauth OIDC server end of session endpoint, to cleanup eventual SSO session.

!!! notes

    If you remember the usage of `kc logout` in the [SSO chapter](../30-user-guide/140-sso.md#logout), you may notice there is no more <br>`--issuerURL` nor `--clientId` option.
    This because the `kc` command fetch these information from your local kubernetes config file.

## Granting rights using k8s RBAC

Let's say we want the user `john` to have full admin rights on the cluster.

First, we will include it in a group `cluster-admin`

```{ .bash .copy }
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
```

> Remember in our context, the simple fact a group is referenced in a `GroupBinding` make it existing.

In our cluster, there is an existing role `cluster-admin`. We must bind our newly created group to this role:

``` { .bash .copy }
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: oidc-cluster-admin
EOF
```

> Note the group is referenced here as `oidc-cluster-admin`. This because a `groupsPrefix: "oidc-"` has been set in OIDC configuration.

After executing these two scripts `kubectl get ns` should display the list of your cluster's namespaces 

> Of course, if you where already logged in, you must logout.

!!! Note

    Setting a `groupPrefix` is a requirement in OIDC configuration, enforced by the API server for security reason. Otherwise any user able to create a `GroupBinding` 
    resource could bind any user to a `system:master` existing group. 

## No UI mode

There is some case where launching a browser is impossible. For example when working on a server accessed through ssh.

We can set a 'no browser' mode when configuring your client, with the `--grantType password` option:

``` { .bash .copy }
kc config https://kubeconfig.ingress.kubo6.mbp/kubeconfig --grantType password
```

> Add `--force` to override an old configuration if needed.

!!! Warning

    This mode will use the OAuth's Resource Owner Password Credentials (ROPC) grant type. this implies the OIDC server must be configured to allow this mode. 
    See [Password Grant](../30-user-guide/160-password-grant.md#configuration) chapter 

With this configuration, user will be prompted on the terminal for its login/password:

``` { .bash .copy }
kubectl get ns
```
```
Username: john
Password:
```
```
NAME                 STATUS   AGE
cert-manager         Active   27d
default              Active   27d
flux-system          Active   27d
ingress-nginx        Active   27d
kubauth              Active   32h
........
```











