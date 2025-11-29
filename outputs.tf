output "instance_id" {
  description = "The OCID of the created instance"
  value       = oci_core_instance.always_free_vm.id
}

output "instance_public_ip" {
  description = "The public IP address of the instance"
  value       = oci_core_instance.always_free_vm.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the instance"
  value       = oci_core_instance.always_free_vm.private_ip
}

output "vcn_id" {
  description = "The OCID of the VCN"
  value       = oci_core_vcn.free_vcn.id
}

output "subnet_id" {
  description = "The OCID of the public subnet"
  value       = oci_core_subnet.public_subnet.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh opc@${oci_core_instance.always_free_vm.public_ip}"
}

output "management_url" {
  description = "OCI Console URL"
  value       = "https://cloud.oracle.com/compute/instances/${oci_core_instance.always_free_vm.id}"
}
