
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


