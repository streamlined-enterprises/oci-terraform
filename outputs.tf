output "public_ip" {
  value = oci_core_instance.free_vm.public_ip
}

output "oke_cluster_id" {
  value = oci_containerengine_cluster.basic_cluster.id
}
