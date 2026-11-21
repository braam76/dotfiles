vim.pack.add { "https://github.com/folke/which-key.nvim" }
local wk = require "which-key"
vim.keymap.set("n", "<leader>?", wk.show, { desc = "Buffer Local Keymaps (which-key)" })
