#!/usr/bin/env bash
# Shared helpers for abinstall-gui backend step scripts.
# Sourced by every backend/steps/step-* script — never executed directly.

MNT="/mnt"
LIVE_USER="live"
STATE_DIR="/run/abinstall-gui"
STATE_FILE="${STATE_DIR}/state.env"

mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

# --- protocol emitters -------------------------------------------------
# Line protocol read by InstallController.qml's SplitParser on stdout.
# pct is 0-100. message must not contain literal newlines.
emit_progress() { # pct message
  printf 'PROGRESS pct=%d message=%q\n' "$1" "$2"
}
emit_error() { # code message
  printf 'ERROR code=%s message=%q\n' "$1" "$2"
}
emit_result() { # status(success|error) step
  printf 'RESULT status=%s step=%s\n' "$1" "$2"
}

# --- persisted install state --------------------------------------------
# Each step runs as its own process, so decisions made in step 1 (which
# device, which partitions, UEFI or BIOS) must survive to steps 3 and 4.
state_set() { # key value
  local key="$1" value="$2"
  touch "$STATE_FILE"
  chmod 600 "$STATE_FILE"
  sed -i "/^${key}=/d" "$STATE_FILE"
  printf '%s=%q\n' "$key" "$value" >>"$STATE_FILE"
}
state_get() { # key
  local key="$1"
  [[ -f "$STATE_FILE" ]] || return 0
  local line
  line=$(grep "^${key}=" "$STATE_FILE" | tail -1)
  [[ -n "$line" ]] && eval "printf '%s' \"\${line#${key}=}\""
}
state_load_all() {
  [[ -f "$STATE_FILE" ]] && source "$STATE_FILE"
}

# --- common checks --------------------------------------------------------
require_root() {
  if [[ "$(id -u)" != "0" ]]; then
    emit_error "not_root" "This step must run as root."
    emit_result "error" "$1"
    exit 1
  fi
}

detect_uefi() {
  if [[ -d /sys/firmware/efi ]]; then
    echo 1
  else
    echo 0
  fi
}

partition_suffix() { # device
  [[ "$1" =~ (nvme|mmcblk) ]] && echo "p" || echo ""
}

arch_chroot() { # command-string
  arch-chroot "$MNT" /bin/bash -c "$1"
}

# Run a command, aborting the step with a protocol ERROR+RESULT on failure.
run_or_die() { # step_name error_code error_message command...
  local step="$1" code="$2" msg="$3"
  shift 3
  if ! "$@"; then
    emit_error "$code" "$msg"
    emit_result "error" "$step"
    exit 1
  fi
}
