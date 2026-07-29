return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    opts = {
      cache = false,
      style = "night",
      on_colors = function(colors)
        -- Backgrounds (adjusted for Claude Desktop)
        colors.bg = "#1C1B1A"          -- Main terminal background
        colors.bg_dark = "#171615"     -- Darker background (e.g. NeoTree if configured to be darker)
        colors.bg_sidebar = "#232120"  -- Claude's lighter sidebar background
        colors.bg_float = "#232120"    -- Popups and floating windows
        colors.bg_popup = "#232120"
        colors.bg_statusline = "#1C1B1A"
        colors.bg_highlight = "#383532" -- More visible grey for selections/cursorline
        
        -- Foregrounds
        colors.fg = "#F0EBE1"          -- Brighter text
        colors.fg_dark = "#CFC7BB"     -- Slightly dimmed text
        colors.fg_float = "#F0EBE1"
        colors.fg_gutter = "#6D6862"   -- Line numbers
        colors.fg_sidebar = "#B5ADA1"
        
        -- Borders & Comments
        colors.border = "#4A4642"
        colors.border_highlight = "#878078"
        colors.comment = "#827C75"     -- Light grey for comments
        
        -- Accents
        colors.blue = "#8DA3E0"
        colors.blue1 = "#9CACE0"
        colors.blue2 = "#7FA8C9"
        colors.cyan = "#89B4C4"
        colors.teal = "#7FB8A8"
        colors.green = "#8FBC8F"
        colors.green1 = "#8FBC8F"
        colors.green2 = "#8FBC8F"
        colors.yellow = "#E0B584"
        colors.orange = "#D97757" -- Anthropic's signature coral accent
        colors.red = "#D47D7D"
        colors.red1 = "#D47D7D"
        colors.magenta = "#B39DDB"
        colors.magenta2 = "#D9A3B8"
        colors.purple = "#B39DDB"
      end,
      on_highlights = function(hl, c)
        -- Example of overriding a specific highlight group if needed,
        -- though on_colors is usually sufficient.
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
