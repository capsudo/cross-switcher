#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "--inside-dbus-session" ]]; then
  # Run this same script inside temporary DBus session.
  exec dbus-run-session -- bash "$0" --inside-dbus-session
fi

extension_uuid="cross-switcher@capsudo.github.com"
devkit_profile_dir="${XDG_RUNTIME_DIR:-/tmp}/cross-switcher-gnome-devkit-profile"
devkit_dconf_profile="$devkit_profile_dir/dconf-profile"

# Use clean GNOME settings, so only wanted extensions are enabled.
mkdir -p \
  "$devkit_profile_dir/config" \
  "$devkit_profile_dir/config-dirs" \
  "$devkit_profile_dir/cache" \
  "$devkit_profile_dir/state"

export XDG_CONFIG_HOME="$devkit_profile_dir/config"
export XDG_CONFIG_DIRS="$devkit_profile_dir/config-dirs"
export XDG_CACHE_HOME="$devkit_profile_dir/cache"
export XDG_STATE_HOME="$devkit_profile_dir/state"

printf 'user-db:user\n' > "$devkit_dconf_profile"
export DCONF_PROFILE="$devkit_dconf_profile"

# GNOME Shell from flake needs matching schemas from same dev shell.
if [[ -z "${GSETTINGS_SCHEMA_DIR:-}" ]]; then
  echo "GSETTINGS_SCHEMA_DIR is empty. Run from direnv/Nix dev shell so GNOME schemas match GNOME Shell." >&2
  exit 1
fi

# Set wanted extension list before GNOME Shell scans settings.
gsettings set org.gnome.shell enabled-extensions "[\"$extension_uuid\"]"
gsettings set org.gnome.shell disabled-extensions "[]"
gsettings set org.gnome.shell disable-user-extensions false

echo "Using isolated GNOME profile: $devkit_profile_dir"
echo "Launching GNOME Shell from: $(command -v gnome-shell)"
gnome-shell --version

gnome-shell --devkit --wayland &
gnome_shell_process_id="$!"

# Wait until nested shell owns its DBus name before calling extension commands.
# If shell exits early, wait prints its real startup error before this script fails.
if ! gdbus wait --session --timeout 30 org.gnome.Shell; then
  echo "GNOME Shell did not appear on nested DBus session" >&2
  wait "$gnome_shell_process_id" || true
  exit 1
fi

# GNOME Shell can appear before it has scanned extensions.
# Wait until Cross Switcher exists, then enable it.
extension_found=false

for _ in {1..60}; do
  if ! kill -0 "$gnome_shell_process_id" 2>/dev/null; then
    echo "GNOME Shell exited before Cross Switcher became visible" >&2
    wait "$gnome_shell_process_id" || true
    exit 1
  fi

  if gnome-extensions info "$extension_uuid" >/dev/null 2>&1; then
    extension_found=true
    break
  fi

  sleep 1
done

if [[ "$extension_found" == "true" ]]; then
  gnome-extensions enable "$extension_uuid"
  echo "Enabled $extension_uuid"
else
  echo "Extension $extension_uuid is not visible to nested GNOME Shell" >&2
fi

wait "$gnome_shell_process_id"
