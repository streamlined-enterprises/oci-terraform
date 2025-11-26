resource "oci_containerengine_cluster" "basic_cluster" {
  compartment_id = var.compartment_ocid
  display_name   = "always-free-oke-cluster"
  kubernetes_version = data.oci_containerengine_kubernetes_versions.latest.version

  node_pools {
    name              = "always-free-node-pool"
    compartment_id    = var.compartment_ocid
    cluster_id        = oci_containerengine_cluster.basic_cluster.id
    subnet_ids        = [oci_core_subnet.public_subnet.id]
    shape             = "VM.Standard.A1.Flex"
    node_shape_config {
      ocpus = 2
      memory_in_gb = 12
    }
    size              = 1
    ssh_public_keys   = [var.ssh_public_key]
  }

  options {
    kubernetes_network_profile {
      pod_cidr             = "10.244.0.0/16"
      service_cidr         = "10.96.0.0/12"
      service_cluster_ip_range = "10.96.0.0/12"
    }
  }

  node_pool_options {
    kubernetes_version = data.oci_containerengine_kubernetes_versions.latest.version
  }
}
