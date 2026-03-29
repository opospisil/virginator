# virginator

Install scripts to automate Arch linux installation and make reclaiming ones virginity a breeze.

- UEFI only
- pre-partitioned disk only
- `EFI` + `ROOT` + `HOME`, with optional `VAULT`
- format only `EFI` and `ROOT`
- preserve `HOME`
- leave `VAULT` locked until the system is fully installed when present
- create a completely fresh primary user and migrate old data manually

## Design goals

- keep the default package set short and reviewable
- install `i3`, `lemurs`, `fish`, `alacritty`, `tmux`, PipeWire, OpenVPN, YubiKey and fingerprint tooling
- keep Neovim nightly, Go, Node.js, and Bitwarden CLI in user space instead of pacman
- prefer Podman over Docker for dev containers
- avoid touching old home directories or the encrypted vault during base install
- use `NetworkManager` with `iwd` as the Wi-Fi backend and disable Wi-Fi powersave by default

## Repository layout

- `bootstrap.sh` runs from the Arch ISO and drives the live install phase
- `config/defaults.sh` defines common defaults
- `config/machines/example.sh` is the template for machine-specific values
- `live/` contains the ISO-time scripts
- `chroot/` contains the first pass inside the installed system
- `post-root/` runs on the installed machine as root after first boot
- `post-user/` runs as the fresh user after first boot
- `packages/` contains reviewed package bundles
- `scripts/` contains reusable helpers like the vault, Neovim nightly, Go, Node, and Bitwarden installers
- `scripts/` also contains opt-in YubiKey and fingerprint enrollment/PAM helpers
- `skel/user/` contains initial user config files for `fish`, `i3`, and `alacritty`

`lemurs` is the default display manager. The repo still keeps a simple `.xinitrc` fallback, but the normal login path is through lemurs.

The installed repo lives under `/opt/virginator`, including the active machine config at `/opt/virginator/config/current.sh`, so both root and the fresh user can run the follow-up phases.

The default networking stack is `NetworkManager` with `iwd` as the Wi-Fi backend. The installer also disables NetworkManager Wi-Fi powersave by default to avoid overly aggressive laptop power saving.

## Expected partition contract

The installer assumes these partitions already exist and are identifiable by `PARTLABEL` or another `blkid` token:

- `BOOT_PARTITION` for the EFI system partition
- `ROOT_PARTITION` for the new system root
- `HOME_PARTITION` for the preserved home partition
- optional `VAULT_PARTITION` for the encrypted vault

Default config uses:

```bash
BOOT_PARTITION="PARTLABEL=EFI"
ROOT_PARTITION="PARTLABEL=ROOT"
HOME_PARTITION="PARTLABEL=HOME"
VAULT_ENABLED="yes"
VAULT_PARTITION="PARTLABEL=VAULT"
```

`HOME` must already be `ext4`. If `VAULT_ENABLED="yes"`, `VAULT` must already be `LUKS`.

For a machine without the encrypted vault, set:

```bash
VAULT_ENABLED="no"
VAULT_PARTITION=""
```

## Fresh user workflow

The scripts intentionally create a brand-new user. If `/home/<new-user>` already exists on the preserved home partition, it is renamed to `/home/<new-user>.old-YYYYmmdd-HHMMSS` before the fresh home is created.

That lets you:

- keep old home directories on the preserved home partition
- log into a clean account with clean dotfiles
- manually copy or symlink only the pieces you still want
- keep a timestamped backup of any previous home for the same username
- use the same shared install tree and readable machine config for both root and user phases

## Quick start

1. Boot the Arch ISO and connect to Wi-Fi:

```bash
iwctl
# inside iwctl:
#   device list
#   station wlan0 scan
#   station wlan0 get-networks
#   station wlan0 connect "your-ssid"
#   exit
```

Replace `wlan0` with the real wireless device shown by `iwctl device list`.

2. Download and run the live ISO bootstrap helper:

```bash
curl -O https://raw.githubusercontent.com/opospisil/virginator/master/preinstall.sh
sudo bash preinstall.sh
cd virginator
```

This sets `DisablePowerSave=true` in `/etc/iwd/main.conf`, restarts `iwd`, refreshes mirrors, installs `reflector`, `git`, `skim`, and clones the repo.

3. Generate the partition selector file:

```bash
./scripts/select-partitions.sh
```

This writes `config/generated-partitions.sh`, which is auto-loaded by the installer when present.

If you prefer the non-interactive path, you can still generate the same snippet manually:

```bash
./scripts/extract-partuuids.sh /dev/nvme0n1p1 /dev/nvme0n1p2 /dev/nvme0n1p3 /dev/nvme0n1p4 > config/generated-partitions.sh
```

4. Copy `config/machines/example.sh` to your real machine config and fill in the values.
5. Run the live install phase:

```bash
cp config/machines/example.sh config/machines/my-machine.sh
sudo ./bootstrap.sh config/machines/my-machine.sh
```

6. Reboot into the installed system.
7. Run the system phase as root:

During the chroot phase, the installer prompts interactively for the root password and the fresh user's password.

```bash
sudo /opt/virginator/post-root/run.sh
```

8. Reboot or switch to `lemurs`, log in as the new user, and run the user phase:

```bash
/opt/virginator/post-user/run.sh
```

9. If vault support is enabled for the machine, mount the vault manually when you are ready:

```bash
sudo /opt/virginator/scripts/mount-vault.sh
```

10. Optionally run the smoke test:

```bash
/opt/virginator/scripts/smoke-test.sh
sudo /opt/virginator/scripts/smoke-test.sh
```

If Wi-Fi is not up on first boot, use one of these before assuming the install is bad:

```bash
nmtui
nmcli device wifi list
iwctl
```

## Package Stages

- `preinstall.sh`: live ISO bootstrap tools only - `reflector`, `git`, `skim`
- `packages/bootstrap.txt`: minimal pacstrap set for the fresh system
- `packages/base.txt`, `packages/desktop-i3.txt`, `packages/audio.txt`, `packages/auth.txt`, `packages/containers.txt`: post-root pacman installs
- `AUR_HELPER_PACKAGE` and `AUR_PACKAGES` in `config/defaults.sh`: post-user AUR installs

That keeps the package sources grouped by install stage instead of scattering package names through scripts.

## Optional authentication setup

Authentication changes stay opt-in and manual.

- YubiKey enrollment as the fresh user: `scripts/enroll-yubikey.sh`
- Add another key later: `scripts/enroll-yubikey.sh --append`
- Enable YubiKey PAM auth for `sudo` with password fallback: `sudo scripts/configure-yubikey-auth.sh enable sudo`
- Enable YubiKey auth for the lemurs login screen: `sudo scripts/configure-yubikey-auth.sh enable lemurs`
- Also enable YubiKey for console login if wanted: `sudo scripts/configure-yubikey-auth.sh enable login`
- Fingerprint enrollment: `sudo scripts/enroll-fingerprint.sh right-index-finger`
- Enable fingerprint auth for the lemurs login screen: `sudo scripts/configure-fingerprint-auth.sh enable lemurs`
- Also enable fingerprint auth for console login if wanted: `sudo scripts/configure-fingerprint-auth.sh enable login`

The PAM helper scripts always keep password fallback in place, write backups as `*.virginator.bak`, and are intentionally separate from the main install flow.

For the normal graphical setup, the `lemurs` target is usually the one you want. Only add the `login` target if you also want console TTY login.

Fingerprint setup is limited to lemurs or console login. It is intentionally not wired into `sudo` or `polkit` because that is considered unsafe.

## Package bundles

The default install is split into:

- `packages/bootstrap.txt`
- `packages/base.txt`
- `packages/desktop-i3.txt`
- `packages/audio.txt`
- `packages/auth.txt`
- `packages/containers.txt`

Optional extras reviewed from the current package inventory live under `packages/optional/`.

Neovim is not installed from pacman in the default flow. `post-user/run.sh` installs the nightly build into `~/.local/opt/neovim-nightly` and symlinks `~/.local/bin/nvim`.

The post-user phase also bootstraps the configured AUR helper and installs the configured AUR packages from `AUR_PACKAGES`.

The default desktop flow is `lemurs` -> `i3`.

## Current limits

- no automatic partitioning
- no automatic PAM edits during install; YubiKey and fingerprint setup stays opt-in
- no automatic migration from old home directories or vault content

That keeps v1 focused on a safe reinstall path first.
