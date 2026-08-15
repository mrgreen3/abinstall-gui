# abinstall-gui

A graphical, Quickshell/QML-based installer framework for ArchBang (and
Arch-derived ISOs, e.g. GreenBang). Wraps the same privileged install logic
as [abinstall](https://github.com/mrgreen3/abinstaller), the existing
terminal installer, behind a 4-step wizard.

## Overview

The GUI covers a deliberately narrow slice of what `abinstall` does:

1. **Partition Disk** — auto-partitions a selected device (GPT, EFI + swap
   + root, swap sized from installed RAM, no swap partition above 8GiB RAM),
   formats, and mounts it at `/mnt`.
2. **Create User** — validates a username and hashes the password. The
   account itself isn't created yet — see [Design notes](#design-notes).
3. **Copy System Files** — copies the live airootfs to the target disk,
   syncs any persistent live-session overlay changes, writes `fstab`,
   configures `mkinitcpio`, and (as its final act) creates the user account
   staged in step 2.
4. **Install Bootloader** — installs and configures GRUB for the detected
   boot mode (UEFI or BIOS).

There's no manual partitioning, LVM, LUKS, or locale/timezone/mirror
configuration in this GUI — it's scoped to the auto-partition path only.
Anything more advanced is `abinstall`'s job.

## Architecture

QML never touches disks directly. The wizard is a thin UI over a
root-privileged bash backend:

```
qml/                          Quickshell/QML UI
├── main.qml                  window + wizard shell
├── InstallController.qml     singleton: state machine, Process{} orchestration
├── components/                ABButton, ABStepIndicator, ABProgressView, ABConfirmDialog
└── steps/                     one page per wizard step

backend/                       root-privileged bash
├── abinstall-gui-runner       single dispatcher (allowlisted step names)
├── lib/common.sh              PROGRESS/ERROR/RESULT emitters, state persistence
└── steps/                     step-01-partition, step-02-user, step-03-copy, step-04-bootloader
```

Each step script is invoked as `abinstall-gui-runner <step> [args]` via
`sudo -n` (the Quickshell process itself runs as the unprivileged live
user), and speaks a simple line protocol on stdout that
`InstallController.qml` parses to drive the progress bar and log view:

```
PROGRESS pct=<0-100> message="..."
ERROR code=<slug> message="..."
RESULT status=<success|error> step=<name>
```

Decisions made in one step (selected device, UEFT/BIOS mode, partition
paths, staged user credentials) are persisted to `/run/abinstall-gui/state.env`
(mode 600, root-owned) so later steps — run as separate processes — can
read them back.

## Design notes

- **User creation is deferred to step 3.** `useradd` needs to run inside
  the target chroot, which needs the target rootfs's own `useradd`/`passwd`
  binaries — those don't exist until step 3 has copied the airootfs across.
  So step 2 only validates the username and hashes the password (`openssl
  passwd -6`, run from the live environment); step 3 creates the account
  at the end, using the staged hash. This keeps the wizard's step order
  (user before copy) while the privileged work happens in the order it
  actually has to.
- **Passwords never touch argv.** They're piped to the step script's stdin,
  not passed as a command-line argument — argv is visible to every user on
  the system via `/proc`.
- Backend step scripts are close ports of `abinstall`'s
  `auto_partition_disk`, `install_archbang` (+ `configure_fstab` +
  `configure_mkinitcpio`), and `configure_bootloader` — interactive prompts,
  `select` menus, and LUKS/LVM handling stripped out, since this GUI only
  offers the auto-partition path.

## Requirements

Runs from an Arch-derived live ISO with `quickshell` installed system-wide,
and a live user with passwordless (`NOPASSWD`) `wheel` sudo — both already
true on ArchBang/GreenBang live images. Backend scripts additionally need:
`parted`, `dosfstools`, `e2fsprogs`, `arch-install-scripts` (`arch-chroot`,
`genfstab`), `grub`, `pv`, `rsync`, `openssl`.

## Usage

```sh
quickshell -p qml/main.qml
```

Intended to be installed to `/usr/lib/abinstall-gui/` on the target ISO and
launched via a wrapper script (see GreenBang's `Scripts/install-gui` for an
example integration).

## Status

Scaffolded and QML-verified (`qmllint` clean, wizard renders and lists real
disks under quickshell), but the four step scripts have not yet been run
for real — they're genuinely destructive (`parted`, `mkfs`, `useradd`,
`grub-install`) and only want testing in a VM or on a live ISO, not on a
daily-driver machine.

## License

GPL-3.0-or-later — see LICENSE file for details. Backend step scripts are
derived from `abinstall`, which carries the same license.

## Credits

- Backend logic derived from [abinstaller](https://github.com/mrgreen3/abinstaller) (Mr Green, mrgreen@archbang.org)
- Original abinstall author: helmuthdu (helmuthdu@gmail.com)
