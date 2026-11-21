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
}
