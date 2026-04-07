# nvim-show-keymaps

A Neovim plugin that displays all active keybindings in a centered floating window. Filter by mode or view everything at once.

## Features

- Shows all keymaps across Normal, Insert, Visual, Command, Terminal, and more
- Filter keymaps by a specific mode
- Centered floating window with rounded borders
- Close with `q` or `<Esc>`
- Displays key, mapping target, and description (if set)

## Requirements

- Neovim 0.8+

## Installation

### lazy.nvim

```lua
{
  dir = "~/path/to/nvim-show-keymaps",
  config = function()
    require("plugin-show-keymaps").setup()
  end,
}
```

### Manual (symlink)

```bash
git clone https://github.com/rnemeth90/nvim-show-keymaps
cd nvim-show-keymaps
./install.sh
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

## Structure

```
lua/plugin-show-keymaps/
  init.lua      ← setup() and show_keymaps() entry points
  keymaps.lua   ← keymap collection and floating window logic
  utils.lua     ← utility helpers
plugin/
  plugin-show-keymaps.vim  ← registers :Keymaps and :KeymapsMode commands
install.sh      ← symlink installer for local development
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
