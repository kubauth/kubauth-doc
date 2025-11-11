# Introduction

This chapter describe how to integrate Kubauth OIDC server to the Kubernetes Authentication system and RBAC.

Aim is to authenticate users interacting with the cluster through tools like `kubectl`.

There will be two part for this topic:

- We need to configure the Kubernetes API server to interact with Kubauth.

    A tool to fully automate this configuration is provided. But, manual configuration is also documented.

- Each user will need to perform a local configuration. 

    Here also, a toolkit is provided to automate this.
