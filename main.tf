terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc3"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://100.108.39.48:8006/api2/json"
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "vm_test" {
  name        = "vm-test-tailscale"
  target_node = "pve-1"
  vmid        = 505 # ID libre

  clone       = "ubuntu-22.04-template" # Ton template ID 9000
  full_clone  = true

  cores   = 1
  memory  = 1024
  
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    size    = "10G"
    type    = "scsi"
    storage = "local-lvm"
  }
}

variable "pm_api_token_id" {}
variable "pm_api_token_secret" {}
