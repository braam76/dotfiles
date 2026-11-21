vim.pack.add {
    "https://github.com/nvim-mini/mini.nvim",
    "https://github.com/braam-76/mini-in-one.nvim",
}

---@type MiniInOne
local mini_in_one = require "mini-in-one"
mini_in_one.setup {
    icons = "defaults",
    pairs = "defaults",
    surround = "defaults",
    diff = "defaults",
    notify = "defaults",
    indentscope = "defaults",

    ai = {
        mappings = {
            around_next = "aa",
            inside_next = "ii",
        },
        n_lines = 500,
    },

    statusline = {
        use_icons = vim.g.have_nerd_font,
    },

    pick = {
        window = {
            config = { border = "rounded" },
        },
    },
}

local pick = mini_in_one.pick.builtin
vim.keymap.set("n", "<leader> ", pick.files, { desc = "Mini files" })
vim.keymap.set("n", "<leader>mg", pick.grep_live, { desc = "Mini grep live" })
vim.keymap.set("n", "<leader>mb", pick.buffers, { desc = "Mini buffers" })
vim.keymap.set("n", "<leader>mh", pick.help, { desc = "Mini help" })
