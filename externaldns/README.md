# ExternalDNS для Yandex Cloud


```
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
```

```
helm show values external-dns/external-dns > values.yaml
```

```
kubectl create namespace external-dns
```

получаем key.json в директории terraform
```
terraform output -raw dns_manager_service_account_key | python3 -m json.tool | grep -v description | grep -v encrypted_private_key | grep -v format | grep -v key_fingerprint | grep -v pgp_key > key.json
```

в директории terraform
```
kubectl create secret generic yandexconfig --namespace external-dns --from-file=key.json
```

получаем folder_id в директории terraform
```
folder_id=$(terraform output -raw folder_id)
```

```
helm upgrade --install external-dns external-dns/external-dns --namespace external-dns --create-namespace -f externaldns/values.yaml --wait --version 1.19.0 --set provider.webhook.args="{--folder-id=$folder_id,--auth-key-file=/etc/kubernetes/key.json}"
```