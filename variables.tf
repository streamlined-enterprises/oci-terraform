variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the API key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
}

variable "region" {
  description = "The Oracle Cloud region"
  type        = string
  default     = "us-chicago-1"
}

variable "instance_shape" {
  description = "The shape of the instance (Always Free eligible)"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "instance_display_name" {
  description = "Display name for the compute instance"
  type        = string
  default     = "Always-Free-VM"
}

variable "availability_domain_index" {
  description = "Index of the availability domain (0, 1, or 2)"
  type        = number
  default     = 0
}

variable "domain_name" {
  description = "the domain suffix for the DNS record"
  type        = string
}

variable "subdomain" {
  description = "the domain prefix for the DNS record"
  type        = string
}

variable "cloudflare_api_token" {
  description = "the cloudflare api token"
  type        = string
}

variable "cloudflare_account_id" {
  description = "the cloudflare account id"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "the cloudflare zone id"
  type        = string
}
