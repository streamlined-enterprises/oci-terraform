variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" { default = "us-chicago-1" } # Change to your home region
variable "ssh_public_key" {}
variable "instance_display_name" { default = "vm1" }
