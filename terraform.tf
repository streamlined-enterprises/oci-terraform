terraform {
  required_version = ">= 1.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }

  # Uncomment to use remote state backend
  # backend "s3" {
  #   bucket         = "your-bucket-name"
  #   key            = "terraform/oci/terraform.tfstate"
  #   region         = "us-chicago-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}
