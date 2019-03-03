module "vpc" {
  source = "./vpc"

  name   = "${var.name}"
  region = "${var.region}"

  vms-cidr      = "10.10.0.0/16"
  pods-cidr     = "10.11.0.0/16"
  services-cidr = "10.12.0.0/16"
}

resource "random_string" "password" {
  length  = 32
  special = true
}

resource "google_container_cluster" "main" {
  name = "${var.name}"
  zone = "${var.zone}"

  network    = "${module.vpc.name}"
  subnetwork = "${module.vpc.subnet-name}"

  min_master_version = "1.11.6-gke.2"
  initial_node_count = 3

  ip_allocation_policy {
    cluster_secondary_range_name  = "${module.vpc.pods-range-name}"
    services_secondary_range_name = "${module.vpc.services-range-name}"
  }

  node_config {
    oauth_scopes = [
      "compute-rw",
      "storage-ro",
      "logging-write",
      "monitoring",
    ]

    disk_type    = "pd-ssd"
    disk_size_gb = "15"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    kubernetes_dashboard {
      disabled = false
    }
  }

  master_auth {
    username = "concourse"
    password = "${random_string.password.result}"
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

resource "google_container_node_pool" "main" {
  provider = "google-beta"
  count    = "${length(var.node-pools)}"

  zone    = "${var.zone}"
  cluster = "${google_container_cluster.main.name}"
  name    = "${lookup(var.node-pools[count.index], "name")}"

  autoscaling {
    min_node_count = "${lookup(var.node-pools[count.index], "min")}"
    max_node_count = "${lookup(var.node-pools[count.index], "max")}"
  }

  management {
    auto_repair  = true
    auto_upgrade = "${lookup(var.node-pools[count.index], "auto-upgrade")}"
  }

  node_config {
    preemptible     = "${lookup(var.node-pools[count.index], "preemptible")}"
    machine_type    = "${lookup(var.node-pools[count.index], "machine-type")}"
    local_ssd_count = "${lookup(var.node-pools[count.index], "local-ssds")}"
    disk_size_gb    = "${lookup(var.node-pools[count.index], "disk-size")}"
    disk_type       = "${lookup(var.node-pools[count.index], "disk-type")}"
    image_type      = "${lookup(var.node-pools[count.index], "image")}"

    workload_metadata_config {
      node_metadata = "SECURE"
    }

    oauth_scopes = [
      "compute-rw",
      "storage-ro",
      "logging-write",
      "monitoring",
    ]
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }
}
