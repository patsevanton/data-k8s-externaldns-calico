# ExternalDNS для Yandex Cloud

Installing the Chart¶
Before you can install the chart you will need to add the external-dns repo to Helm.

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
After you’ve installed the repo you can install the chart.

helm upgrade --install external-dns external-dns/external-dns --version 1.19.0
