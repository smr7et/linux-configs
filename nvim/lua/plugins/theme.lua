-- return {
--   -- 1. install the kanagawa plugin
--   {
--     "rebelot/kanagawa.nvim",
--     lazy = false, -- force it to load immediately on startup
--     priority = 1000, -- load it before other plugins so ui doesn't glitch
--     opts = {
--       -- you can add advanced kanagawa config here later, like:
--       -- transparent = true,
--     },
--   },
--
--   -- 2. force lazyvim to use it as the default theme
--   {
--     "lazyvim/lazyvim",
--     opts = {
--       colorscheme = "kanagawa-dragon",
--       -- wave: The default warm theme.
--       -- dragon: A darker, high-contrast theme for late-night sessions.
--       -- lotus: A lighter theme for bright environments.
--     },
--   },
-- }
--
-- return {
--   -- 1. Install the Nightfox plugin
--   {
--     "EdenEast/nightfox.nvim",
--     lazy = false, -- Force it to load immediately
--     priority = 1000, -- Load it before other plugins
--   },
--
--   -- 2. Force LazyVim to use it as the default theme
--   {
--     "LazyVim/LazyVim",
--     opts = {
--       colorscheme = "terafox",
--       -- nightfox: The default dark theme.
--       -- carbonfox: Very dark, high contrast (excellent for OLED screens or late-night terminal sessions).
--       -- nordfox: Inspired by the icy, muted blues of the popular Nord theme.
--       -- terafox: A softer, earthy dark theme.
--       -- duskfox: A slightly warmer, faded dark theme.
--       -- dayfox / dawnfox: Light themes if you prefer a brighter terminal.
--     },
--   },
-- }
--
--
return {
  -- 1. Install the Cyberdream plugin
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      -- Recommended Cyberdream-specific options
      transparent = true, -- Set to true to use your terminal's background
      italic_comments = true, -- Makes comments italic
      hide_fillchars = true, -- Replaces window separator lines with empty space
      borderless_telescope = true, -- Makes telescope look cleaner
    },
  },

  -- 2. Force LazyVim to use it as the default theme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "cyberdream",
    },
  },
}
