# ExternalDNS для Yandex Cloud


```
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
```


```
helm upgrade --install external-dns external-dns/external-dns ---wait -version 1.19.0
```