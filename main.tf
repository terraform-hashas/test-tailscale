terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true
}

resource "proxmox_virtual_environment_vm" "vm_test" {
  name      = "vm-test-tailscale-bpg"
  node_name = "pve-1"
  vm_id     = 505

  clone {
    vm_id = 9000
    full  = false 
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = 25
  }
}

variable "proxmox_api_url" { type = string }
variable "proxmox_api_token_id" { type = string }
variable "proxmox_api_token_secret" { type = string; sensitive = true }
