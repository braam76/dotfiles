vim.pack.add {
    "https://github.com/saghen/blink.cmp",
    "https://github.com/saghen/blink.lib",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/stevearc/conform.nvim",
    "https://github.com/folke/lazydev.nvim",
}

local js_formatters = { "oxfmt", "prettierd", "prettier", stop_after_first = true }

require("conform").setup {
    formatters_by_ft = {
        lua = { "stylua" },
        nix = { "nixfmt" },
        python = { "isort", "black" },
        rust = { "rustfmt", lsp_format = "fallback" },
        zig = { "zigfmt" },
        javascript = js_formatters,
        javascriptreact = js_formatters,
        typescript = js_formatters,
        typescriptreact = js_formatters,
        vue = { "prettierd", "prettier", stop_after_first = true },
    },
    format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
}

vim.keymap.set("n", "<leader>lf", function()
    require("conform").format { async = true, lsp_format = "fallback" }
end, { desc = "Format buffer" })

require("lazydev").setup {}

require("blink.cmp").setup {
    keymap = { preset = "super-tab" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
    },
    sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
            lazydev = {
                name = "LazyDev",
                module = "lazydev.integrations.blink",
                score_offset = 100,
            },
        },
    },
    fuzzy = { implementation = "lua" },
    signature = { enabled = true },
}

-- Keep nested devenv projects separate from their parent flake/repository.
local function nix_root(bufnr)
    return vim.fs.root(bufnr, { { "devenv.yaml", "devenv.nix", "flake.nix" }, ".git" })
end

local function is_devenv(root)
    return root and vim.uv.fs_stat(root .. "/devenv.nix") ~= nil
end

vim.lsp.config("nixd", {
    root_dir = function(bufnr, on_dir)
        local root = nix_root(bufnr)
        if root and not is_devenv(root) then
            on_dir(root)
        end
    end,
    -- This flake imports /etc/nixos/hardware-configuration.nix.
    -- Scope impure evaluation to the NixOS language server, not all Nix commands.
    cmd_env = { NIX_CONFIG = (vim.env.NIX_CONFIG or "") .. "\npure-eval = false" },
    settings = {},
    before_init = function(_, config)
        local init = vim.fn.resolve(vim.fn.stdpath "config" .. "/init.lua")
        local flake_root = vim.fs.root(init, "flake.nix")
        if not flake_root or vim.uv.fs_realpath(config.root_dir) ~= vim.uv.fs_realpath(flake_root) then
            return
        end

        -- JSON strings are also valid Nix strings for ordinary filesystem paths.
        local flake = "(builtins.getFlake " .. vim.json.encode(flake_root) .. ")"
        local nixos = flake .. ".nixosConfigurations.nixos"
        config.settings.nixd = {
            nixpkgs = { expr = "import " .. flake .. ".inputs.nixpkgs { }" },
            options = {
                nixos = { expr = nixos .. ".options" },
            },
        }
    end,
})

-- devenv 2.4+ generates project-specific nixpkgs and option expressions itself.
-- Do not send generic nixd settings: they would override devenv's configuration.
vim.lsp.config("devenv", {
    cmd = function(dispatchers, config)
        return vim.lsp.rpc.start({ "devenv", "lsp" }, dispatchers, { cwd = config.root_dir })
    end,
    filetypes = { "nix" },
    workspace_required = true,
    root_dir = function(bufnr, on_dir)
        local root = nix_root(bufnr)
        if is_devenv(root) then
            on_dir(root)
        end
    end,
})

-- Use servers supplied by the shell/project, never install them from Neovim.
if vim.fn.executable "vtsls" == 1 then
    local vue_cmd = vim.fn.exepath "vue-language-server"
    if vue_cmd ~= "" then
        local vue_package = vim.env.VUE_LANGUAGE_SERVER_PATH
        if not vue_package or vue_package == "" then
            -- npm normally symlinks the executable into PATH from the package's bin/ directory.
            local executable = vim.fn.resolve(vue_cmd)
            local package_root = vim.fs.dirname(vim.fs.dirname(executable))
            if vim.endswith(package_root, "/@vue/language-server") then
                vue_package = package_root
            else
                -- Project-local package managers can use a shim in node_modules/.bin instead.
                vue_package = vim.fs.joinpath(vim.fs.dirname(vim.fs.dirname(vue_cmd)), "@vue/language-server")
            end
        end
        if vim.uv.fs_stat(vim.fs.joinpath(vue_package, "package.json")) then
            vim.lsp.config("vtsls", {
                filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
                settings = {
                    vtsls = {
                        tsserver = {
                            globalPlugins = {
                                {
                                    name = "@vue/typescript-plugin",
                                    location = vue_package,
                                    languages = { "vue" },
                                    configNamespace = "typescript",
                                },
                            },
                        },
                    },
                },
            })
            -- nvim-lspconfig already forwards Vue's TypeScript requests to vtsls.
            vim.lsp.enable "vue_ls"
        end
    end
    vim.lsp.enable "vtsls"
end

vim.lsp.enable {
    "gopls",
    "lua_ls",
    "nixd",
    "devenv",
    "basedpyright",
    "rust_analyzer",
    "clangd",
    "cmake",
    "zls",
    "bashls",
    "phpactor",
}
