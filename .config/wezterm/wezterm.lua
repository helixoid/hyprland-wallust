local config = {}

config.enable_wayland = true
config.front_end = "WebGpu"
config.font = require("wezterm").font_with_fallback({
  "Intel One Mono",
  "Noto Sans CJK",
  "Symbols Nerd Font",
  "Noto Color Emoji"
})
config.font_size = 12

config.color_scheme_dirs = { "~/.config/wezterm/colors" }
config.color_scheme = "wallust"
config.enable_tab_bar = false
config.hide_mouse_cursor_when_typing = true
config.window_background_opacity = 0.25
config.anti_alias_custom_block_glyphs = true
config.default_cursor_style = 'BlinkingBar'
config.warn_about_missing_glyphs = true
config.use_ime = true
config.use_dead_keys = false
config.hide_mouse_cursor_when_typing = true

return config
