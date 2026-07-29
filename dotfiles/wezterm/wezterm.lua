local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- 1. Color Scheme
config.color_scheme = 'Monokai Dimmed'

-- 2. Increase default font size (default is usually 12.0)
config.font_size = 14.0

-- 3. Theme the app and background colors
config.colors = {
  background = '#1e1e1e', -- A nice soft dark grey instead of pitch black
  tab_bar = {
    background = '#2d2d2d', -- Lighter grey contrasting background for the tab bar area
    active_tab = {
      bg_color = '#1e1e1e', -- Matches the terminal background so it seamlessly connects
      fg_color = '#c0c0c0',
    },
    inactive_tab = {
      bg_color = '#2d2d2d',
      fg_color = '#8b8b8b',
    },
    inactive_tab_hover = {
      bg_color = '#3d3d3d', -- Slightly lighter on hover
      fg_color = '#c0c0c0',
    },
  }
}

-- 4. Modern macOS window style
config.window_decorations = "RESIZE"

-- 5. Make the tab handles larger and match the theme
config.window_frame = {
  font_size = 14.0, -- Increases the size of the tabs
  active_titlebar_bg = '#2d2d2d',
  inactive_titlebar_bg = '#2d2d2d',
}

-- Padding for a cleaner look
config.window_padding = {
  left = 8,
  right = 8,
  top = 12,
  bottom = 8,
}

-- 6. Initial window size (30% wider, 30% shorter: 100 cols x 35 rows)
config.initial_cols = 100
config.initial_rows = 35

return config

