
```
helm -n kubauth upgrade -i kubauth --values ./values.yaml oci://quay.io/kubauth/charts/kubauth --version 0.1.2-snapshot --create-namespace --wait --set oidc.image.pullPolicy=Always

```

https://squidfunk.github.io/mkdocs-material/reference/admonitions/



Installation
User guide
  - Configuration
  - login and claims
  - Audit
  - SSO
  - Groups
  - Password grant
  - LDAP setup
  - Identity providers chaining
Kubernetes integration
  - apiserver
  - kubeconfig
  - Deploying as regular user
Apps Configuration
  - Harbor
  - ArgoCD
Appendix
  - OpenLDAP deployment





OAuth’s Resource Owner Password Credentials (ROPC) grant type, aka the password grant, was included in the original OAuth 2.0 specification as a temporary measure back in 2012.
It was designed as a quick way of migrating old applications from legacy authentication mechanisms, such as HTTP Basic Authentication or credential sharing,
and onto an OAuth tokenized architecture.

## Why it can still be useful (despite deprecation)

- First‑party legacy migrations: Lets you keep an existing UX while you transition server-side to OAuth/OIDC tokens.
- Constrained CLI/headless sessions: When an interactive browser is impossible (air‑gapped shells, jump hosts). Device Authorization is preferred, but ROPC can be a short‑term bridge.
- Tightly controlled enterprise environments: Only for trusted, first‑party apps on private networks with strict controls.
- Break‑glass access: Temporary, audited emergency access if the normal SSO/browser flow is unavailable.
- Demos and labs: Short‑lived test environments where risk is limited and isolated.

## Hard requirements if you ever enable it

- First‑party only. Never expose to third‑party clients. Avoid public/native apps that can be reverse‑engineered.
- Strong transport controls: TLS required; prefer private networks and consider mTLS.
- No password storage: Prompt on demand, do not persist credentials. Enforce strong password policies.
- Minimize token risk: Very short access‑token TTLs, least‑privilege scopes, rapid revocation. Prefer no refresh tokens (or extremely short‑lived) for ROPC.
- MFA limitations: ROPC can’t perform modern phishing‑resistant MFA (e.g., WebAuthn). Use conditional access or step‑up outside of ROPC if mandated.
- Abuse protections: Rate limiting, IP allow‑lists, anomaly detection, account lockouts, and full audit logging.

## Prefer these alternatives

- Authorization Code + PKCE: For browsers and native apps.
- Device Authorization Grant (RFC 8628): For CLI, TVs, and headless environments.
- Client Credentials: For service‑to‑service (no end‑user).
- Token Exchange/On‑behalf‑of: When a service must call downstream APIs on a user’s behalf.

## Recommended stance in Kubauth

- Keep ROPC disabled by default (as shown by the 403 you observed).
- If you must use it for a temporary migration or constrained CLI flow:
    - Create a dedicated client with minimal scopes and very short TTLs.
    - Restrict by network and audience, add strict monitoring and an explicit decommission date.`






## About the Password Grant (ROPC)

OAuth's Resource Owner Password Credentials (ROPC) grant type, also known as the password grant, was included in the original OAuth 2.0 specification back in 2012 as a temporary migration path. 
It was designed to help legacy applications transition from HTTP Basic Authentication or direct credential sharing to an OAuth token-based architecture.

The OAuth 2.0 Security Best Current Practice (BCP) has since **deprecated** this flow, and OAuth 2.1 removes it entirely due to several fundamental security concerns:

- **Credentials exposure**: The client application directly handles user passwords
- **Phishing risk**: Users are trained to enter passwords into applications
- **Limited MFA support**: Cannot support modern phishing-resistant authentication (WebAuthn, FIDO2)
- **No consent flow**: Users cannot review or limit what they're authorizing
- **Credential theft**: If the client is compromised, user passwords are exposed

## Why it can still be useful (with caveats)

Despite deprecation, there are legitimate scenarios where ROPC may be the most pragmatic solution:

### 1. **Legacy application migration**
When modernizing authentication for existing applications, ROPC allows you to adopt OAuth/OIDC tokens server-side while maintaining the current user experience. This provides a bridge during gradual migration to browser-based flows.

### 2. **Headless and CLI environments**
In scenarios where a browser is unavailable or impractical:

- Air-gapped environments or jump hosts without browser access
- Automated scripts and CI/CD pipelines (where service accounts aren't suitable)
- Terminal-only environments on embedded systems

### 3. **Highly trusted first-party applications**
In tightly controlled enterprise environments where:

- The application is developed and operated by the same organization as the authorization server
- Network access is restricted (private networks, VPN-only)
- Strong operational controls and monitoring are in place

### 4. **Break-glass access scenarios**
Emergency access when normal interactive authentication is unavailable:

- Disaster recovery procedures
- System maintenance when SSO infrastructure is down
- Temporary administrative access (with full audit logging)

### 5. **Development and testing**
For isolated development/test environments where:

- Automated testing requires authentication flows
- Developer productivity benefits from simplified local testing
- The environment is isolated from production data

## If you must enable it: Hard requirements

!!! warning "Security Requirements"
Enabling ROPC should only be done with these strict controls:

**First-party only**

- Never expose to third-party clients
- Avoid public/native apps that can be reverse-engineered
- Use only for applications you fully control

**Transport security**

- Require TLS 1.2+ for all connections
- Consider mTLS for additional client authentication
- Restrict to private networks when possible

**Credential handling**

- Never store user passwords in the client
- Prompt for credentials on-demand only
- Enforce strong password policies at the authorization server
- Consider requiring application-specific passwords

**Token security**

- Use very short access token lifetimes (5-15 minutes)
- Implement least-privilege scopes
- Avoid issuing refresh tokens, or make them very short-lived
- Enable rapid token revocation capabilities

**Authentication factors**

- Be aware: ROPC cannot perform modern phishing-resistant MFA
- Consider step-up authentication for sensitive operations
- Use risk-based authentication and conditional access policies

**Abuse protection**

- Implement strict rate limiting
- Use IP allow-lists where possible
- Deploy anomaly detection and alerting
- Enable account lockout policies
- Maintain comprehensive audit logs

## Better alternatives

Consider these modern, more secure flows instead:

| Flow | Use Case |
|------|----------|
| **Authorization Code + PKCE** | Web and native/mobile applications |
| **Device Authorization Grant (RFC 8628)** | CLI tools, smart TVs, devices without browsers |
| **Client Credentials** | Service-to-service authentication (no user context) |
| **Token Exchange / On-Behalf-Of** | Downstream API calls requiring user context |

## Recommended approach in Kubauth

**Default stance**: Keep ROPC disabled (as shown by the 403 error above).

**If temporarily required**:

1. Create a dedicated OAuth client specifically for ROPC
2. Configure minimal required scopes
3. Set very short token lifetimes (5-15 min)
4. Restrict by network/IP ranges
5. Limit to specific user groups/audiences
6. Enable comprehensive monitoring and alerting
7. **Set an explicit decommission date** and plan migration to Device Authorization Grant or Authorization Code + PKCE

**Document the business justification** and security review in your security compliance records.



