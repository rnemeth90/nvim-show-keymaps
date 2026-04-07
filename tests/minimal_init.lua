-- Minimal Neovim init for running tests with plenary.nvim
local plenary_path = vim.env.PLENARY_PATH or "/tmp/plenary.nvim"

vim.opt.rtp:prepend(plenary_path)
vim.opt.rtp:prepend(".")

require("plenary")
