# Customizing the Login UI

Kubauth ships with a small, self-contained set of HTML templates and CSS that drive the **login**, **index** and **upstream welcome** pages. This chapter explains how to customize those pages — from simple color tweaks to a full layout rewrite — and how to deploy the result through the Helm chart.

## Overview

The OIDC server renders three HTML pages, all served on the OIDC issuer URL:

| URL                    | Template                           | Purpose                                                                                        |
|------------------------|------------------------------------|------------------------------------------------------------------------------------------------|
| `/oauth2/auth/...`     | `templates/login.gohtml`           | Login page: user/password form and/or upstream provider buttons.                               |
| `/index`               | `templates/index.gohtml`           | Index page listing every OIDC client whose [`displayName`, `description`, `entryURL`](115-oidc-clients-configuration.md) are set. Also the post-logout landing page. |
| `/upstream/welcome`    | `templates/upstream-welcome.gohtml`| "Remember me" confirmation page shown after authenticating through an external upstream provider, when [`oidc.sso.mode: onDemand`](140-sso.md). |

All three templates pull their CSS from:

```
/static/shared.css        ← color variables + base styles for body, container, form, btn, footer, ...
/static/index.css         ← layout for the application grid
/static/login.css         ← layout for the login form and upstream buttons
```

Inside Kubauth, those files live under the **resources folder** declared by the `--resources` flag (Helm value [`oidc.server.resourcesFolder`](210-helm-chart.md#oidc-module-oidc), default `resources`):

```
resources/
├── static/
│   ├── favicon.ico
│   ├── shared.css
│   ├── index.css
│   └── login.css
└── templates/
    ├── login.gohtml
    ├── index.gohtml
    └── upstream-welcome.gohtml
```

Both `/static/<file>` URLs and the templates are served by a single HTTP handler tree, so the layout above is fixed — file names and subfolder names must match exactly.

### How Themes Work

`shared.css` defines two themes through CSS custom properties:

```css
:root {
    /* dark theme variables (used when no class is set on <html>) */
    --color-bg-body:   #1a1a1a;
    --color-text:      #e0e0e0;
    /* ... */
}

html.theme-light {
    /* light theme overrides */
    --color-bg-body:   #f4f4f5;
    --color-text:      #27272a;
    /* ... */
}
```

The active theme is selected by the [`OidcClient.spec.style`](../60-references/110-oidcclient.md#style) field — or, in its absence, by the Helm value [`oidc.defaultStyle`](210-helm-chart.md#oidcdefaultstyle). The three templates render the corresponding class on the `<html>` element:

```html
<html lang="en"{{if eq .Style "light"}} class="theme-light"{{end}}>
```

Out of the box only `dark` and `light` are recognized. Any other value falls back to dark (no class on `<html>`).

## Choosing a Customization Path

You have two options depending on how deep your changes go:

| Goal                                                                           | Path                                                                       |
|--------------------------------------------------------------------------------|----------------------------------------------------------------------------|
| Re-skin the existing dark or light theme (different brand colors, rounded corners, custom font, …) | [Path A — CSS-only tweak](#path-a-css-only-tweak)                          |
| Add an extra named theme (e.g. `corporate`), restructure the page, change copy, add an extra field, … | [Path B — Replace the resources folder](#path-b-replace-the-resources-folder) |

Path A is a runtime overlay — no image rebuild, no new artifact in your registry. Path B requires building a thin custom image. Pick the lightest one that fits your scope.

## Path A — CSS-Only Tweak

For brand color, font and minor visual changes you only need to override the files under `/resources/static/`. The templates and the rest of the image stay untouched.

The `oidc.extraConfigMaps` Helm value mounts a ConfigMap as a regular directory at a path of your choice. Mounting it at `/resources/static/` **hides the baked-in `static/` folder** behind the ConfigMap's contents — exactly what we want.

#### Caveat

Kubernetes mounts a ConfigMap as the **whole directory**, not file-by-file. So the ConfigMap must contain every file the templates load from `/static/`:

| File              | Required? | Comment                                              |
|-------------------|-----------|------------------------------------------------------|
| `shared.css`      | yes       | The file you actually want to override.              |
| `index.css`       | yes       | Referenced from `/index`. Copy the upstream version. |
| `login.css`       | yes       | Referenced from the login page and welcome page.     |
| `favicon.ico`     | yes       | Served at `/favicon.ico`.                            |

If any one of these is missing, the corresponding HTTP request returns 404 and the affected page renders unstyled.

#### Recipe

1. **Fork `shared.css`** and edit it:

    ```bash
    mkdir -p custom-static
    curl -L -o custom-static/shared.css \
      https://raw.githubusercontent.com/kubauth/kubauth/main/resources/static/shared.css

    # Edit custom-static/shared.css and tweak --color-bg-body, --btn-bg, etc.
    ```

2. **Pull the unchanged static files** so the ConfigMap is complete:

    ```bash
    for f in index.css login.css favicon.ico ; do
      curl -L -o custom-static/$f \
        https://raw.githubusercontent.com/kubauth/kubauth/main/resources/static/$f
    done
    ```

3. **Build the ConfigMap.** Use `kubectl create configmap --from-file` so the file names become the ConfigMap keys verbatim. `favicon.ico` is binary, so pass it via `--from-file` as well — `kubectl` will store it under `binaryData` automatically:

    ```bash
    kubectl -n kubauth create configmap kubauth-ui-static \
      --from-file=shared.css=custom-static/shared.css \
      --from-file=index.css=custom-static/index.css \
      --from-file=login.css=custom-static/login.css \
      --from-file=favicon.ico=custom-static/favicon.ico \
      --dry-run=client -o yaml | kubectl apply -f -
    ```

    Or declaratively:

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kubauth-ui-static
      namespace: kubauth
    data:
      shared.css: |
        :root {
            --color-bg-body: #003366;
            --btn-bg:        #ff6f00;
            /* ... your overrides ... */
        }
        /* ... rest of the upstream shared.css ... */
      index.css: |
        /* unchanged upstream content */
      login.css: |
        /* unchanged upstream content */
    binaryData:
      favicon.ico: <base64-encoded bytes>
    ```

4. **Tell Helm to mount it** through `oidc.extraConfigMaps`:

    ```yaml
    oidc:
      extraConfigMaps:
        - name: ui-static                    # arbitrary; becomes the Volume name
          mountPath: /resources/static       # replaces the image's /resources/static folder
          configMapName: kubauth-ui-static   # must match the ConfigMap you just created
    ```

5. **Upgrade**:

    ```bash
    helm upgrade --install -n kubauth \
      kubauth oci://quay.io/kubauth/charts/kubauth \
      --version 0.3.0 \
      --values values.yaml
    ```

When the new pod is `READY`, hard-reload the login or `/index` page (`Cmd/Ctrl+Shift+R`) to bypass the browser cache.

#### Rolling back

Either drop the `extraConfigMaps` entry from `values.yaml` and re-upgrade, or simply delete the ConfigMap and re-create the Deployment's pod:

```bash
kubectl -n kubauth delete configmap kubauth-ui-static
helm upgrade ...   # without the extraConfigMaps entry
```

The pod restarts on the baked-in `/resources/static/` and you are back on the stock theme.

!!! warning "ConfigMap size limit"

    A Kubernetes ConfigMap is capped at **1 MiB** of serialized data. The default Kubauth `favicon.ico` is ~15 kB and the three CSS files together are ~5 kB, so there is plenty of headroom. If you replace `favicon.ico` with a high-resolution PNG sprite or ship a heavy webfont, watch the limit — and at that point switch to [Path B](#path-b-replace-the-resources-folder), which bakes the assets into the image.

## Path B — Replace the Resources Folder

When you need to change the page structure (new copy, extra form fields, a corporate logo, a fully different theme, custom JavaScript, …), bring your own complete `resources/` folder.

### 1. Duplicate the Upstream Tree

```bash
git clone --depth 1 --branch v0.3.0 https://github.com/kubauth/kubauth.git /tmp/kubauth
cp -r /tmp/kubauth/resources ./custom/resources
```

You now have a writable copy of every file Kubauth needs at runtime.

### 2. Modify Templates and Static Files

Edit `custom/resources/templates/*.gohtml` and `custom/resources/static/*.css` to your liking. The data model exposed to each template is described in [Template Data Models](#template-data-models) below — anything outside those models cannot be referenced from the template.

A few constraints:

- The three templates **must** be named `login.gohtml`, `index.gohtml`, `upstream-welcome.gohtml`. Renaming them breaks the boot of the OIDC server.
- The HTTP server always serves `<resourcesFolder>/static/` under the `/static/` URL prefix. Use that prefix in any `<link rel="stylesheet" href="...">` / `<script src="...">` you add.
- Static URLs are served as-is; you can freely add subfolders (`/static/img/logo.svg`, `/static/fonts/...`) — they will just appear under `/static/img/...` / `/static/fonts/...`.

#### Adding an Extra Named Theme

To support an additional named style (say `corporate`) on top of `dark` and `light`:

1. Add the variable block in `shared.css`:

    ```css
    html.theme-corporate {
        --color-bg-body: #003366;
        --btn-bg:        #ff6f00;
        /* ... override the variables you need ... */
    }
    ```

2. Update each template to map `Style` to a class:

    ```html
    <html lang="en"{{if ne .Style "dark"}} class="theme-{{ .Style }}"{{end}}>
    ```

    The conditional keeps the `:root` (default = dark) for any value of `Style` equal to `dark` or empty, and emits `class="theme-<style>"` for everything else.

3. Set the new theme on a per-client basis:

    ```yaml
    apiVersion: kubauth.kubotal.io/v1alpha1
    kind: OidcClient
    metadata:
      name: corporate-portal
      namespace: kubauth
    spec:
      style: corporate
      # ...
    ```

    Or globally via Helm:

    ```yaml
    oidc:
      defaultStyle: corporate
    ```

### 3. Build the Image

Bake your custom tree into a thin image based on the stock one:

```dockerfile
# Dockerfile
FROM quay.io/kubauth/exec/kubauth:0.3.0

COPY resources/ /resources-custom/
```

```bash
docker build -t registry.example.com/kubauth-custom:0.3.0 .
docker push registry.example.com/kubauth-custom:0.3.0
```

### Patterns for Building the Image

The kubauth binary takes `--resources <path>` and reads `static/` and `templates/` from there. There are two practical ways to ship a custom set:

1. **Side-by-side image** (recommended). Start `FROM quay.io/kubauth/exec/kubauth:<version>`, copy your tree into a **new** path (e.g. `/resources-custom/`), and set [`oidc.server.resourcesFolder: /resources-custom`](210-helm-chart.md#oidc-module-oidc). The upstream `/resources/` is still present in the image, which makes it trivial to A/B between the stock and custom UI: a single value change in `values.yaml` switches back. Your custom tree **must contain every template and every static file referenced by the templates** — the server reads from one folder only and does not merge with `/resources/`.
2. **Overlay on top of `/resources/`**. Start `FROM` upstream and `COPY my-overrides/ /resources/`. Docker merges into the existing directory, so any file you do not override is taken from the base image. You only ship what you actually changed, and `oidc.server.resourcesFolder` stays at its default (`resources`). Rollback means switching back to the stock image tag.

Pattern 1 is the safest default. Pattern 2 is the right pick when you only modify a couple of files and want the smallest possible diff in your image.

## Template Data Models

Every template receives a single Go struct. The fields available are listed below — anything that is not in the model cannot be referenced from the template.

### `login.gohtml` — `LoginModel`

Rendered for the login page (`/oauth2/auth/...`). Source: [`cmd/oidc/oidcserver/display-login.go`](https://github.com/kubauth/kubauth/blob/main/cmd/oidc/oidcserver/display-login.go){:target="_blank"}.

#### `.Style`

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Style name to apply, as defined on the targeted `OidcClient` or by `oidc.defaultStyle`. Use it on the `<html>` element to pick a theme.

<hr class="api-field-separator">

#### `.Version`, `.BuildTs`

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Kubauth version and build timestamp. The stock template surfaces them in a fixed footer at the bottom of the viewport.

<hr class="api-field-separator">

#### `.InvalidLogin`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
</p>

`true` when the form was just submitted with an invalid login/password pair. The stock template uses this to display an inline error.

<hr class="api-field-separator">

#### `.ShowLoginForm`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
</p>

`true` when an `internal` upstream provider is configured for this client (or no provider is configured at all). Toggle the visibility of the user/password form on this flag.

<hr class="api-field-separator">

#### `.FieldsetLabel`

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Label to render above the login form. Comes from the `internal` UpstreamProvider's `displayName` when one is defined, otherwise from the Helm value `oidc.defaultLoginLabel` (defaults to `Welcome`). When the value is `"--"`, the stock template hides the legend entirely.

<hr class="api-field-separator">

#### `.ShowSsoCheck`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
</p>

`true` when [`oidc.sso.mode: onDemand`](140-sso.md). Use it to render the "Remember Me" checkbox only when SSO is opt-in.

<hr class="api-field-separator">

#### `.UpstreamButtons`

<p class="api-meta">
<span class="api-badge api-type">[]UpstreamButtonModel</span>
</p>

Non-internal upstream providers to render as one button each. The list is empty when no external providers apply to the current client. Each entry has:

| Field         | Type   | Meaning                                                              |
|---------------|--------|----------------------------------------------------------------------|
| `Name`        | string | `metadata.name` of the `UpstreamProvider` (used in the redirect URL).|
| `DisplayName` | string | Label to render on the button.                                       |

The standard button target is:

```html
<a href="/upstream/go?upstreamProvider={{.Name}}">{{.DisplayName}}</a>
```

<hr class="api-field-separator">

#### `.ShowNoProviderMessage`

<p class="api-meta">
<span class="api-badge api-type">bool</span>
</p>

`true` only when there is **nothing** to show on the login page — no internal form, no upstream button. Render an explanatory message and a hint to contact the cluster administrator.

### `index.gohtml` — Index Page

Rendered for `/index` and for the post-logout landing page. Source: [`cmd/oidc/oidcserver/handle-index.go`](https://github.com/kubauth/kubauth/blob/main/cmd/oidc/oidcserver/handle-index.go){:target="_blank"} (look at the anonymous struct around line 63).

#### `.Style`, `.Version`, `.BuildTs`

Same semantics as in `LoginModel` (theme, version, build timestamp).

<hr class="api-field-separator">

#### `.Entries`

<p class="api-meta">
<span class="api-badge api-type">[]indexEntry</span>
</p>

One entry per OIDC client whose `displayName` **and** `entryURL` are non-empty (clients with only one of the two are skipped). Sorted alphabetically by `DisplayName`, then by `EntryURL`. When the list is empty the stock template renders a "Bye!" page used after logout. Each entry has:

| Field         | Type   | Meaning                                                                                            |
|---------------|--------|----------------------------------------------------------------------------------------------------|
| `DisplayName` | string | `OidcClient.spec.displayName`.                                                                     |
| `Description` | string | `OidcClient.spec.description` (may be empty).                                                      |
| `EntryURL`    | string | `OidcClient.spec.entryURL` — the URL the user is sent to when clicking the card.                  |

See [OidcClient Reference](../60-references/110-oidcclient.md#displayname) for the source fields.

### `upstream-welcome.gohtml` — `UpstreamWelcomeModel`

Rendered for `/upstream/welcome` after a successful upstream authentication, only when [`oidc.sso.mode: onDemand`](140-sso.md) (in `always` mode the SSO cookie is set unconditionally and this page is skipped; in `never` mode the SSO is disabled entirely). Source: [`cmd/oidc/oidcserver/handle-upstream-welcome.go`](https://github.com/kubauth/kubauth/blob/main/cmd/oidc/oidcserver/handle-upstream-welcome.go){:target="_blank"}.

#### `.Style`, `.Version`, `.BuildTs`

Same semantics as in `LoginModel` (theme, version, build timestamp).

<hr class="api-field-separator">

#### `.UserName`

<p class="api-meta">
<span class="api-badge api-type">string</span>
</p>

Human-readable identifier of the user as derived from the upstream claims. Picked in this order: `FullName`, then claims `name`, `preferred_username`, `nickname`, `email`, then `given_name family_name`, falling back to the bare login. May be empty in pathological cases (use a fallback in the template).

The page has a single form posting to `/upstream/welcome`:

```html
<form method="POST" action="/upstream/welcome">
  <input type="checkbox" name="remember">
  <button type="submit">Continue</button>
</form>
```

When the checkbox is ticked, Kubauth persists the SSO session for the user.

## Deploying the Customized Image

Once your custom image is built and pushed, point the Helm chart at it:

```yaml
oidc:
  image:
    repository: registry.example.com/kubauth-custom
    tag: "0.3.0"        # use your own versioning scheme

  server:
    # Required when you used the recommended overlay pattern.
    # Path must match the COPY destination in your Dockerfile.
    resourcesFolder: /resources-custom
```

Then upgrade:

```bash
helm upgrade --install -n kubauth \
  kubauth oci://quay.io/kubauth/charts/kubauth \
  --version 0.3.0 \
  --values values.yaml
```

When the new pod is `READY`, hard-reload your browser (`Cmd/Ctrl+Shift+R`) to bypass CSS caches and verify the rendering on `/index`, on a client's login page, and on `/upstream/welcome`.

### Rolling Back

The customization lives entirely in the image and the `oidc.server.resourcesFolder` value. To revert:

```yaml
oidc:
  image:
    repository: quay.io/kubauth/exec/kubauth   # stock image
    tag: ""                                     # back to chart appVersion default
  server:
    resourcesFolder: resources                  # stock layout
```

Then re-run the same `helm upgrade`.

## Troubleshooting

### The new CSS does not show up

The browser aggressively caches `/static/*.css`. Force a hard reload (`Cmd/Ctrl+Shift+R`) or open a private window.

If the file is missing entirely (404 in the DevTools network panel), the `oidc.server.resourcesFolder` value points to a directory that does not contain a `static/<file>.css`. Double-check the `COPY` destination in your Dockerfile vs the Helm value.

### Pod fails to start with `template: ... no such file or directory`

The OIDC server panics at boot when one of the three templates cannot be loaded. Confirm that **all three** of `login.gohtml`, `index.gohtml` and `upstream-welcome.gohtml` are present under `<resourcesFolder>/templates/`.

```bash
kubectl -n kubauth logs deployment/kubauth -c oidc | head -20
```

### `template: <name>:N: function "..." not defined`

You used a function or method in your template that is not available. Go's `html/template` only exposes built-in functions plus those registered by the application; Kubauth does not register any extras. Stick to the built-ins (`if`, `range`, `with`, `eq`, `ne`, `printf`, …) and to the methods and fields exposed by the model.

### Adding new dynamic data (claim, group, …) to a template

The data models above are fixed — they cannot be extended from outside the binary. If you need to surface additional information (e.g. a tenant logo, a custom slogan from a ConfigMap), inject it at template-render time by adding a small build of Kubauth from source, or hand the data through a side-channel like a separately served static JSON file fetched by JavaScript in the template.

## See Also

- [Helm Chart Reference › `oidc.server.resourcesFolder`](210-helm-chart.md#oidc-module-oidc)
- [Helm Chart Reference › `oidc.defaultStyle`](210-helm-chart.md#oidcdefaultstyle)
- [OIDC Clients Configuration › `style`](115-oidc-clients-configuration.md)
- [OidcClient Reference › `style`](../60-references/110-oidcclient.md#style)
- [SSO Session](140-sso.md) — when `upstream-welcome.gohtml` is rendered
- [Upstream Providers](200-upstream-providers.md) — feeds the `UpstreamButtons` list
- Kubauth source: [`resources/`](https://github.com/kubauth/kubauth/tree/main/resources){:target="_blank"}, [`cmd/oidc/oidcserver/`](https://github.com/kubauth/kubauth/tree/main/cmd/oidc/oidcserver){:target="_blank"}
