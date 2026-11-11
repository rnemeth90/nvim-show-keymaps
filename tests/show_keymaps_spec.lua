local plugin = require("plugin-show-keymaps")

describe("plugin-show-keymaps", function()
  before_each(function()
    -- Close any floating windows left open by a previous test
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end)

  describe("setup()", function()
    it("accepts empty options without error", function()
      assert.has_no.errors(function()
        plugin.setup({})
      end)
    end)

    it("accepts nil options without error", function()
      assert.has_no.errors(function()
        plugin.setup()
      end)
    end)
  end)

  describe("show_keymaps()", function()
    it("opens a floating window when called without a mode", function()
      local wins_before = #vim.api.nvim_list_wins()
      plugin.show_keymaps()
      assert.are.equal(wins_before + 1, #vim.api.nvim_list_wins())
    end)

    it("opens a floating window when called with a mode filter", function()
      local wins_before = #vim.api.nvim_list_wins()
      plugin.show_keymaps("n")
      assert.are.equal(wins_before + 1, #vim.api.nvim_list_wins())
    end)

    it("the opened window is floating", function()
      plugin.show_keymaps()
      local wins = vim.api.nvim_list_wins()
      local has_float = false
      for _, win in ipairs(wins) do
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative ~= "" then
          has_float = true
          break
        end
      end
      assert.is_true(has_float)
    end)

    it("closing with q removes the floating window", function()
      local wins_before = #vim.api.nvim_list_wins()
      plugin.show_keymaps()
      vim.api.nvim_feedkeys("q", "x", false)
      assert.are.equal(wins_before, #vim.api.nvim_list_wins())
    end)

    it("closes when focus moves to another window", function()
      local wins_before = #vim.api.nvim_list_wins()
      local origin = vim.api.nvim_get_current_win()
      plugin.show_keymaps()
      vim.api.nvim_set_current_win(origin)
      assert.are.equal(wins_before, #vim.api.nvim_list_wins())
    end)

    it("treats an empty mode as all modes", function()
      plugin.show_keymaps("")
      local cfg = vim.api.nvim_win_get_config(vim.api.nvim_get_current_win())
      assert.is_truthy(vim.inspect(cfg.title):find("All Modes", 1, true))
    end)
  end)

  describe("keymap collection", function()
    local keymaps = require("plugin-show-keymaps.keymaps")
    local config = { hide_plug = true, desc_only = false, rhs_max_width = 40, groups = {} }

    local function text(lines)
      return table.concat(lines, "\n")
    end

    before_each(function()
      vim.g.mapleader = " "
    end)

    after_each(function()
      for _, lhs in ipairs({ " zz", " za", "<Plug>(test-plug)", "zq", " zl" }) do
        pcall(vim.keymap.del, "n", lhs)
        pcall(vim.keymap.del, "v", lhs)
        pcall(vim.keymap.del, "n", lhs, { buffer = 0 })
      end
    end)

    it("displays the leader key as <leader>", function()
      assert.are.equal("<leader>gp", keymaps._display_lhs(" gp"))
      assert.are.equal("<C-w><Space>", keymaps._display_lhs("<C-w> "))
    end)

    it("includes buffer-local maps and tags them", function()
      vim.keymap.set("n", " zl", "<Nop>", { buffer = 0, desc = "local map" })
      local lines = keymaps._collect("n", vim.api.nvim_get_current_buf(), config)
      assert.is_truthy(text(lines):find("<leader>zl.-local map  %[buffer%]"))
    end)

    it("sorts maps alphabetically", function()
      vim.keymap.set("n", " zz", "<Nop>", { desc = "last" })
      vim.keymap.set("n", " za", "<Nop>", { desc = "first" })
      local out = text(keymaps._collect("n", 0, config))
      assert.is_true(out:find("<leader>za", 1, true) < out:find("<leader>zz", 1, true))
    end)

    it("adds a heading per leader group with its configured name", function()
      vim.keymap.set("n", " za", "<Nop>", { desc = "first" })
      local cfg = vim.tbl_extend("force", config, { groups = { z = "zebra" } })
      local lines = keymaps._collect("n", 0, cfg)
      assert.is_true(vim.tbl_contains(lines, "  <leader>z  zebra"))
    end)

    it("lists a visual-mode map once, not again under visual block", function()
      vim.keymap.set("v", " zz", "<Nop>", { desc = "visual only" })
      local _, count = text(keymaps._collect(nil, 0, config)):gsub("visual only", "")
      assert.are.equal(1, count)
    end)

    it("hides <Plug> maps by default", function()
      vim.keymap.set("n", "<Plug>(test-plug)", "<Nop>")
      assert.is_falsy(text(keymaps._collect("n", 0, config)):find("test-plug", 1, true))
    end)

    it("hides maps without a description when desc_only is set", function()
      vim.keymap.set("n", "zq", "<Nop>")
      local cfg = vim.tbl_extend("force", config, { desc_only = true })
      assert.is_falsy(text(keymaps._collect("n", 0, cfg)):find("zq", 1, true))
    end)

    it("truncates long mapping targets", function()
      vim.keymap.set("n", " zz", ":" .. string.rep("x", 100) .. "<CR>")
      local out = text(keymaps._collect("n", 0, config))
      assert.is_truthy(out:find("…", 1, true))
      assert.is_falsy(out:find(string.rep("x", 50), 1, true))
    end)
  end)
end)
