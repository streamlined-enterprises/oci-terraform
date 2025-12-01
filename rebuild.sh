#!/bin/bash
set -e

terraform taint null_resource.vm_provisioner
terraform taint oci_core_instance.always_free_vm
terraform apply -auto-approve

