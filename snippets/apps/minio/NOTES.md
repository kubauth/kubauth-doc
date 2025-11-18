

```


mc alias set myminio https://minio-minio1.ingress.kubo6.mbp minio minio123

mc mb myminio/xxx

```

```

mc idp openid add myminio kubauth \
    client_id=minio \
    client_secret=minio123 \
    config_url="https://kubauth.ingress.kubo6.mbp/.well-known/openid-configuration" \
    redirect_uri="https://minio-console-minio1.ingress.kubo6.mbp/oauth_callback" \
    claim_name="minio_policies" \
    display_name=KUBAUTH \
    claim_userinfo="on"
    
mc admin service restart myminio
```




