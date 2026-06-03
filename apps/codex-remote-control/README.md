# Codex Remote Control

This app installs a systemd service that keeps `codex remote-control` running with remote control enabled when the server boots.

The systemd service is installed as a system unit, but Codex runs as the regular `alex` user. This keeps Codex credentials and config under `/home/alex/.codex`.

## Why there is a wrapper

Codex is installed through npm/nvm, so the concrete executable path can change after Node, npm, or Codex updates. The service does not call a fixed path like:

```bash
/home/alex/.nvm/versions/node/v20.3.0/bin/codex
```

Instead, systemd calls `codex-remote-control.sh`, which delegates the pseudo-TTY launch to `run-remote-control.sh`, and the wrapper resolves `codex` through `alex`'s login shell:

```bash
/usr/bin/zsh -lc 'exec apps/codex-remote-control/run-remote-control.sh'
```

## Ubuntu 24.04 sandbox note

Codex uses bubblewrap for the Linux sandbox. On this host `kernel.apparmor_restrict_unprivileged_userns=1` makes remote sessions fail when they try to start sandboxed work. The installer applies `codex-remote-control.sysctl.conf`, which sets `kernel.apparmor_restrict_unprivileged_userns=0`. This has a security tradeoff: it relaxes Ubuntu AppArmor restrictions for unprivileged user namespaces system-wide.

## Install

From the repository root:

```bash
sudo apps/codex-remote-control/install.sh
```

The installer:

- verifies that user `alex` exists
- verifies that `codex` is available in `alex`'s login shell
- installs `/etc/sysctl.d/99-codex-remote-control.conf` from `codex-remote-control.sysctl.conf` and applies it
- generates `/etc/systemd/system/codex-remote-control.service` from the current repository path
- enables the service for boot
- starts the service immediately

## Manage

```bash
sudo systemctl status codex-remote-control.service
sudo systemctl restart codex-remote-control.service
sudo systemctl stop codex-remote-control.service
sudo journalctl -u codex-remote-control.service -n 50 --no-pager
```

The local wrapper also has helper commands:

```bash
apps/codex-remote-control/codex-remote-control.sh status
apps/codex-remote-control/codex-remote-control.sh doctor
```

`start` and `doctor` must run as `alex`; systemd handles that via `User=alex`. The runtime script pipes an idle `tail -f /dev/null` into `script` from util-linux so systemd keeps stdin open while `script` provides the pseudo-TTY required by `codex remote-control`. It explicitly loads `~/.nvm/nvm.sh`, selects `nvm` default, and logs the resolved Codex executable to `~/.codex/remote-control/remote-control.log`.

## Uninstall

```bash
sudo apps/codex-remote-control/uninstall.sh
```

This stops and disables the systemd service, removes the installed unit file and sysctl config, and reloads systemd. It does not remove Codex, npm, nvm, or `/home/alex/.codex`.

## If the repository moves

The installed unit contains the absolute project path:

```text
/home/alex/dev/bedroom-server/apps/codex-remote-control/codex-remote-control.sh
```

If the repository is moved, run the installer again from the new location:

```bash
sudo apps/codex-remote-control/install.sh
```

## Upgrade check

After updating Codex with npm or `codex update`, restart the service:

```bash
sudo systemctl restart codex-remote-control.service
sudo systemctl status codex-remote-control.service
```

Because the runtime wrapper loads `~/.nvm/nvm.sh` and uses the `nvm` default Node version, no unit edit should be needed after normal npm/nvm updates.
