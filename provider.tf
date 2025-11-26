variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}

provider "oci" {
  tenancy = var.tenancy_ocid
  user    = var.user_ocid
  fingerprint = var.fingerprint
  private_key_path = var.private_key_path
  region      = var.region
}
