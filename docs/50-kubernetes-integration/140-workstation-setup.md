# Workstation Setup


## kubelogin Installation

On the `kubectl` client side, we will use the [kubelogin](https://github.com/int128/kubelogin) kubectl plugin to manage user authentication.

To install it, from the Kubelogin README:

Install the latest release from Homebrew, Krew, Chocolatey, or GitHub Releases.

```
# Homebrew (macOS and Linux)
brew install kubelogin

# Krew (macOS, Linux, Windows and ARM)
kubectl krew install oidc-login

# Chocolatey (Windows)
choco install kubelogin
```

If you install via GitHub releases, save the binary as `kubectl-oidc_login` on your path. When you invoke `kubectl oidc-login`, kubectl finds it by the naming convention for kubectl plugins. The other installation methods do this for you.

The next step is to configure your local `kubeconfig`. Kubauth provides a tool to automate this task.

## Configuration

The [`kc` CLI](../20-installation.md#kc-cli-tool-installation) tool provides a subcommand to configure your local kubeconfig from the service we previously installed:

``` { .bash .copy}
kc config https://kubeconfig.ingress.kubo6.mbp/kubeconfig
```

> Adjust the URL to your local environment, but keep the `/kubeconfig` path.

You should see a message like the following:

```bash
Setup new context 'oidc-kubo6' in kubeconfig file '/Users/john/.kube/config'
```

!!! note

    If such a context already exists in your config file, it will not be overwritten and you will receive an error message. Use the `--force` option to override.


!!! tip

    If you encounter an error like `tls: failed to verify certificate: x509:...`, the CA associated with your ClusterIssuer is not recognized on your local workstation.

    - Add the `--insecureSkipVerify` option to the `kc config` command. You will also need to configure your browser to accept the certificate.
    - Add the CA as a trusted certificate on your local workstation. You can extract it with:
      ``` { .bash .copy }
      kubectl -n kubauth get secret kubauth-oidc-server-cert \
        -o=jsonpath='{.data.ca\.crt}' | base64 -d >./ca.crt 
      ```




For reference, here is a sample local config file resulting from this operation:

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


## First Login Attempt

You can now issue a kubectl command to trigger authentication:

``` { .bash .copy}
kubectl explain pods
```

Your browser should open to the Kubauth login page. Once logged in, this operation will complete successfully, as it does not require any specific permissions.

```bash
KIND:       Pod
VERSION:    v1

DESCRIPTION:
    Pod is a collection of containers that can run on a host. This resource is
    created by clients and scheduled onto hosts.
.....
```

Now, try another request:

``` { .bash .copy}
kubectl get ns
```

This time, you will receive an error, as such an operation requires Kubernetes permissions.

```bash
Error from server (Forbidden): namespaces is forbidden: User "john" cannot list resource "namespaces" in API group "" at the cluster scope
```

However, you can verify that you are authenticated with the user you used on the login page.

Another way to determine your identity is to use the following `kc` subcommand:

``` { .bash .copy}
kc whoami
```
```bash
john
```
You can also obtain more information by using an option to dump the JWT token:

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

## Session Duration

You may notice that the system does not require authentication for each call, but manages some form of session.

Recall the end of [Kubauth OIDC client creation](../50-kubernetes-integration/110-overview.md#oidc-client-creation):

```
  ....
  accessTokenLifespan: 1m0s
  idTokenLifespan: 1m0s
  refreshTokenLifespan: 30m0s
```

- On initial login, the server grants a token with a lifespan of 1 minute and a refresh token.
- During this minute, all operations are performed without OIDC interaction.
- After this duration, if the refresh token has not expired, the API server uses it to obtain a new 1-minute token and a new refresh token.

As a result, in this configuration, the session will expire after 30 minutes of inactivity.

## Logout

If you need to cancel a session before this timeout (for example, to log in as a different user), you can issue the following command:

```
kc logout
```

This performs two actions:

- Cleans up the local storage.
- Launches a browser to the Kubauth OIDC server's end-of-session endpoint to clear any SSO session.

!!! note

    If you recall the usage of `kc logout` in the [SSO chapter](../30-user-guide/140-sso.md#logout), you may notice there is no longer a `--issuerURL` or `--clientId` option. This is because the `kc` command fetches this information from your local Kubernetes config file.

## Granting Rights Using Kubernetes RBAC

Let's say we want the user `john` to have full admin rights on the cluster.

First, we will add them to a `cluster-admin` group:

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

> Remember, in our context, simply referencing a group in a `GroupBinding` makes it exist.

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

> Note the group is referenced here as `oidc-cluster-admin`. This is because `groupsPrefix: "oidc-"` was set in the OIDC configuration.

After executing these two scripts, `kubectl get ns` should display the list of your cluster's namespaces.

> Of course, if you were already logged in, you must log out first.

!!! note

    Setting a `groupsPrefix` is a requirement in OIDC configuration, enforced by the API server for security reasons. Otherwise, any user able to create a `GroupBinding` resource could bind any user to an existing `system:masters` group.

## No UI Mode

There are cases where launching a browser is impossible, such as when working on a server accessed through SSH.

We can configure a 'no browser' mode when setting up your client, using the `--grantType password` option:

``` { .bash .copy }
kc config https://kubeconfig.ingress.kubo6.mbp/kubeconfig --grantType password
```

> Add `--force` to override an existing configuration if needed.

!!! warning

    This mode uses OAuth's Resource Owner Password Credentials (ROPC) grant type. This requires the OIDC server to be configured to allow this mode. See the [Password Grant](../30-user-guide/160-password-grant.md#configuration) chapter.

With this configuration, users will be prompted on the terminal for their login and password:

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












