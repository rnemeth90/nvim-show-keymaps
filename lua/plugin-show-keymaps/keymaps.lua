local M = {}

local ns = vim.api.nvim_create_namespace("show-keymaps")

local VALID_MODES = { n=true, i=true, v=true, x=true, s=true, o=true, c=true, t=true, l=true }
local MODE_ORDER  = { "n", "i", "v", "x", "s", "o", "c", "t" }
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

local INDENT = "  "
-- "●" is U+25CF = 3 UTF-8 bytes; adding a trailing space makes BULLET 4 bytes total
local BULLET = "● "

-- Returns lines (strings) and hls ({ line_0based, hl_group, col_start, col_end } entries).
local function collect_keymaps(mode_filter)
  if mode_filter and not VALID_MODES[mode_filter] then
    vim.notify("nvim-show-keymaps: invalid mode '" .. mode_filter .. "'", vim.log.levels.ERROR)
    return { INDENT .. "Invalid mode: '" .. mode_filter .. "'" }, {}
  end

  local lines = {}
  local hls   = {}

  local modes = mode_filter and { mode_filter } or MODE_ORDER

  for _, mode in ipairs(modes) do
    -- Merge global and buffer-local keymaps
    local maps = vim.api.nvim_get_keymap(mode)
    vim.list_extend(maps, vim.api.nvim_buf_get_keymap(0, mode))

    if #maps > 0 then
      -- Section header: "  ● Normal  (n)"
      local mode_name = MODES[mode] or mode
      local header    = INDENT .. BULLET .. mode_name .. "  (" .. mode .. ")"
      lines[#lines+1] = header
      local ln = #lines - 1  -- 0-based

      -- "●" spans bytes [#INDENT, #INDENT+3)
      hls[#hls+1] = { ln, "Special", #INDENT, #INDENT + 3 }
      -- mode name spans bytes [#INDENT + #BULLET, ...)
      local name_s = #INDENT + #BULLET
      local name_e = name_s + #mode_name
      hls[#hls+1] = { ln, "Title", name_s, name_e }
      -- "(n)" from name_e onward
      hls[#hls+1] = { ln, "Comment", name_e, -1 }

      -- Divider
      lines[#lines+1] = INDENT .. string.rep("─", 60)
      hls[#hls+1] = { #lines - 1, "Comment", 0, -1 }

      -- Compute max lhs width for column alignment within this section
      local lhs_width = 0
      for _, map in ipairs(maps) do
        lhs_width = math.max(lhs_width, #map.lhs:gsub(" ", "<Space>"))
      end
      lhs_width = math.min(lhs_width, 25)

      for _, map in ipairs(maps) do
        local lhs  = map.lhs:gsub(" ", "<Space>")
        -- map.rhs is "" (not nil) for Lua-callback keymaps, so check both
        local rhs  = (map.rhs ~= nil and map.rhs ~= "") and map.rhs
                     or (map.callback and "<Lua function>" or "")
        local desc = map.desc or ""

        -- Line layout: INDENT lhs_padded "  →  " rhs ["  # " desc]
        local lhs_padded = string.format("%-" .. lhs_width .. "s", lhs)
        local line_text  = INDENT .. lhs_padded .. "  →  " .. rhs
        if desc ~= "" then
          line_text = line_text .. "  # " .. desc
        end
        lines[#lines+1] = line_text
        ln = #lines - 1

        -- lhs: highlight only the actual key, not the padding
        local lhs_s = #INDENT
        local lhs_e = lhs_s + #lhs
        hls[#hls+1] = { ln, "Keyword", lhs_s, lhs_e }

        -- arrow "→" (3 bytes): sits after INDENT + lhs_width + "  "
        local arrow_s = #INDENT + lhs_width + 2
        local arrow_e = arrow_s + 3
        hls[#hls+1] = { ln, "Comment", arrow_s, arrow_e }

        -- rhs: starts after the arrow + trailing "  "
        local rhs_s = arrow_e + 2
        local rhs_e = rhs_s + #rhs
        hls[#hls+1] = { ln, "String", rhs_s, rhs_e }

        -- desc: highlight "  # <desc>" from rhs_e to EOL
        if desc ~= "" then
          hls[#hls+1] = { ln, "Comment", rhs_e, -1 }
        end
      end

      lines[#lines+1] = ""
    end
  end

  if #lines == 0 then
    lines = { INDENT .. "No keymaps found." }
  end

  return lines, hls
end

local function open_float(lines, hls, title)
  local width  = math.max(1, math.floor(vim.o.columns * 0.8))
  local height = math.max(1, math.min(math.floor(vim.o.lines * 0.8), #lines + 2))
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  for _, h in ipairs(hls) do
    -- nvim_buf_add_highlight(buf, ns_id, hl_group, line, col_start, col_end)
    vim.api.nvim_buf_add_highlight(buf, ns, h[2], h[1], h[3], h[4])
  end

  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", "keymaps", { buf = buf })

  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    width     = width,
    height    = height,
    row       = row,
    col       = col,
    style     = "minimal",
    border    = "rounded",
    title     = " " .. title .. " ",
    title_pos = "center",
  })

  vim.api.nvim_set_option_value("wrap", false, { win = win })
  vim.api.nvim_set_option_value("cursorline", true, { win = win })

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
  local lines, hls = collect_keymaps(mode_filter)
  open_float(lines, hls, title)
end

return M
