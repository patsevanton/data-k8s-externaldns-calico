# ExternalDNS для Yandex Cloud


```
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
```

```
helm show values external-dns/external-dns > values.yaml
```

```
helm upgrade --install external-dns external-dns/external-dns ---wait -version 1.19.0
```

```
yc iam key create iamkey \
  --service-account-id=<your service account ID> \
  --format=json \
  --output=key.json
```
