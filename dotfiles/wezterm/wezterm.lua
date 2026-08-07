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
config.native_macos_fullscreen_mode = true
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_button_style = "Windows"
config.integrated_title_buttons = {}
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

-- Automatically close the window without prompting when the last pane/tab exits
config.window_close_confirmation = 'NeverPrompt'

-- 3. Keybindings
-- We define a named custom event here so that WezTerm can link it cleanly to BOTH
-- a keyboard shortcut and a Command Palette entry. If we used an inline anonymous function,
-- WezTerm would auto-generate an ugly generic name (e.g., 'user-defined-0') in the palette.
wezterm.on('export-scrollback', function(window, pane)
  -- Extract all text currently in the terminal pane buffer
  local text = pane:get_lines_as_text()
  -- Define a static filename so we don't clutter the home directory with endless files
  local name = "wezterm-scrollback.txt"
  local path = os.getenv("HOME") .. "/" .. name
  
  local f = io.open(path, 'w+')
  if f then
    f:write(text)
    f:flush()
    f:close()
    
    -- Trigger a custom global state update to tell our custom status bar to display a notification.
    -- (We use this instead of window:toast_notification because Nix-installed WezTerm binaries
    -- lack macOS App Bundles, which causes macOS to silently swallow OS-level toasts).
    wezterm.GLOBAL.notification = "Saved " .. name
    wezterm.GLOBAL.notification_expires = os.time() + 4
  end
end)

-- Inject our nicely named command into the WezTerm Command Palette (Ctrl+Shift+P)
wezterm.on('augment-command-palette', function(window, pane)
  return {
    {
      brief = 'Export Terminal Text/Scrollback',
      icon = 'md_export',
      -- We reference the explicit event name here so it links up with the shortcut below
      action = wezterm.action.EmitEvent('export-scrollback'),
    },
  }
end)

config.keys = {
  -- Export scrollback to text file (Ctrl + Shift + E)
  -- We removed the custom WezTerm pane navigation shortcuts previously to restore default Vim bindings
  { key = "e", mods = "CTRL|SHIFT", action = wezterm.action.EmitEvent('export-scrollback') },
}

-- Powerline Glyphs
local SOLID_RIGHT_ARROW = utf8.char(0xe0b0)
local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

-- 4. Custom Tab Bar Title Formatting (Zellij Powerline Slants)
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

  -- Truncate title so it fits within max_width without chopping off the powerline arrows
  local fixed_width = is_first and 13 or 3
  local available_width = math.max(0, max_width - fixed_width)
  title = wezterm.truncate_right(title, available_width)

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

-- 5. Right Status Bar (Zellij Host / Status Pill & Custom Notifications)
wezterm.on("update-status", function(window, pane)
  local hostname = wezterm.hostname():match("^([^.]+)") or wezterm.hostname()
  
  local status_elements = {}
  local is_notifying = wezterm.GLOBAL.notification_expires and os.time() < wezterm.GLOBAL.notification_expires

  -- Inject our custom internal notification if it is active
  if is_notifying then
    table.insert(status_elements, { Background = { Color = TAB_BAR_BG } })
    table.insert(status_elements, { Foreground = { Color = "#fd971f" } }) -- Orange
    table.insert(status_elements, { Text = SOLID_LEFT_ARROW })
    table.insert(status_elements, { Background = { Color = "#fd971f" } })
    table.insert(status_elements, { Foreground = { Color = TAB_BAR_BG } })
    table.insert(status_elements, { Attribute = { Intensity = "Bold" } })
    table.insert(status_elements, { Text = " " .. wezterm.GLOBAL.notification .. " " })
  end

  -- Hostname block (blends seamlessly if notification is active)
  local hostname_arrow_bg = is_notifying and "#fd971f" or TAB_BAR_BG

  table.insert(status_elements, { Background = { Color = hostname_arrow_bg } })
  table.insert(status_elements, { Foreground = { Color = ACTIVE_BG } })
  table.insert(status_elements, { Text = SOLID_LEFT_ARROW })
  table.insert(status_elements, { Background = { Color = ACTIVE_BG } })
  table.insert(status_elements, { Foreground = { Color = ACTIVE_FG } })
  table.insert(status_elements, { Attribute = { Intensity = "Bold" } })
  table.insert(status_elements, { Text = " " .. hostname .. " " })

  window:set_right_status(wezterm.format(status_elements))
end)

return config
