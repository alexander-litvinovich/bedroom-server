# Bedroom Server

A repo for setting up my home lab server on Ubuntu 24.04 from scratch for the case when NVMe will pass away.

An old HP Prodesk 405 G4 Mini desktop is running Ubuntu 24.04

The list of software to be running:

- [x] OpenSSH server
- [x] Docker
- [x] Lazydocker
- [x] zsh + Oh My Zsh
- [x] Change MOTD
- [x] Tailscale
- [x] Pi-hole
- [x] NGINX Proxy Manager
- [x] XRDP server
- [x] n8n
- [x] Ollama
- [x] Vaultwarden https://github.com/dani-garcia/vaultwarden
- [x] Kavita

TBD:

- [ ] Syncthing
- [ ] Git repo (Gitea)
- [ ] Traefik

Check the list: https://vas3k.blog/notes/homelab_2022/

## How to install and make it run

Start by installing packages from `preflight.sh`

To enable SSH access use `ssh.sh` it installs OpenSSH Uncomplicated Firewall (UFW) Keychain. Set up SSH server as a daemon, opens 22 port in UFW and applying SSH configuration from `assets/ssh_config`. Also it adds SSH agent autostart to `~/.zshrc`.

## Codex worker VMs

The worker setup uses Incus virtual machines so that every Codex/T3 identity,
workspace, Git checkout, Docker daemon, and session has its own filesystem and
machine identity. The guest account is always `vmuser`.

Copy `.env.example` to `.env`, set the `CODEX_VM_*` values, and reserve the
configured IP range outside the router's DHCP range. `CODEX_VM_PARENT_NIC` must
be a wired interface.

Install the one bootstrap dependency, then provision the host locally:

```bash
sudo apt update
sudo apt install -y ansible-core
set -a; source .env; set +a
ansible-playbook --connection=local --inventory localhost, --ask-become-pass ansible/host.yml
```

Log out and back in once if Ansible added you to `incus-admin`. Build the golden
image and create workers:

```bash
./codex-vm image-build
./codex-vm create codex-01
./codex-vm create codex-02
./codex-vm list
./codex-vm ssh-config
```

Paste the generated SSH entries into T3 Desktop's SSH config. On each VM, log
in independently:

```bash
codex login --device-auth
gh auth login
```

Useful lifecycle commands:

```bash
./codex-vm doctor
./codex-vm status codex-01
./codex-vm ssh codex-01
./codex-vm stop codex-01
./codex-vm start codex-01
./codex-vm destroy codex-01
```

The 20 GiB guest disks and the 80 GiB host pool are thin-provisioned: physical
NVMe usage grows as blocks are written. Deleting a VM returns its blocks to the
pool, although the sparse loop file itself normally does not shrink.

## Mount Drives

Make sure you have exFAT support installed:

```bash
sudo apt install exfat-fuse exfat-utils
```

Create the mount point directory and change ownership of the mount point to your user:

```bash
sudo mkdir -p "/media/$USER/storage" && sudo chown $USER:$USER "/media/$USER/storage"
```

Add the line to fstab:

```bash
sudo nano /etc/fstab
```

Test the mount:

```bash
sudo mount -a
```

## Ports

| Port | Service                          |
| ---- | -------------------------------- |
| 53   | Pi-Hole DNS                      |
| 80   | NGINX Proxy Manager (HTTP)       |
| 81   | NGINX Proxy Manager Admin (HTTP) |
| 443  | NGINX Proxy Manager (HTTPS)      |
| 2283 | Immich (HTTP)                    |
| 8080 | Pi-Hole (HTTP)                   |
| 8443 | Pi-Hole (HTTPS)                  |
| 3389 | XRDP Server                      |

## Troubleshooting

When cannot connect to RDP try to terminate user session

```bash
loginctl terminate-user "$XRDP_USER"
```

## Web Services currently running in home network

- http://immich.myhome
- http://kavita.myhome
- http://n8n.myhome
- http://pihole.myhome
- http://proxymanager.myhome
