
This is a technical documentation about an OIDC server named Kubauth.
Built with mkdocs with some extension.
It has been written in poor globish by a French native.
Could you rewrite 20-installation.md in correct technical english.
Don't touch the remaining of the manuel for now.

Now, rewrite index.md

Now, rewrite all files in 30-user-guide folder

Now, rewrite all files in 40-applications-integration folder

Now, rewrite all files in 50-kubernetes-integration folder

Now, rewrite all files in 70-appendix folder

In 60-reference folder, write the reference part for CRD OidcClient, User, GroupBinding and Group. This from source code at https://github.com/kubauth/kubauth/tree/main/api/kubauth/v1alpha1.

Update mkdocs.yml accordingly

In the 70-kc folder, add an overview about kc CLI executable and a page for each of the kc subcommand.  Source is https://github.com/kubauth/kc


The kc token doc mention a --redirectURL option which does not seems to exists

Could you check for all subcommand that all options you documented really exists.

You removed existing options. Please check the SOURCE CODE


Seems too verbose. Focus on essential



This is a technical documentation about an OIDC server named Kubauth.
Built with mkdocs with some extension, in docs folder
It has been written in poor globish by a French native.
It has been rewritten by AI in a previous version
Could you check and rewrite all modification since tag v0.1.2

------
Opus 4.7

This is a technical documentation about an OIDC server named Kubauth (https://github.com/kubauth/kubauth)
Built with mkdocs with some extension, in docs folder
There is also a companion CLI tool named 'kc' (https://github.com/kubauth/kc), described in this doc.
This tool has evolved in version/branch v0.2.1. Update the doc accordingly


This is a technical documentation about an OIDC server named Kubauth (https://github.com/kubauth/kubauth)
Built with mkdocs with some extension, in docs folder
Documentation is in sync with version 0.2.1. Could you update the 30-user-guide part with all modification from the current 0.3.0 branch
Beside kubauth repo, you can grab information from the CHANGELOG.md file

In the 110-usersconfiguration, can you add a small description of the kubauth-users helm chart, the same way you did for the kubauth-upstream-providers.

Now, update the 20-installation.md chapter

Now, update the 60-references part

Now, update the 40-application-integration and 50-kubernetes integration, if needed

kubauth-kit repo is now archived. Replaced by kubauth-apiserver and kubauth-kubeconfig. Update links accordingly.


---------
This doc is in sync with
- kubauth:
  commit 9d34caab2231a4326485b2fcd7cf8d77e203a9f4 (HEAD -> v0.3.0, origin/v0.3.0)
  Author: Serge ALEXANDRE <serge.alexandre@kubotal.io>
  Date:   Fri May 22 19:26:32 2026 +0200

  feat(ingress): Non-passthrough mode with SSL backend is now also supported with HAProxy
- kc:
  commit 1d9e60e43e06df8b8383b562c9e3c346cb9e56eb (HEAD -> v0.2.1, origin/v0.2.1)
  Author: Serge ALEXANDRE <serge.alexandre@kubotal.io>
  Date:   Thu May 14 16:03:18 2026 +0200

  feat: --prompt option added. If set, value is added in authorization request
---------

In the reference part, the way spec fields are displayed, using simple markdown does not render nicely and is not very readable. Could you suggest another way to display theses reference information. 
Implements on 110-oidcclient for a first look.


I think the 70-kc chapter deserve the same type of visual improvement. Test it on 'kc token' first

Also improve look for Common Options, in Overview 


In user guide, add a page about kubauth helm chart describing the important velues in value file.


Could you write a page in user guide describing how to add a new style or template layout.
- How to build a new docker image with:
    - For light modification: Just add a new theme in the shared.css
    - For deeper modification. Duplicate the 'resources' folder and modify the templates
- Document the description of the data model for templating for index.gohtml (line 63 in handle-index), login.gohtml (LoginModel struct in display-login.go) 
and upstream-welcome.html (UpstreamWelcomeModel struct in handle-upstream-welcome.go)
- How to deploy with helm with the modified image and modified resourcesFolder value

For Path A — CSS-Only Tweak, is it possible (and simpler) to mount a configMap, instead of rebulding an image


Secret was used because extraConfigMaps was not exposed in helm chart. But I think configMap is more appropriate. 
So, modify the helm chart to add extraConfigMaps. The helm chart is here: /Users/sa/dev/d1/git/kubauth/helm/kubauth
and adjust this doc.

Path A/Method 2 seems similar to Path B