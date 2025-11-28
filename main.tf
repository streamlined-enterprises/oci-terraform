# --- 1. VCN and Subnet (VCN is Always Free) ---
resource "oci_core_vcn" "llm_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "LLM-VCN"
}

resource "oci_core_subnet" "llm_subnet" {
  cidr_block     = "10.0.1.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.llm_vcn.id
  display_name   = "LLM-Subnet"
  # Use VCN's default route and DNS
  route_table_id = oci_core_vcn.llm_vcn.default_route_table_id
  dns_label      = "llmsubnet"
  prohibit_public_ip_on_vnic = false # Crucial for internet access
}

# --- 2. Security List (Firewall Rules) ---
resource "oci_core_security_list" "llm_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.llm_vcn.id
  display_name   = "LLM-Security-List"

  # Ingress Rule: Allow SSH (Port 22) from anywhere
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    tcp_options {
      destination_port_range {
        min = 22
        max = 22
      }
    }
  }

  # Ingress Rule: Allow Cloudflare (Cloudflared will handle the Ollama port 11434 access)
  # You don't need to expose 11434 to the internet, only to Cloudflared running on the VM.
  # Allowing Ingress from the VM itself and all egress is often enough.

  # Egress Rule: Allow all traffic out (needed for Ollama model pulls and Cloudflared)
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_vnic_attachment" "llm_vnic_attachment" {
  instance_id = oci_core_instance.ollama_vm.id
  create_vnic_details {
    subnet_id              = oci_core_subnet.llm_subnet.id
    security_list_ids      = [oci_core_security_list.llm_security_list.id]
    assign_public_ip       = true
    skip_source_dest_check = true
  }
}


# --- 3. Compute Instance (VM.Standard.A1.Flex - Always Free) ---
resource "oci_core_instance" "ollama_vm" {
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_display_name
  shape               = "VM.Standard.A1.Flex" # Always Free Ampere A1 Flex
  shape_config {
    ocpus               = 4 # Max OCPUs in Always Free tier
    memory_in_gbs       = 24 # Max RAM in Always Free tier
  }

  # Use an Always Free eligible Linux image (e.g., Ubuntu or Oracle Linux)
  source_details {
    source_type = "image"
    # Find a public image OCID for your region (e.g., Ubuntu/Oracle Linux)
    # This OCID must be updated to an Always Free eligible image in your region.
    # Placeholder: Replace with actual OCID from OCI Console or data source
    source_id   = "ocid1.image.oc1.us-chicago-1.aaaaaaaasrbvw2qh25ewu3gg2div6bkwvqdi2oilwxirhic3qa5tzzxrcdwa"
  }

  # SSH Keys for access
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  # Boot volume size (min 47GB, max 200GB in Always Free)
  create_vnic_details {
    subnet_id = oci_core_subnet.llm_subnet.id
  }
}
