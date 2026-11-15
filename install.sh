#!/usr/bin/env bash
# Install the Medal-Linux clipping glue: gpu-screen-recorder plus the clip
# scripts, shared config and panel launcher. Idempotent; safe to re-run.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/gpu-clips"
APPS="$HOME/.local/share/applications"

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }

# --- 1. clipping engine ------------------------------------------------------
if command -v gpu-screen-recorder >/dev/null 2>&1; then
    say "gpu-screen-recorder already installed"
elif command -v pacman >/dev/null 2>&1; then
    say "installing gpu-screen-recorder (pacman)"
    sudo pacman -S --needed --noconfirm gpu-screen-recorder
else
    say "building gpu-screen-recorder from source into ~/.local"
    src="$HOME/.local/src"
    mkdir -p "$src" "$HOME/.local/include"
    [ -d "$src/gpu-screen-recorder" ] ||
        git clone --depth 1 https://repo.dec05eba.com/gpu-screen-recorder "$src/gpu-screen-recorder"
    # Vulkan headers are only needed to compile the (optional) av1/vulkan path.
    if [ ! -f "$HOME/.local/include/vulkan/vulkan.h" ]; then
        git clone --depth 1 https://github.com/KhronosGroup/Vulkan-Headers "$src/Vulkan-Headers"
        cp -r "$src/Vulkan-Headers/include/vulkan" "$src/Vulkan-Headers/include/vk_video" \
              "$HOME/.local/include/"
    fi
    cd "$src/gpu-screen-recorder"
    rm -rf build
    CFLAGS="-I$HOME/.local/include" meson setup build --buildtype=release -Dstrip=true \
        -Dprefix="$HOME/.local" -Dcapabilities=false -Dsystemd=false -Dnvidia_suspend_fix=false
    ninja -C build install
fi

# --- 2. clip scripts ---------------------------------------------------------
say "installing scripts to $BIN"
mkdir -p "$BIN"
install -m 755 "$REPO"/bin/clip-start "$REPO"/bin/clip-save \
               "$REPO"/bin/clip-saved-notify "$REPO"/bin/clip-ui "$BIN"/

# --- 3. shared config --------------------------------------------------------
mkdir -p "$CONFIG_DIR" "$HOME/Videos/Clips"
if [ -f "$CONFIG_DIR/config.env" ]; then
    say "keeping existing $CONFIG_DIR/config.env"
else
    say "creating $CONFIG_DIR/config.env"
    install -m 644 "$REPO"/configs/config.env.example "$CONFIG_DIR/config.env"
fi

# --- 4. panel launcher -------------------------------------------------------
if command -v python3 >/dev/null 2>&1 &&
   python3 -c 'import gi; gi.require_version("Gtk","4.0")' >/dev/null 2>&1; then
    mkdir -p "$APPS"
    sed "s|@HOME@|$HOME|g" "$REPO"/configs/clip-ui.desktop >"$APPS/clip-ui.desktop"
    say "added Clips launcher entry"
else
    say "python-gobject (GTK4) missing - the panel needs it; hotkeys still work"
fi

# --- 5. start the buffer now -------------------------------------------------
"$BIN/clip-start" || true

say "done"
cat <<EOF

Next step: bind the hotkeys in your compositor, e.g. for Hyprland add

    hl.exec_cmd("\$HOME/.local/bin/clip-start")     -- in hyprland.start
    hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd("\$HOME/.local/bin/clip-save"), ...)

or copy the lines from $REPO/hyprland/clip-keybinds.lua
Clips are saved to $HOME/Videos/Clips
EOF
