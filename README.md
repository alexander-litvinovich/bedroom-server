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

TBD:

- [ ] Ollama
- [ ] Some private cloud storage
- [ ] Git repo (gitea?)

## How to install and make it run

Start by installing packages from `preflight.sh`

To enable SSH access use `ssh.sh` it installs OpenSSH Uncomplicated Firewall (UFW) Keychain. Set up SSH server as a daemon, opens 22 port in UFW and applying SSH configuration from `assets/ssh_config`. Also it adds SSH agent autostart to `~/.zshrc`.

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
