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

получаем key.json
```
cd terraform
terraform output -raw dns_manager_service_account_key | python3 -m json.tool | grep -v description | grep -v encrypted_private_key | grep -v format | grep -v key_fingerprint | grep -v pgp_key > key.json
```

kubectl create secret generic yandexconfig --namespace external-dns --from-file=terraform/key.json