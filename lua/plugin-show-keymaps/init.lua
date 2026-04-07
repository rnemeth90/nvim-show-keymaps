local utils = require("plugin-show-keymaps.utils")
local keymaps = require("plugin-show-keymaps.keymaps")

local M = {}

local defaults = {}

local config = {}

-- Call this from your Neovim config: require("plugin-test").setup({ ... })
function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})
end

-- Show all keybindings in a floating window.
-- Optionally pass a mode string: "n", "i", "v", etc.
function M.show_keymaps(mode)
  keymaps.show(mode)
end

return M
