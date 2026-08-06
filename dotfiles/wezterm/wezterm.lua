local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- 1. General & UI Settings
config.font_size = 14.0
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32

-- Palette (Monokai Dimmed / Zellij Theme Colors)
local SOLID_BG = "#1e1e1e"
local TAB_BAR_BG = "#181818"
local ACTIVE_BG = "#a6e22e"  -- Zellij Lime Green
local ACTIVE_FG = "#181818"  -- Dark text for active tab
local INACTIVE_BG = "#3b3a32" -- Dark Gray for inactive tabs
local INACTIVE_FG = "#c5c8c6" -- Light Gray text for inactive tabs
local HOVER_BG = "#4a4940"    -- Hover state background

config.colors = {
  background = SOLID_BG,
  tab_bar = {
    background = TAB_BAR_BG,
  },
}

-- 2. macOS Window Styling & Integrated Titlebar
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_frame = {
  font_size = 13.0,
  active_titlebar_bg = TAB_BAR_BG,
  inactive_titlebar_bg = TAB_BAR_BG,
}

config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

config.initial_cols = 100
config.initial_rows = 35

-- Powerline Glyphs
local SOLID_RIGHT_ARROW = utf8.char(0xe0b0)
local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

-- 3. Custom Tab Bar Title Formatting (Zellij Powerline Slants)
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local is_first = (tab.tab_index == 0)
  local is_last = (tab.tab_index == #tabs - 1)
  local is_active = tab.is_active

  local bg = is_active and ACTIVE_BG or (hover and HOVER_BG or INACTIVE_BG)
  local fg = is_active and ACTIVE_FG or INACTIVE_FG

  -- Determine the background color of the next segment for smooth Powerline arrow transitions
  local next_bg = TAB_BAR_BG
  if not is_last then
    local next_tab = tabs[tab.tab_index + 2] -- 1-indexed next tab reference
    if next_tab then
      next_bg = next_tab.is_active and ACTIVE_BG or INACTIVE_BG
    end
  end

  -- Tab title text formatting
  local title = tab.active_pane.title
  if not title or #title == 0 then
    title = tab.tab_title
  end
  if not title or #title == 0 then
    title = "Tab #" .. (tab.tab_index + 1)
  else
    title = (tab.tab_index + 1) .. ": " .. title
  end

  local res = {}

  -- Left prefix header for the first tab
  if is_first then
    table.insert(res, { Background = { Color = TAB_BAR_BG } })
    table.insert(res, { Foreground = { Color = "#66d9ef" } })
    table.insert(res, { Attribute = { Intensity = "Bold" } })
    table.insert(res, { Text = " WezTerm " })

    table.insert(res, { Background = { Color = bg } })
    table.insert(res, { Foreground = { Color = TAB_BAR_BG } })
    table.insert(res, { Text = SOLID_RIGHT_ARROW })
  end

  -- Tab content block
  table.insert(res, { Background = { Color = bg } })
  table.insert(res, { Foreground = { Color = fg } })
  table.insert(res, { Attribute = { Intensity = is_active and "Bold" or "Normal" } })
  table.insert(res, { Text = " " .. title .. " " })

  -- Right Powerline arrow transition
  table.insert(res, { Background = { Color = next_bg } })
  table.insert(res, { Foreground = { Color = bg } })
  table.insert(res, { Text = SOLID_RIGHT_ARROW })

  return res
end)

-- 4. Right Status Bar (Zellij Host / Status Pill)
wezterm.on("update-status", function(window, pane)
  local hostname = wezterm.hostname():match("^([^.]+)") or wezterm.hostname()
  
  local status = {
    { Background = { Color = TAB_BAR_BG } },
    { Foreground = { Color = ACTIVE_BG } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = ACTIVE_BG } },
    { Foreground = { Color = ACTIVE_FG } },
    { Attribute = { Intensity = "Bold" } },
    { Text = " " .. hostname .. " " },
  }

  window:set_right_status(wezterm.format(status))
end)

return config
