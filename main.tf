
locals {
  setup_script_hash = filesha256("${path.module}/setup.sh")
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Reserve and assign a Public IP Address
resource "oci_core_public_ip" "reserved_ip" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.primary_vnic_ip.private_ips[0].id
  display_name   = "Always-Free-VM-Reserved-IP"
  freeform_tags = {
    Name        = "Always Free VM Public IP"
    Environment = "Production"
  }

  depends_on = [oci_core_instance.always_free_vm]

  #lifecycle {
    #prevent_destroy = true
  #}
}

# Configure the Compute Instance
resource "oci_core_instance" "always_free_vm" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "Always-Free-VM"
  shape               = var.instance_shape

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.public_subnet.id
    display_name           = "Primary VNIC"
    assign_public_ip       = false
    private_ip             = "10.0.1.10"
    skip_source_dest_check = false
    nsg_ids                = [oci_core_network_security_group.free_nsg.id]
  }

  source_details {
    source_type             = "IMAGE"
    source_id               = "ocid1.image.oc1.us-chicago-1.aaaaaaaasrbvw2qh25ewu3gg2div6bkwvqdi2oilwxirhic3qa5tzzxrcdwa"
    boot_volume_size_in_gbs = 50
  }

  shape_config {
    memory_in_gbs = "6"
    ocpus         = "1"
  }

  freeform_tags = {
    Name        = "Always Free VM"
    Environment = "Production"
  }
}

# Get the VNIC attachment details
data "oci_core_vnic_attachments" "vm_vnic" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.always_free_vm.id
}

# Get the private IP of the primary VNIC
data "oci_core_private_ips" "primary_vnic_ip" {
  vnic_id = data.oci_core_vnic_attachments.vm_vnic.vnic_attachments[0].vnic_id
}

# Run provisioners after reserved IP is assigned
resource "null_resource" "vm_provisioner" {
  connection {
    type        = "ssh"
    user        = "opc"
    private_key = file("/home/ty/.ssh/ssh.key")
    host        = oci_core_public_ip.reserved_ip.ip_address
    timeout     = "30m"
    agent       = false
  }

  provisioner "file" {
    source      = "${path.module}/setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
   inline = [
     "export CLOUDFLARE_TUNNEL_TOKEN='${cloudflare_zero_trust_tunnel_cloudflared.openhands.tunnel_token}'",
     "chmod +x /tmp/setup.sh",
     "sudo -E bash /tmp/setup.sh > /tmp/setup.log 2>&1"
   ]
 }

  depends_on = [oci_core_public_ip.reserved_ip]
}

# Create Virtual Cloud Network
resource "oci_core_vcn" "free_vcn" {
  cidr_block     = "10.0.0.0/16"
  display_name   = "always-free-vcn"
  compartment_id = var.compartment_ocid
  dns_label      = "alwaysfreevcn"
}

# Create Internet Gateway
resource "oci_core_internet_gateway" "free_igw" {
  compartment_id = var.compartment_ocid
  display_name   = "always-free-igw"
  vcn_id         = oci_core_vcn.free_vcn.id
}

# Create Public Subnet
resource "oci_core_subnet" "public_subnet" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  cidr_block          = "10.0.1.0/24"
  display_name        = "public-subnet"
  dns_label           = "public"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.free_vcn.id

  route_table_id = oci_core_route_table.public_route_table.id
}

# Create Route Table
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_ocid
  display_name   = "public-route-table"
  vcn_id         = oci_core_vcn.free_vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.free_igw.id
  }
}

# Create Network Security Group
resource "oci_core_network_security_group" "free_nsg" {
  compartment_id = var.compartment_ocid
  display_name   = "always-free-nsg"
  vcn_id         = oci_core_vcn.free_vcn.id
}

# Allow SSH Ingress
resource "oci_core_network_security_group_security_rule" "ssh_in" {
  network_security_group_id = oci_core_network_security_group.free_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

# Allow HTTP Ingress (for Cloudflare tunnel validation)
resource "oci_core_network_security_group_security_rule" "http_in" {
  network_security_group_id = oci_core_network_security_group.free_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

# Allow HTTPS Ingress (for Cloudflare tunnel validation)
resource "oci_core_network_security_group_security_rule" "https_in" {
  network_security_group_id = oci_core_network_security_group.free_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# Allow Egress
resource "oci_core_network_security_group_security_rule" "egress" {
  network_security_group_id = oci_core_network_security_group.free_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
}

# NOTE: Port 3000 is NOT exposed globally. Only cloudflared will access it via localhost.

# Data source to get the Oracle Linux image
data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  shape                    = var.instance_shape
}

# Data source to get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# ==================== CLOUDFLARE ZERO TRUST ====================

# Generate random tunnel secret
resource "random_string" "tunnel_secret" {
  length  = 32
  special = true
}

# Create Cloudflare Tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "openhands" {
  account_id = var.cloudflare_account_id
  name       = "openhands-tunnel"
  secret     = base64encode(random_string.tunnel_secret.result)
}

# Create Cloudflare Tunnel configuration
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "openhands" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.openhands.id

  config {
    ingress_rule {
      hostname = "${var.subdomain}.${var.domain_name}"
      service  = "http://localhost:3000"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Create CNAME DNS record pointing to Cloudflare tunnel
resource "cloudflare_record" "openhands" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.openhands.cname}"
  ttl     = 1
  proxied = true
}
