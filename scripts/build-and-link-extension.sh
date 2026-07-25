#!/usr/bin/env bash
set -euo pipefail

extension_uuid="cross-switcher@capsudo.github.com"
extension_link="$HOME/.local/share/gnome-shell/extensions/$extension_uuid"

make all

mkdir -p ~/.local/share/gnome-shell/extensions
ln -sfnT "$PWD" "$extension_link"
ls -ld "$extension_link"

test "$(readlink "$extension_link")" = "$PWD"
