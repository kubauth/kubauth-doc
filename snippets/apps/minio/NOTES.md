

```


mc alias set myminio https://minio.ingress.kubo2.mbp minio minio123

mc mb myminio/xxx

```

```

mc idp openid add myminio kubauth \
    client_id=minio \
    client_secret=minio123 \
    config_url="https://kubauth.ingress.kubo2.mbp/.well-known/openid-configuration" \
    redirect_uri="https://minio-console.ingress.kubo2.mbp/oauth_callback" \
    claim_name="minio_policies" \
    display_name=KUBAUTH \
    claim_userinfo="on"
    
mc admin service restart myminio
```


# Patch community helm chart

To solve IDP certificate issue:

Need to patch the community helm chart:

.../templates/_helper.tpl:

```
{{/*
Formats volume for MinIO TLS keys and trusted certs
*/}}
{{- define "minio.tlsKeysVolume" -}}
{{- if .Values.tls.enabled }}
- name: cert-secret-volume
  secret:
    secretName: {{ tpl .Values.tls.certSecret $ }}
    items:
    - key: {{ .Values.tls.publicCrt }}
      path: public.crt
    - key: {{ .Values.tls.privateKey }}
      path: private.key
{{- end }}
{{- if or .Values.tls.enabled (ne .Values.trustedCertsSecret "") }}
{{- $certSecret := eq .Values.trustedCertsSecret "" | ternary .Values.tls.certSecret .Values.trustedCertsSecret }}
{{- $publicCrt := eq .Values.trustedCertsSecret "" | ternary .Values.tls.publicCrt "" }}
- name: trusted-cert-secret-volume
  secret:
    secretName: {{ $certSecret }}
{{/*    {{- if ne $publicCrt "" }}*/}}
{{/*    items:*/}}
{{/*    - key: {{ $publicCrt }}*/}}
{{/*      path: public.crt*/}}
{{/*    {{- end }}*/}}
{{- end }}
{{- end -}}

```

(See commented lines)

And set all issuers (including internal) with tha same than kubauth.