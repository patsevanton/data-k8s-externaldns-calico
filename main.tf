data "yandex_client_config" "client" {}

locals {
  folder_id = coalesce(var.folder_id, data.yandex_client_config.client.folder_id)
}

resource "yandex_kubernetes_cluster" "zonal_k8s_cluster" {
  name        = "my-cluster"
  description = "my-cluster description"
  network_id  = yandex_vpc_network.k8s-network.id

  master {
    version = "1.31"
    zonal {
      zone      = yandex_vpc_subnet.k8s-subnet.zone
      subnet_id = yandex_vpc_subnet.k8s-subnet.id
    }
    public_ip = true
  }

  service_account_id      = yandex_iam_service_account.sa-k8s-admin.id
  node_service_account_id = yandex_iam_service_account.sa-k8s-admin.id
  release_channel         = "STABLE"
  network_policy_provider = "CALICO"
  // to keep permissions of service account on destroy
  // until cluster will be destroyed
  depends_on = [yandex_resourcemanager_folder_iam_member.sa-k8s-admin-permissions]
}

# yandex_kubernetes_node_group

resource "yandex_kubernetes_node_group" "k8s_node_group" {
  cluster_id  = yandex_kubernetes_cluster.zonal_k8s_cluster.id
  name        = "name"
  description = "description"
  version     = "1.31"

  labels = {
    "key" = "value"
  }

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.k8s-subnet.id]
    }

    resources {
      cores         = 2
      memory        = 2
      core_fraction = 50
    }

    boot_disk {
      type = "network-hdd"
      size = 32
    }

    scheduling_policy {
      preemptible = true
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    }

  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-b"
    }
  }
}
