resource "oci_core_vcn" "vcn" {
  cidr_block       = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name     = "always-free-vcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "always-free-igw"
}

resource "oci_core_route_table" "rtb" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "always-free-rtb"

  route_rules {
    destination = "0.0.0.0/0"
    target      = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_subnet" "public_subnet" {
  cidr_block       = "10.0.1.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "always-free-public-subnet"
  route_table_id = oci_core_route_table.rtb.id
}
