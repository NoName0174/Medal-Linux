# Medal-Linux

A Medal.tv / ShadowPlay-style clipper for Linux desktops (built and tested on
CachyOS + Hyprland + Intel, Wayland).

Press a key, keep the last N seconds. Nothing is written to disk until you ask
for it: a replay buffer keeps the last minute of screen + game audio +
microphone in RAM, and a hotkey writes out the part you want.

There is **no Medal client for Linux** (Medal is Windows-only and its capture
driver hooks the GPU directly), so this reproduces the part that matters: the
instant-replay clip flow, plus a small control panel and a clip library.

## Features

- **Instant replay** of the last 15 / 30 / 60 s (one 60 s buffer serves every
  length -- saving does not re-encode).
- **Game audio + microphone**, mixed into a single track (`opus`, 48 kHz).
  Microphone can be toggled at runtime.
- **GPU encoding** via `gpu-screen-recorder` (VAAPI/NVENC), so clipping costs a
  few percent of the GPU and the buffer never touches the CPU.
- **Control panel** (`clip-ui`, GTK4): buffer status, clip buttons, monitor
  picker, buffer length, mic switch, recent clips with a Play button.
- **Notifications** with the clip name and size, plus a desktop notification.
- Clips land in `~/Videos/Clips` as `Replay_<date>_<time>.mp4`.

## Requirements

- Linux with Wayland (X11 also works) and PipeWire.
- `gpu-screen-recorder` >= 6.1 (ShadowPlay-like capture/encode engine).
- For the panel: `python-gobject` (GTK4) -- `python3 -c 'import gi; gi.require_version("Gtk","4.0")'`.
- Hyprland for the hotkeys below (any WM works, you just bind the commands
  yourself).

## Install

```sh
git clone https://github.com/NoName0174/Medal-Linux
cd Medal-Linux
./install.sh
```

`install.sh` installs `gpu-screen-recorder` (pacman if available, otherwise
builds it per-architecture from source into `~/.local`), copies the scripts to
`~/.local/bin`, creates `~/.config/gpu-clips/config.env`, and adds the panel
launcher entry. It never touches system files outside the package install.

Then add the hotkeys (Hyprland: `hyprland/clip-keybinds.lua`, or copy the lines
into `~/.config/hypr/hyprland/keybinds.lua`) and the autostart line:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("$HOME/.local/bin/clip-start")
end)
```

`clip-start` is idempotent, so you can also launch it from a terminal or call it
from any clip hotkey -- it starts the buffer if it is not already running.

## Hotkeys (defaults)

| Key | Action |
| --- | --- |
| `Ctrl+Alt+V` | Save the last 30 s (default length from config) |
| `Ctrl+Alt+1` | Save the last 15 s |
| `Ctrl+Alt+2` | Save the last 30 s |
| `Ctrl+Alt+3` | Save the last 60 s |
| `Super+Alt+V` | Open the Clips panel |

Saves snap to the nearest keyframe, so a "15 s" clip is usually 15-17 s.

## Configuration

`~/.config/gpu-clips/config.env` (also editable from the panel):

```
CLIP_SECONDS=30            # default length for `clip-save` with no argument
CLIP_BUFFER_SECONDS=60     # RAM buffer; must be >= the longest clip you want
CLIP_MONITOR=""            # empty = active monitor at start; or eDP-1 / HDMI-A-1
CLIP_AUDIO="default_output|default_input"   # game audio + mic ("|" mixes)
CLIP_FPS=60
CLIP_QUALITY=18000         # CBR bitrate in kbit/s
```

Values are quoted: the file is sourced by bash, and an unquoted `a|b` would be
parsed as a pipe rather than a value.

RAM use is roughly `CLIP_BUFFER_SECONDS * CLIP_QUALITY / 8 / 1024` MB (~135 MB
for 60 s at 18 Mbit/s). Clip output size is proportional to the saved length.

Microphone only: `CLIP_AUDIO="default_input"`. Game audio only:
`CLIP_AUDIO="default_output"`. Easy Effects mic chain:
`CLIP_AUDIO="default_output|ee_source_group"`.

## How it works

- `bin/clip-start` launches `gpu-screen-recorder` in replay mode (`-r 60`, CBR,
  IPC socket), detached in its own session, and writes its PID to
  `$XDG_RUNTIME_DIR/gsr-replay.pid`.
- `bin/clip-save [seconds]` asks the running buffer for exactly N seconds over
  the IPC socket (`gsr-cli save-replay N`), falling back to `SIGUSR1` (whole
  buffer) if the socket is gone.
- `bin/clip-saved-notify` is the `-sc` hook: it runs once a clip is written and
  shows the toast.
- `bin/clip-ui` reads the same config and pidfile, so panel and hotkeys never
  disagree.

## Known limitations

- No medal.tv account integration: no auto-upload, no cloud library. Clips are
  local files -- upload them yourself if you want them on Medal.
- Monitor capture is per-monitor; on a multi-monitor setup set `CLIP_MONITOR`
  (or restart the buffer while the game is on the monitor you want).
- `-w focused` (follow the focused window) is X11-only upstream; on Wayland the
  buffer is tied to the monitor chosen at start.
- Codec is H.264 + Opus in MP4. Opus-in-MP4 plays in VLC/browsers but some
  editors prefer AAC -- add `-ac aac` to the `args` array in `clip-start` if you
  need that.

## Credits

Clipping engine: [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/about/)
by dec05eba. This repo is only the glue: hotkeys, shared config, notifications
and the panel.
