vim.pack.add { "https://github.com/folke/flash.nvim" }

local f = require "flash"
vim.keymap.set({ "n", "x", "o" }, "<leader>s", f.jump, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "<leader>S", f.treesitter, { desc = "Flash Treesitter" })
vim.keymap.set({ "o" }, "r", f.remote, { desc = "Remote Flash" })
vim.keymap.set({ "o", "x" }, "R", f.treesitter_search, { desc = "Treesitter Search" })
vim.keymap.set({ "c" }, "<c-s>", f.toggle, { desc = "Toggle Flash Search" })
