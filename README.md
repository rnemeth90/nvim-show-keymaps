# nvim-plugin-test

A minimal Neovim plugin to learn Lua module development.

## Structure

```
lua/plugin-test/
  init.lua     ← main module, exposes setup() and greet()
  utils.lua    ← helper functions
plugin/
  plugin-test.vim  ← registers :PluginTestGreet command
```

## Usage

Add to your Neovim config (e.g. with lazy.nvim):

```lua
{
  dir = "~/repos/github.com/rnemeth90/nvim-plugin-test",
  config = function()
    require("plugin-test").setup({
      greeting = "Hey",
    })
  end,
}
```

Then run `:PluginTestGreet` or call from Lua:

```lua
require("plugin-test").greet("Ryan")
-- prints: Hey, Ryan!
```
