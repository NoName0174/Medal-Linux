-- Medal-Linux: instant-replay clip hotkeys for Hyprland.
-- Copy these into ~/.config/hypr/hyprland/keybinds.lua (or require this file).
--
-- One 60 s buffer in RAM backs every length; clip-save <seconds> asks the
-- running buffer for part of it over its IPC socket, so saving never re-encodes.

-- Save the default length (CLIP_SECONDS, 30 s) from the shared config.
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd("$HOME/.local/bin/clip-save"),
    { locked = true, description = "Clip: save default length" })

hl.bind("CTRL + ALT + 1", hl.dsp.exec_cmd("$HOME/.local/bin/clip-save 15"),
    { locked = true, description = "Clip: save last 15 s" })
hl.bind("CTRL + ALT + 2", hl.dsp.exec_cmd("$HOME/.local/bin/clip-save 30"),
    { locked = true, description = "Clip: save last 30 s" })
hl.bind("CTRL + ALT + 3", hl.dsp.exec_cmd("$HOME/.local/bin/clip-save 60"),
    { locked = true, description = "Clip: save last 60 s" })

-- Control panel (buffer status, lengths, mic, monitor, recent clips).
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("$HOME/.local/bin/clip-ui"),
    { description = "Clips: open control panel" })

-- Good defaults when clipping inside a game: no notifications stealing focus.
-- windowrule2 = "suppress_event maximize, class:^(clip-ui)$"
