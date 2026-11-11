# nvim-show-keymaps

A Neovim plugin that displays all active keybindings in a centered floating window. Filter by mode or view everything at once.

## Features

- Shows all keymaps across Normal, Insert, Visual, Command, Terminal, and more
- Includes buffer-local keymaps (LSP, filetype, etc.), tagged `[buffer]`
- Filter keymaps by a specific mode
- Sorted alphabetically, with each map listed once (a Visual map isn't repeated under Visual Block)
- Leader maps shown as `<leader>…` and grouped by prefix, using group names from
  [which-key](https://github.com/folke/which-key.nvim) when it's installed
- Hides `<Plug>` mappings; optionally hides maps without a description
- Long mapping targets are truncated so descriptions stay visible
- Centered floating window with rounded borders
- Close with `q`, `<Esc>`, or by moving to another window

## Requirements

- Neovim 0.9+

## Installation

### lazy.nvim

```bash
return { "rnemeth90/nvim-show-keymaps" }
```

### Manual (symlink)

```bash
git clone https://github.com/rnemeth90/nvim-show-keymaps
cd nvim-show-keymaps
./install.sh
# then include in whatever file you load plugins with
```

## Usage

### Commands

| Command | Description |
|---|---|
| `:Keymaps` | Show all keybindings |
| `:KeymapsMode <mode>` | Show keybindings for a specific mode |

**Mode identifiers:**

| Key | Mode |
|---|---|
| `n` | Normal |
| `i` | Insert |
| `v` | Visual |
| `x` | Visual Block |
| `s` | Select |
| `o` | Operator |
| `c` | Command |
| `t` | Terminal |

**Example:**
```
:KeymapsMode n    " show Normal mode keymaps
:KeymapsMode i    " show Insert mode keymaps
```

### Lua API

```lua
-- Show all keymaps
require("plugin-show-keymaps").show_keymaps()

-- Show keymaps for a specific mode
require("plugin-show-keymaps").show_keymaps("n")
```

## Configuration

`setup()` is optional. These are the defaults:

```lua
require("plugin-show-keymaps").setup({
  -- Hide <Plug> mappings (internal plugin hooks, not meant to be pressed)
  hide_plug = true,
  -- Only list mappings that have a description
  desc_only = false,
  -- Truncate the mapping target to this many characters (0 = no limit)
  rhs_max_width = 40,
  -- Extra names for <leader> groups, e.g. { g = "git" }.
  -- Group names from which-key specs are picked up automatically.
  groups = {},
})
```

## Development

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim). To run them locally:

```bash
# Install plenary once
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim /tmp/plenary.nvim

# Run tests
nvim --headless -u tests/minimal_init.lua \
  -c "lua require('plenary.test_harness').test_directory('tests/', { sequential = true })" \
  +qa
```

## License

MIT
