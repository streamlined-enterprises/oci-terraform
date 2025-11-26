resource "oci_core_instance" "free_vm" {
  compartment_id = var.compartment_ocid
  display_name   = "always-free-vm"
  shape          = "VM.Standard.E2.1.Micro"
  subnet_id      = oci_core_subnet.public_subnet.id

  source_details {
    source_type = "image"
    image_id    = data.oci_core_images.oracle_linux_8_latest.id
  }

  ssh_keys = [var.ssh_public_key]
}
