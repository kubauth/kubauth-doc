
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


