vim.pack.add { "https://github.com/stevearc/oil.nvim" }
require("oil").setup {
    default_file_explorer = true,
    columns = {
        "icon",
        "permissions",
        "size",
        "mtime",
    },
}
vim.keymap.set("n", "<leader>-", "<cmd>Oil<CR>", { desc = "Open netrw" })
