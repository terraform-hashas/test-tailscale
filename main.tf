terraform {
  cloud {
    organization = "LAB_TEST_BRAHIM"
    workspaces {
      name = "test-tailscale"
    }
  }
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
  name      = "vm-test-tailscale-final"
  node_name = "pve-1"
  vm_id     = 505
  started   = true
  on_boot   = false

  clone {
    vm_id   = 9000
    full    = true
    retries = 3
  }

  agent {
    enabled = false
  }

  cpu {
    cores   = 2
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
  }

  scsi_hardware = "virtio-scsi-pci"

  vga {
    type = "serial0"
  }

  serial_device {}

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = 22
    discard      = "on"
    file_format  = "raw"
  }

  network_device {
    bridge = "vmbr2"
    model  = "virtio"
  }

  initialization {
    datastore_id = "local-zfs"
    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
    ip_config {
      ipv4 {
        address = "192.168.192.55/18"
        gateway = "192.168.192.5"
      }
    }
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
}

variable "proxmox_api_url" {
  type = string
}
variable "proxmox_api_token_id" {
  type = string
}
variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}
variable "ssh_public_key" {
  type = string
}

# Self-healing test: VM 505 manual delete
