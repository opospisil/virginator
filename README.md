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
- install `i3`, `fish`, `alacritty`, `tmux`, PipeWire, OpenVPN, YubiKey and fingerprint tooling
- keep Neovim nightly, Go, Node.js, and Bitwarden CLI in user space instead of pacman
- prefer Podman over Docker for dev containers
- avoid touching old home directories or the encrypted vault during base install

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

The scripts intentionally create a brand-new user and refuse to reuse an existing home directory at `/home/<new-user>`.

That lets you:

- keep old home directories on the preserved home partition
- log into a clean account with clean dotfiles
- manually copy or symlink only the pieces you still want

## Quick start

1. Boot the Arch ISO and connect to the network.
2. Clone the repo over HTTPS.
3. Copy `config/machines/example.sh` to your real machine config and fill in the values.
4. Run the live install phase:

```bash
git clone https://github.com/opospisil/virginator.git
cd virginator
cp config/machines/example.sh config/machines/my-machine.sh
sudo ./bootstrap.sh config/machines/my-machine.sh
```

5. Reboot into the installed system.
6. Run the system phase as root:

```bash
sudo /usr/local/src/virginator/post-root/run.sh
```

7. Log in as the new user and run the user phase:

```bash
/usr/local/src/virginator/post-user/run.sh
```

8. If vault support is enabled for the machine, mount the vault manually when you are ready:

```bash
sudo /usr/local/src/virginator/scripts/mount-vault.sh
```

9. Optionally run the smoke test:

```bash
/usr/local/src/virginator/scripts/smoke-test.sh
sudo /usr/local/src/virginator/scripts/smoke-test.sh
```

## Optional authentication setup

Authentication changes stay opt-in and manual.

- YubiKey enrollment as the fresh user: `scripts/enroll-yubikey.sh`
- Add another key later: `scripts/enroll-yubikey.sh --append`
- Enable YubiKey PAM auth with password fallback: `sudo scripts/configure-yubikey-auth.sh enable sudo`
- Also enable YubiKey for login if wanted: `sudo scripts/configure-yubikey-auth.sh enable login`
- Fingerprint enrollment: `sudo scripts/enroll-fingerprint.sh right-index-finger`
- Enable fingerprint login: `sudo scripts/configure-fingerprint-auth.sh enable login`

The PAM helper scripts always keep password fallback in place, write backups as `*.virginator.bak`, and are intentionally separate from the main install flow.

Fingerprint setup is limited to login only. It is intentionally not wired into `sudo` or `polkit` because that is considered unsafe.

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

## Current limits

- no automatic partitioning
- no automatic PAM edits during install; YubiKey and fingerprint setup stays opt-in
- no display manager yet; the default user flow is `startx`
- no automatic migration from old home directories or vault content

That keeps v1 focused on a safe reinstall path first.
