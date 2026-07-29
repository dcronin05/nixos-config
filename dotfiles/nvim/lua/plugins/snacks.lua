return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        -- Show dotfiles/hidden files globally in the explorer.
        hidden = true,
        -- The top-level `hidden` is NOT automatically inherited by individual
        -- sources — each has its own `hidden = false` default. Override them
        -- explicitly so that <leader><leader>, <leader>/, and <leader>ff all
        -- include hidden/dotfiles in results.
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
          smart = { hidden = true },
          recent = { hidden = true },
        },
      },
    },
  },
}
