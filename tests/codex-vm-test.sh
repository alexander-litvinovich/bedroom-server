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
CODEX_VM_GATEWAY=192.168.1.1
CODEX_VM_DNS=192.168.1.1
CODEX_VM_IP_START=192.168.1.201
CODEX_VM_IP_END=192.168.1.203
validate_network_config

incus() {
  printf '%s\n' '[{"config":{"user.codex-vm.managed":"true","user.codex-vm.ipv4":"192.168.1.201"}}]'
}
[[ "$(allocate_ip)" == 192.168.1.202 ]]

printf 'codex-vm self-check passed\n'
