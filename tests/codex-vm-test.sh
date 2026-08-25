#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export CODEX_VM_NO_MAIN=1
# shellcheck disable=SC1091
source "$ROOT_DIR/codex-vm"

valid_name codex-01
if valid_name 01-codex || valid_name codex-; then exit 1; fi
valid_user vmuser
if valid_user 'VM User'; then exit 1; fi
valid_ipv4 192.168.1.201
if valid_ipv4 192.168.1.999; then exit 1; fi
[[ "$(ip_to_int 192.168.1.1)" == 3232235777 ]]
[[ "$(int_to_ip 3232235777)" == 192.168.1.1 ]]

CODEX_VM_CIDR=192.168.1.0/24
CODEX_VM_HOST_IP=192.168.1.200
CODEX_VM_GATEWAY=192.168.1.1
CODEX_VM_DNS=192.168.1.1
CODEX_VM_IP_START=192.168.1.201
CODEX_VM_IP_END=192.168.1.220
validate_network_config
[[ "$(worker_route_cidrs)" == $'192.168.1.201/32\n192.168.1.202/31\n192.168.1.204/30\n192.168.1.208/29\n192.168.1.216/30\n192.168.1.220/32' ]]
if (CODEX_VM_HOST_IP=192.168.1.202; validate_network_config) 2>/dev/null; then exit 1; fi
CODEX_VM_IP_END=192.168.1.203

incus() {
  printf '%s\n' '[{"config":{"user.codex-vm.managed":"true","user.codex-vm.ipv4":"192.168.1.201"}}]'
}
[[ "$(allocate_ip)" == 192.168.1.202 ]]

CODEX_VM_GUEST_USER=vmuser
CODEX_VM_SSH_IDENTITY='~/.ssh/codex_workers'
ssh_config=$(render_ssh_config)
[[ "$ssh_config" == *'HostName 192.168.1.201'* ]]
[[ "$ssh_config" == *'User vmuser'* ]]
[[ "$ssh_config" == *'IdentityFile ~/.ssh/codex_workers'* ]]

test_home=$(mktemp -d)
trap 'rm -rf -- "$test_home"' EXIT
HOME=$test_home
install -d -m 0700 "$HOME/.ssh"
printf 'Host github.com\n    User git\n' >"$HOME/.ssh/config"
install_ssh_config >/dev/null
[[ "$(head -n 1 "$HOME/.ssh/config")" == 'Include ~/.ssh/config.d/codex-vm' ]]
grep -Fq 'Host github.com' "$HOME/.ssh/config"
grep -Fq 'HostName 192.168.1.201' "$HOME/.ssh/config.d/codex-vm"
[[ "$(stat -c %a "$HOME/.ssh/config.d")" == 700 ]]
[[ "$(stat -c %a "$HOME/.ssh/config.d/codex-vm")" == 600 ]]
install_ssh_config >/dev/null
[[ "$(grep -Fxc 'Include ~/.ssh/config.d/codex-vm' "$HOME/.ssh/config")" == 1 ]]

CODEX_VM_STORAGE_SOURCE=/mnt/storage/incus/codex-workers.img
CODEX_VM_STORAGE_SIZE=60GiB
CODEX_VM_STORAGE_POOL=codex-workers
CODEX_VM_PROFILE=codex-worker
CODEX_VM_DISK_SIZE=20GiB
findmnt() { printf '/mnt/storage ext4 rw,noatime\n'; }
df() { printf 'Avail\n1000000000000\n'; }
validate_storage_config
[[ "$STORAGE_MOUNT" == /mnt/storage ]]
[[ "$STORAGE_FSTYPE" == ext4 ]]
[[ "$STORAGE_SIZE_BYTES" == 64424509440 ]]
require_storage_capacity

findmnt() { printf '/ ext4 rw,relatime\n'; }
if (validate_storage_config) 2>/dev/null; then exit 1; fi
findmnt() { printf '/mnt/storage hfsplus rw,noatime\n'; }
if (validate_storage_config) 2>/dev/null; then exit 1; fi
findmnt() { printf '/mnt/storage ext4 rw,noatime\n'; }
df() { printf 'Avail\n1000\n'; }
validate_storage_config
if (require_storage_capacity) 2>/dev/null; then exit 1; fi

migration_log="$test_home/migration.log"
: >"$migration_log"
df() { printf 'Avail\n1000000000000\n'; }
incus() {
  printf '%s\n' "$*" >>"$migration_log"
  case "$*" in
    'storage show codex-workers') return 0 ;;
    'storage get codex-workers source') printf '/var/lib/incus/disks/codex-workers.img\n' ;;
    'storage get codex-workers size') printf '80GiB\n' ;;
    'list --format=json') printf '[{"name":"busy","expanded_devices":{"root":{"pool":"codex-workers"}}}]\n' ;;
  esac
}
if (cmd_storage_migrate --force) 2>/dev/null; then exit 1; fi
! grep -Fq 'image delete' "$migration_log"
! grep -Fq 'storage delete' "$migration_log"

: >"$migration_log"
incus() {
  printf '%s\n' "$*" >>"$migration_log"
  case "$*" in
    'storage show codex-workers') return 0 ;;
    'storage get codex-workers source') printf '/var/lib/incus/disks/codex-workers.img\n' ;;
    'storage get codex-workers size') printf '80GiB\n' ;;
    'list --format=json') printf '[]\n' ;;
    'query /1.0/storage-pools/codex-workers') printf '{"used_by":["/1.0/images/image-one","/1.0/profiles/codex-worker"]}\n' ;;
  esac
}
create_storage_pool() { printf 'create_storage_pool\n' >>"$migration_log"; }
ensure_profile_root() { printf 'ensure_profile_root\n' >>"$migration_log"; }
install_ssh_config() { return 0; }
storage_bind_active() { return 0; }
cmd_storage_migrate --force >/dev/null
grep -Fq 'image delete image-one' "$migration_log"
grep -Fq 'profile device remove codex-worker root' "$migration_log"
grep -Fq 'storage delete codex-workers' "$migration_log"
grep -Fq 'create_storage_pool' "$migration_log"
grep -Fq 'ensure_profile_root' "$migration_log"

printf 'codex-vm self-check passed\n'
