require("conform").setup {
    formatters_by_ft = {
        lua = { "stylua" },
        nix = { "nixfmt" },
        python = { "isort", "black" },
        rust = { "rustfmt", lsp_format = "fallback" },
        zig = { "zigfmt" },
        javascript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
    },
    format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
}

vim.keymap.set("n", "<leader>lf", function()
    require("conform").format { async = true, lsp_format = "fallback" }
end, { desc = "Format buffer" })
