vim.pack.add { "https://github.com/iamcco/markdown-preview.nvim" }

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.keymap.set("n", "<leader>pr", "<cmd>MarkdownPreview<CR>", {
            desc = "Markdown Preview",
        })
    end,
})
