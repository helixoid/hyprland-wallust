local config = {}

config.enable_wayland = true
config.front_end = "WebGpu"
config.font = require("wezterm").font_with_fallback({
  "Intel One Mono",
  "Symbols Nerd Font",
  "Noto Color Emoji"
})
config.font_size = 12

config.color_scheme_dirs = { "~/.config/wezterm/colors" }
config.color_scheme = "wallust"
config.enable_tab_bar = false
config.window_background_opacity = 0.25

config.use_ime = true
config.use_dead_keys = false

return config
