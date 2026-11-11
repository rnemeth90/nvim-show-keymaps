local keymaps = require("plugin-show-keymaps.keymaps")

local M = {}

local defaults = {
  -- Hide <Plug> mappings (internal plugin hooks, not meant to be pressed)
  hide_plug = true,
  -- Only list mappings that have a description
  desc_only = false,
  -- Truncate the mapping target to this many characters (0 = no limit)
  rhs_max_width = 40,
  -- Extra names for <leader> groups, e.g. { g = "git" }.
  -- Group names from which-key specs are picked up automatically.
  groups = {},
}

local config = vim.deepcopy(defaults)

-- Call this from your Neovim config: require("plugin-show-keymaps").setup({ ... })
function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})
end

-- Show all keybindings in a floating window.
-- Optionally pass a mode string: "n", "i", "v", etc.
function M.show_keymaps(mode)
  if mode == "" then mode = nil end
  keymaps.show(mode, config)
end

return M
