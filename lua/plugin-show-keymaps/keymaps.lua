local M = {}

local MODES = {
  n = "Normal",
  i = "Insert",
  v = "Visual",
  x = "Visual Block",
  s = "Select",
  o = "Operator",
  c = "Command",
  t = "Terminal",
}

-- Collect keymaps for all modes (or a specific mode)
local function collect_keymaps(mode_filter)
  local lines = {}
  local modes = mode_filter and { mode_filter } or vim.tbl_keys(MODES)

  for _, mode in ipairs(modes) do
    local maps = vim.api.nvim_get_keymap(mode)
    if #maps > 0 then
      table.insert(lines, string.format("── %s (%s) ──", MODES[mode] or mode, mode))
      for _, map in ipairs(maps) do
        local lhs = map.lhs:gsub(" ", "<Space>")
        local rhs = map.rhs or (map.callback and "<Lua function>" or "")
        local desc = map.desc and ("  # " .. map.desc) or ""
        table.insert(lines, string.format("  %-20s → %s%s", lhs, rhs, desc))
      end
      table.insert(lines, "")
    end
  end

  if #lines == 0 then
    lines = { "No keymaps found." }
  end

  return lines
end

-- Open a centered floating window
local function open_float(lines, title)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.min(math.floor(vim.o.lines * 0.8), #lines + 2)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", "keymaps", { buf = buf })

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  vim.api.nvim_set_option_value("wrap", false, { win = win })
  vim.api.nvim_set_option_value("cursorline", true, { win = win })

  -- Close with q or <Esc>
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
  end

  return buf, win
end

function M.show(mode_filter)
  local title = mode_filter
    and string.format("Keybindings — %s mode", MODES[mode_filter] or mode_filter)
    or "Keybindings — All Modes"
  local lines = collect_keymaps(mode_filter)
  open_float(lines, title)
end

return M
