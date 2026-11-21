vim.pack.add { "https://github.com/craftzdog/solarized-osaka.nvim" }

-- Keep the plugin's highlights, but take every palette value from generated JSON.
local theme_path = vim.fn.stdpath "config" .. "/lua/generated_theme.lua"
local theme_stamp
local function reload_theme()
    local stat = vim.uv.fs_stat(theme_path)
    if not stat then
        return
    end
    local stamp = stat.mtime.sec .. ":" .. stat.mtime.nsec
    if stamp == theme_stamp then
        return
    end
    local ok, err = pcall(function()
        package.loaded.generated_theme = nil
        require("generated_theme").apply()
    end)
    theme_stamp = stamp
    if not ok then
        vim.notify("Theme reload failed: " .. tostring(err), vim.log.levels.ERROR)
    end
end
reload_theme()
local theme_timer = assert(vim.uv.new_timer())
theme_timer:start(1000, 1000, vim.schedule_wrap(reload_theme))
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        theme_timer:stop()
        theme_timer:close()
    end,
})
