# Kubauth

A Kubernetes-native OpenID Connect (OIDC) Identity Provider.

## Overview

Kubauth is a fully-featured OIDC identity provider designed for Kubernetes environments.

It stores users, groups, clients, and sessions as native Kubernetes resources, providing a scalable and cloud-native authentication solution.

Kubauth can operate autonomously with its own user database or act as a federation gateway for external identity providers such as LDAP.

## Key Features

- **OIDC Compliance**: Supports standard OIDC flows including Authorization Code and Resource Owner Password Credentials (ROPC)
- **PKCE Support**: Complete Proof Key for Code Exchange (PKCE) implementation with configurable enforcement
- **Kubernetes-Native Storage**: All data stored as Kubernetes Custom Resources (CRDs) — no external database required
- **SSO Capabilities**: Cross-application Single Sign-On with persistent sessions
- **User & Group Management**: Fine-grained user authentication and group-based authorization
    - Claims can be defined at user or group level
    - User profiles can be built from multiple identity sources
- **Security First**: bcrypt password hashing, JWT signing with persistent keys, secure session management
- **Production Ready**: Health checks, admission webhooks, and Helm chart deployment

## Kubauth Components

Kubauth consists of several subprojects:

- **kubauth**: The main OIDC server with all its connectors
- **kc**: A companion CLI tool
- Two subprojects designed to authenticate `kubectl` users with OIDC:
    - **kubauth-apiserver**: A Kubernetes configuration tool to automate the `apiserver` OIDC configuration
    - **kubauth-kubeconfig**: A tool to automate `kubectl` client configuration
