" Show all keybindings
command! Keymaps lua require("plugin-show-keymaps").show_keymaps()

" Show keybindings for a specific mode, e.g. :KeymapsMode n
command! -nargs=1 KeymapsMode lua require("plugin-show-keymaps").show_keymaps(<q-args>)
