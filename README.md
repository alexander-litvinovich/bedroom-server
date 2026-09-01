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

Install Ansible and run the general package and SSH playbooks locally:

```bash
sudo apt update
sudo apt install -y ansible-core
ansible-playbook --ask-become-pass ansible/packages.yml
ansible-playbook --ask-become-pass ansible/power-management.yml
ansible-playbook --ask-become-pass ansible/ssh.yml
ansible-playbook --ask-become-pass ansible/tailscale.yml
ansible-playbook --ask-become-pass ansible/xrdp.yml
ansible-playbook --ask-become-pass ansible/docker.yml
ansible-playbook --ask-become-pass ansible/ohmyzsh.yml
sudo passwd rdpuser
```

`ansible/packages.yml` installs Git, GitHub CLI, Midnight Commander, Homebrew,
and RTK.
`ansible/power-management.yml` prevents suspend and hibernation and makes the
power button shut down the host.
`ansible/ssh.yml` installs OpenSSH, UFW, and Keychain; enables the SSH service;
allows SSH through UFW; installs `assets/ssh_config`; and configures Keychain for
the current user.
`ansible/tailscale.yml` installs Tailscale from its official APT repository,
starts `tailscaled`, and enables client automatic updates. Authenticate once with
`sudo tailscale up`.
`ansible/xrdp.yml` creates the `rdpuser` account and configures XRDP for it,
including its firewall rule and headless display configuration.
`ansible/docker.yml` installs Docker Engine from Docker's APT repository, enables
its services, and adds the current user to the `docker` group. Log out and back
in before using Docker without `sudo`.
`ansible/ohmyzsh.yml` installs Zsh and Oh My Zsh for the current user without
overwriting an existing `.zshrc`.

Run `preflight.sh` afterward for the software that has not yet been converted to
Ansible.

## VS Code Remote Tunnel

The `ansible/vscode-tunnel.yml` playbook installs the Microsoft Visual Studio
Code APT package, configures its APT repository, and creates a persistent
`code-tunnel.service`. The service runs as the account that invokes Ansible and
uses outbound connections only; no inbound firewall rule is required.

Install it locally:

```bash
ansible-playbook --ask-become-pass ansible/vscode-tunnel.yml
```

Configure the tunnel once. Choose a unique name in place of `bedroom-server`,
follow the device-login prompt using the GitHub or Microsoft account that will
access the server, and wait until a `vscode.dev/tunnel/...` URL is displayed:

```bash
sudo systemctl stop code-tunnel
code tunnel --name bedroom-server --accept-server-license-terms
```

Press `Ctrl-C` after the initial URL is displayed, then start and enable the
persistent service:

```bash
sudo systemctl enable --now code-tunnel
sudo systemctl status code-tunnel --no-pager
code tunnel status
```

Open the displayed `vscode.dev` URL, or use **Remote Tunnels: Connect to
Tunnel** in VS Code, and authenticate with the same account. To inspect service
logs, run `sudo journalctl -u code-tunnel -f`.

## Codex worker VMs

The worker setup uses Incus virtual machines so that every Codex/T3 identity,
workspace, Git checkout, Docker daemon, and session has its own filesystem and
machine identity. The guest account is always `vmuser`.

Copy `.env.example` to `.env`, set the `CODEX_VM_*` values, and reserve the
configured IP range outside the router's DHCP range. `CODEX_VM_PARENT_NIC` must
be the wired LAN interface from `ip -br link`. Reserve `CODEX_VM_HOST_IP`
immediately outside the worker range as well; the host uses this address for a
persistent macvlan shim that can reach the VMs. `CODEX_VM_STORAGE_SOURCE` must
point to an `.img` file on a persistent, non-root ext4 or xfs mount.
Incus only supports managed LVM loop files below `/var/lib/incus/disks`, so the
host playbook bind-mounts the configured file's directory there; the bytes still
reside on the selected SSD.

Install the one bootstrap dependency, then provision the host locally:

```bash
sudo apt update
sudo apt install -y ansible-core
set -a; source .env; set +a
ansible-playbook --ask-become-pass ansible/host.yml
```

If `codex-workers` already exists at another location and contains no instances,
migrate it to the configured storage source. This intentionally removes cached
and golden images, then asks you to rebuild them:

```bash
./codex-vm storage-migrate
set -a; source .env; set +a
ansible-playbook --ask-become-pass ansible/host.yml
./codex-vm image-build
./codex-vm doctor
```

Log out and back in once if Ansible added you to `incus-admin`. Build the golden
image and create workers:

```bash
test -f ~/.ssh/codex_workers.pub || ssh-keygen -t ed25519 -f ~/.ssh/codex_workers -C codex-workers
./codex-vm image-build
./codex-vm create codex-01
./codex-vm create codex-02
./codex-vm list
./codex-vm ssh-config
```

`create` installs local aliases in `~/.ssh/config.d/codex-vm`, so the Incus host
can connect directly with `ssh codex-01`. For VMs that existed before this was
configured, rerun the host playbook and reconcile the aliases:

```bash
set -a; source .env; set +a
ansible-playbook --ask-become-pass ansible/host.yml
./codex-vm ssh-config install
ssh codex-01
```

For another trusted computer on the LAN, securely transfer the shared private
key to `~/.ssh/codex_workers` on that computer and protect it:

```bash
chmod 600 ~/.ssh/codex_workers
ssh -i ~/.ssh/codex_workers vmuser@192.168.1.201
```

Paste the output of `./codex-vm ssh-config` into that computer's SSH config to
use aliases such as `ssh codex-01`. The private key must match
`CODEX_VM_SSH_PUBLIC_KEY`; never expose or commit it. All trusted LAN computers
share this credential, so rotate it everywhere if any one computer is
compromised.

On each VM, log in independently:

```bash
codex login --device-auth
gh auth login
```

Useful lifecycle commands:

```bash
./codex-vm doctor
./codex-vm storage-migrate
./codex-vm status codex-01
./codex-vm ssh codex-01
./codex-vm stop codex-01
./codex-vm start codex-01
./codex-vm destroy codex-01
```

The 20 GiB guest disks and the 60 GiB host pool are thin-provisioned: physical
SSD usage grows as blocks are written. Deleting a VM returns its blocks to the
pool, although the sparse loop file itself normally does not shrink. The current
pool lives at `/media/storage/incus/codex-workers.img` on the internal 2 TB SSD.

The same configuration can use a USB SSD only when it is formatted as ext4 or
xfs and mounted persistently by UUID before Incus starts. Do not use the current
HFS+ USB disk for VM storage; it must be backed up and reformatted first, and
disconnecting it while a VM is active can corrupt the VM.

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
loginctl terminate-user rdpuser
```

## Web Services currently running in home network

- http://immich.myhome
- http://kavita.myhome
- http://n8n.myhome
- http://pihole.myhome
- http://proxymanager.myhome
