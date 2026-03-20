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
    retries = 3    # Ajoute cette ligne pour laisser le temps à Proxmox
  }

  network_device {
    bridge = "vmbr2" # Bridge privé pour Tailscale
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = 25
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.192.55/18" # IP fixe dans ton subnet
        gateway = "192.168.192.5"
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key] # Utilise le secret GitHub
    }
  }
}

# --- DÉCLARATION DES VARIABLES (SYNTAXE CORRIGÉE) ---
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
