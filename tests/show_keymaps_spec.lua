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
  end)
end)
