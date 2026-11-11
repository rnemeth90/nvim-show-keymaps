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
  l = "Lang-Arg",
}

local INDENT = "  "
local BULLET = "● "
local ARROW  = "  →  "

-- Builds one line from (text, hl_group) segments and records the byte range
-- of each highlighted segment, so callers never compute offsets by hand.
local function line_builder()
  local parts, hls, len = {}, {}, 0
  local b = {}
  function b.add(text, hl)
    if text == "" then return b end
    if hl then hls[#hls+1] = { hl, len, len + #text } end
    parts[#parts+1] = text
    len = len + #text
    return b
  end
  function b.finish() return table.concat(parts), hls end
  return b
end

-- Replace the leader key with "<leader>" and remaining spaces with "<Space>"
local function display_lhs(lhs)
  local leader = vim.g.mapleader or "\\"
  if lhs:sub(1, #leader) == leader then
    lhs = "<leader>" .. lhs:sub(#leader + 1)
  end
  return (lhs:gsub(" ", "<Space>"))
end

local function truncate(text, max)
  if max and max > 0 and vim.fn.strchars(text) > max then
    return vim.fn.strcharpart(text, 0, max - 1) .. "…"
  end
  return text
end

-- Group names for <leader>X prefixes: which-key specs first, then user config
local function group_names(config)
  local names = {}
  local ok, wk_config = pcall(require, "which-key.config")
  if ok and type(wk_config.mappings) == "table" then
    for _, m in ipairs(wk_config.mappings) do
      if m.group and type(m.desc) == "string" and type(m.lhs) == "string" then
        names[m.lhs:gsub("^<[Ll]eader>", "<leader>")] = m.desc
      end
    end
  end
  for key, name in pairs(config.groups or {}) do
    names["<leader>" .. key] = name
  end
  return names
end

local function include(map, config)
  if config.hide_plug and map.lhs:find("<Plug>", 1, true) then return false end
  if config.desc_only and (map.desc == nil or map.desc == "") then return false end
  if map.desc == "which_key_ignore" then return false end
  return true
end

-- The <leader>X prefix a map belongs to, or nil for non-leader maps
local function leader_prefix(display)
  return display:match("^(<leader><[^>]+>)") or display:match("^(<leader>[^<]?)")
end

-- 0 = not a leader map, 1 = single key after <leader>, 2 = part of a group
local function leader_class(display)
  local prefix = leader_prefix(display)
  if not prefix then return 0 end
  return prefix == display and 1 or 2
end

-- Global + buffer-local maps for a mode, sorted, each map listed only once
-- across sections (e.g. a "v" map also shows up when querying "x").
local function maps_for_mode(mode, bufnr, seen, config)
  local all = vim.api.nvim_get_keymap(mode)
  vim.list_extend(all, vim.api.nvim_buf_get_keymap(bufnr, mode))

  local maps = {}
  for _, map in ipairs(all) do
    local key = table.concat({ map.mode or mode, map.lhs, tostring(map.buffer or 0) }, "\0")
    if not seen[key] and include(map, config) then
      seen[key] = true
      map.display = display_lhs(map.lhs)
      map.class = leader_class(map.display)
      maps[#maps+1] = map
    end
  end

  -- Non-leader maps, then single-key leader maps, then leader groups;
  -- alphabetical within each
  table.sort(maps, function(a, b)
    if a.class ~= b.class then return a.class < b.class end
    local al, bl = a.display:lower(), b.display:lower()
    if al ~= bl then return al < bl end
    return a.display < b.display
  end)
  return maps
end

-- Returns lines and hls ({ line_0based, hl_group, col_start, col_end } entries)
local function collect_keymaps(mode_filter, bufnr, config)
  if mode_filter and not VALID_MODES[mode_filter] then
    vim.notify("nvim-show-keymaps: invalid mode '" .. mode_filter .. "'", vim.log.levels.ERROR)
    return { INDENT .. "Invalid mode: '" .. mode_filter .. "'" }, {}
  end

  local lines, hls = {}, {}
  local function push(builder)
    local text, line_hls = builder.finish()
    lines[#lines+1] = text
    for _, h in ipairs(line_hls) do
      hls[#hls+1] = { #lines - 1, h[1], h[2], h[3] }
    end
  end

  local groups = group_names(config)
  local seen = {}
  local modes = mode_filter and { mode_filter } or MODE_ORDER

  for _, mode in ipairs(modes) do
    local maps = maps_for_mode(mode, bufnr, seen, config)
    if #maps > 0 then
      push(line_builder()
        .add(INDENT).add(BULLET, "Special").add(MODES[mode] or mode, "Title")
        .add("  (" .. mode .. ")", "Comment"))
      push(line_builder().add(INDENT .. string.rep("─", 60), "Comment"))

      local lhs_width = 0
      for _, map in ipairs(maps) do
        lhs_width = math.max(lhs_width, vim.fn.strdisplaywidth(map.display))
      end
      lhs_width = math.min(lhs_width, 25)

      local current_group
      for _, map in ipairs(maps) do
        -- Subheading for the single-key leader maps, then one per <leader>X group
        local heading = map.class == 1 and "<leader>"
          or map.class == 2 and leader_prefix(map.display)
        if heading and heading ~= current_group then
          current_group = heading
          local name = map.class == 1 and "top level" or groups[heading]
          push(line_builder())
          push(line_builder()
            .add(INDENT).add(heading, "Keyword")
            .add(name and ("  " .. name) or "", "Title"))
        end

        local rhs = (map.rhs ~= nil and map.rhs ~= "") and map.rhs
          or (map.callback and "<Lua function>" or "<Nop>")
        rhs = truncate(rhs, config.rhs_max_width)
        local pad = string.rep(" ", math.max(0, lhs_width - vim.fn.strdisplaywidth(map.display)))

        local b = line_builder()
          .add(INDENT).add(map.display, "Keyword").add(pad)
          .add(ARROW, "Comment").add(rhs, "String")
        if map.desc and map.desc ~= "" then
          b.add("  # " .. map.desc, "Comment")
        end
        if map.buffer and map.buffer ~= 0 then
          b.add("  [buffer]", "Special")
        end
        push(b)
      end

      push(line_builder())
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
    vim.api.nvim_buf_set_extmark(buf, ns, h[1], h[3], { end_col = h[4], hl_group = h[2] })
  end

  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
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

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, close, { buffer = buf, silent = true })
  end

  -- Close when focus moves to another window
  vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = close })

  return buf, win
end

function M.show(mode_filter, config)
  config = config or {}
  local title = mode_filter
    and string.format("Keybindings — %s mode", MODES[mode_filter] or mode_filter)
    or "Keybindings — All Modes"
  -- Read the current buffer before the float takes focus, so its
  -- buffer-local maps are the ones listed
  local lines, hls = collect_keymaps(mode_filter, vim.api.nvim_get_current_buf(), config)
  open_float(lines, hls, title)
end

-- Exposed for tests
M._collect = collect_keymaps
M._display_lhs = display_lhs

return M
