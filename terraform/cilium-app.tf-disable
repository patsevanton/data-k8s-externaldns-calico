resource "yandex_kubernetes_cluster" "cilium-app" {
  name       = "cilium-app"
  network_id = yandex_vpc_network.k8s-network.id

  master {
    version = "1.33"
    zonal {
      zone      = yandex_vpc_subnet.k8s-subnet.zone
      subnet_id = yandex_vpc_subnet.k8s-subnet.id
    }
    public_ip          = true
    security_group_ids = [yandex_vpc_security_group.allow-all-sg.id]
  }

  service_account_id      = yandex_iam_service_account.sa-k8s-admin.id
  node_service_account_id = yandex_iam_service_account.sa-k8s-admin.id
  release_channel         = "RAPID"
  cluster_ipv4_range      = "10.113.0.0/16"
  service_ipv4_range      = "10.97.0.0/16"

  depends_on = [yandex_resourcemanager_folder_iam_member.sa-k8s-admin-permissions]
}

resource "yandex_kubernetes_node_group" "k8s_node_group_cilium_app" {
  cluster_id = yandex_kubernetes_cluster.cilium-app.id
  name       = "node-group-cilium-app"
  version    = "1.33"

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.k8s-subnet.id]
    }

    resources {
      cores  = 2
      memory = 8
    }

    boot_disk {
      type = "network-ssd"
      size = 65
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

output "get_credentials_command_cilium_app" {
  description = "Command to get kubeconfig for the Cilium App cluster"
  value       = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.cilium-app.id} --external --force"
}
