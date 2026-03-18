terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.1"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://100.108.39.48:8006/"
  # On combine l'ID et le Secret avec un "=" pour le provider BPG
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure  = true
}

resource "proxmox_virtual_environment_vm" "vm_test" {
  name      = "vm-test-tailscale-bpg"
  node_name = "pve-1"
  vm_id     = 505

  clone {
    vm_id = 9000 # ID de ton template ubuntu-22.04 visible sur ton image_a3704f
    full  = true
  }

  cpu {
    cores = 1
    type  = "host"
  }

  memory {
    dedicated = 1024
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 25
  }
}

variable "pm_api_token_id" {}
variable "pm_api_token_secret" {}
