# 🚀 Proxmox CI/CD Lab — Terraform + Ansible + Tailscale

<p align="left">
  <img src="https://img.shields.io/badge/Terraform-1.7-7B42BC?style=for-the-badge&logo=terraform&logoColor=white"/>
  <img src="https://img.shields.io/badge/Ansible-2.20-EE0000?style=for-the-badge&logo=ansible&logoColor=white"/>
  <img src="https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?style=for-the-badge&logo=githubactions&logoColor=white"/>
  <img src="https://img.shields.io/badge/Proxmox-8.4-E57000?style=for-the-badge&logo=proxmox&logoColor=white"/>
  <img src="https://img.shields.io/badge/Tailscale-Mesh_VPN-242424?style=for-the-badge&logo=tailscale&logoColor=white"/>
</p>

<p align="left">
  <img src="https://img.shields.io/badge/Checkov-IaC_Scan-brightgreen?style=flat-square"/>
  <img src="https://img.shields.io/badge/Trivy-Vulnerability_Scan-blue?style=flat-square"/>
  <img src="https://img.shields.io/badge/Terraform_Cloud-State_Backend-7B42BC?style=flat-square"/>
  <img src="https://img.shields.io/badge/Ubuntu-22.04_Cloud_Init-E95420?style=flat-square&logo=ubuntu&logoColor=white"/>
  <img src="https://img.shields.io/badge/Nginx-Web_Server-009639?style=flat-square&logo=nginx&logoColor=white"/>
</p>

**Pipeline CI/CD complet : un `git push` depuis un poste dev provisionne automatiquement une VM sur Proxmox bare-metal Hetzner, la configure via Ansible, et déploie un serveur web.**

**Zéro port exposé sur internet. Zéro intervention manuelle. 100% as-code.**

---

## 📐 Architecture
```
┌─────────────────────────────────────────────────────────────┐
│  Poste Dev (Ubuntu Management VM)                           │
│  git push → GitHub                                          │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
                   GitHub Actions Runner
                          │
              ┌───────────┴───────────┐
              │                       │
              ▼                       ▼
       Checkov + Trivy         Tailscale ephemeral
       (IaC Security)         node monté sur runner
              │                       │
              └───────────┬───────────┘
                          │ Tailscale mesh VPN
                          ▼
                  Proxmox Hetzner (100.108.39.48)
                  subnet: 192.168.192.0/18
                          │
                          ▼
              ┌───────────────────────┐
              │   VM 505              │
              │   ubuntu-22.04        │
              │   192.168.192.55      │
              │   Nginx + page web    │
              └───────────────────────┘
```

---

## 🔄 Pipeline CI/CD
```
git push (poste dev)
    │
    ▼
GitHub Actions Runner
    │
    ├── [Job 1] Checkov — scan IaC Terraform → SARIF → GitHub Security tab
    │           Trivy  — scan vulnérabilités  → SARIF → GitHub Security tab
    │
    └── [Job 2] Tailscale — nœud éphémère (runner rejoint le tailnet)
                    │
                    ├── Terraform init + apply
                    │   └── Clone VM depuis template Ubuntu 22.04
                    │       Cloud-init : IP statique + clé SSH ed25519
                    │
                    ├── sleep 90s (attente fin cloud-init)
                    │
                    └── Ansible playbook
                        ├── Gathering Facts ✅
                        ├── Install Nginx   ✅
                        ├── Deploy page web ✅
                        └── Start + enable  ✅
```

**Sur PR** → Checkov + Trivy uniquement (pas d'apply)  
**Sur push `main`** → Pipeline complet

---

## 🛠️ Stack technique

### Infrastructure as Code
- **Terraform `bpg/proxmox` provider** — provisionnement VM via API Proxmox
- **Cloud-init** — injection clé SSH ed25519 + IP statique à la création
- **Terraform Cloud** — backend distant pour le state (mode Local execution)

### Configuration Management
- **Ansible** — playbook idempotent : install Nginx + déploiement page web
- **Inventaire statique** — IP `192.168.192.55` sur réseau privé `vmbr2`

### Networking & Sécurité
- **Tailscale mesh VPN** — le runner GitHub rejoint le tailnet via authkey éphémère
- **Subnet routing** — Proxmox expose `192.168.192.0/18` via Tailscale
- **Aucun port exposé** sur internet — accès exclusivement via Tailscale
- **Checkov** — scan IaC security avec export SARIF → GitHub Security tab
- **Trivy** — scan vulnérabilités filesystem avec export SARIF
- **GitHub Secrets** — 7 secrets, zéro credential en clair dans le code

---

## 📁 Structure du projet
```
test-tailscale/
├── .github/
│   └── workflows/
│       └── deploy.yml       # Pipeline CI/CD complet
├── ansible/
│   ├── inventory.ini        # VM cible : 192.168.192.55
│   └── install_nginx.yml    # Playbook : Nginx + page web
├── main.tf                  # VM Proxmox + cloud-init
└── README.md
```

---

## 🔐 Secrets GitHub

| Secret | Rôle |
|---|---|
| `TAILSCALE_AUTHKEY` | Auth key éphémère Tailscale (reusable) |
| `PM_API_URL` | URL API Proxmox via Tailscale |
| `PM_API_TOKEN_ID` | ID token API Proxmox |
| `PM_API_TOKEN_SECRET` | Secret UUID du token Proxmox |
| `SSH_PUBLIC_KEY` | Clé ed25519 publique injectée cloud-init |
| `SSH_PRIVATE_KEY` | Clé ed25519 privée pour Ansible |
| `TF_API_TOKEN` | Token Terraform Cloud (state backend) |

---

## 🚀 Déploiement

### Prérequis

- Node Proxmox avec Tailscale installé et connecté
- Template Ubuntu 22.04 cloud-init (VM ID 9000)
- Token API Proxmox (`root@pam!terraform`)
- Workspace Terraform Cloud en mode **Local execution**
- Subnet routing Tailscale activé sur Proxmox
```bash
# Sur Proxmox — activer le subnet routing
tailscale up --advertise-routes=192.168.192.0/18 --accept-routes
```

### Lancement
```bash
git clone https://github.com/bhashas/test-tailscale
cd test-tailscale
git push origin main
# → Pipeline déclenché automatiquement
```

### Résultat
```bash
curl http://192.168.192.55
# → <h1>Pipeline OK</h1>
# → <p>VM : vm-test-tailscale-bpg</p>
# → <p>IP : 192.168.192.55</p>
# → <p>Deploye via GitHub Actions + Terraform + Ansible</p>
```

---

## 📊 Ce que ce lab démontre

| Compétence | Technologie | Niveau |
|---|---|---|
| Infrastructure as Code | Terraform + bpg/proxmox | ✅ Production-ready |
| Configuration Management | Ansible | ✅ Idempotent |
| CI/CD Pipeline | GitHub Actions | ✅ Multi-job |
| VPN Mesh & Networking | Tailscale + subnet routing | ✅ Zero-trust |
| IaC Security Scanning | Checkov + Trivy + SARIF | ✅ DevSecOps |
| State Management | Terraform Cloud | ✅ Remote backend |
| Secrets Management | GitHub Secrets | ✅ Zero plaintext |
| Virtualisation | Proxmox + cloud-init | ✅ Bare-metal |

---

## 🧰 Technologies

`Proxmox VE 8.4` · `Terraform 1.7` · `bpg/proxmox provider` · `Ansible 2.20` · `Nginx` · `Tailscale 1.94` · `GitHub Actions` · `Checkov` · `Trivy` · `Terraform Cloud` · `Ubuntu 22.04 LTS` · `Cloud-Init` · `ed25519 SSH`

---

## 👤 Auteur

Construit dans le cadre d'un homelab multi-site (node local + Hetzner bare-metal) orienté pratique DevSecOps et Cloud Engineering.

> Ce lab fait partie d'un portfolio de projets infrastructure couvrant Proxmox, pfSense, WireGuard, VXLAN, 802.1X/NPS, Kubernetes, Wazuh/ELK et GCP.
