-- ~/.config/nvim/lua/init.lua

local Terminal = require('toggleterm.terminal').Terminal
local workspace_win = nil
local workspace_buf = nil
local workspace_visible = false
local julia = nil -- Julia terminal instance
local current_workspace_path = nil -- Track the current workspace.json path

-- Helper function to get current file directory
local function get_current_file_directory()
    local current_file = vim.fn.expand('%:p')
    if current_file == '' then
        return vim.fn.getcwd()
    else
        return vim.fn.fnamemodify(current_file, ':h')
    end
end

-- Initialize current_workspace_path on startup
current_workspace_path = get_current_file_directory()

-- Configure Julia REPL with horizontal orientation
local function create_julia_terminal()
    julia = Terminal:new({
        cmd = "julia --banner=yes --history-file=no",
        direction = "horizontal",
        size = 11,
        hidden = true,
        on_open = function(term)
            vim.api.nvim_win_set_height(term.window, 11)
            vim.api.nvim_win_set_option(term.window, 'number', false)
            vim.api.nvim_win_set_option(term.window, 'relativenumber', false)

            -- Set workspace directory to the current file's directory immediately
            local initial_dir = current_workspace_path:gsub([[\]], [[\\]])
            
            -- Initialize workspace function with dynamic path
            term:send([[
                Base.include_string(Main, raw"""
                function export_workspace(directory="")
                    file_path = directory == "" ? "workspace.json" : joinpath(directory, "workspace.json")
                    open(file_path, "w") do f
                        excluded_names = Set(["eval", "export_workspace", "minimal_print", "include"])
                        for n in names(Main; all=true)
                            if !startswith(string(n), "#") && 
                               !(string(n) in excluded_names) &&
                               isdefined(Main, n)
                                try
                                    val = getfield(Main, n)
                                    if !isa(val, Module)
                                        val_str = isa(val, Number) ? string(val) : repr("text/plain", val)
                                        val_str = replace(val_str, r"\s+" => " ")
                                        println(f, "$n: ", val_str, " ($(typeof(val)))")
                                    end
                                catch
                                    continue
                                end
                            end
                        end
                    end
                end
                """)
                println("\x1b[2J\x1b[H")
            ]])

            -- Navigation mappings
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-h>", "<C-\\><C-n><C-w>h", {silent = true})
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-j>", "<C-\\><C-n><C-w>j", {silent = true})
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-k>", "<C-\\><C-n><C-w>k", {silent = true})
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-l>", "<C-\\><C-n><C-w>l", {silent = true})
        end,
    })
    return julia
end

-- Initialize Julia terminal instance
julia = create_julia_terminal()

-- Workspace management
function toggle_workspace()
    -- Always update current_workspace_path before toggling
    current_workspace_path = get_current_file_directory()
    
    if not workspace_visible then
        vim.cmd("vsplit | enew")
        workspace_win = vim.api.nvim_get_current_win()
        workspace_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_win_set_buf(workspace_win, workspace_buf)
        vim.api.nvim_win_set_width(workspace_win, 85)
        vim.api.nvim_buf_set_name(workspace_buf, "WORKSPACE_VIEW")
        workspace_visible = true
        update_workspace()
        setup_file_watcher()
    else
        vim.api.nvim_win_close(workspace_win, true)
        if workspace_buf and vim.api.nvim_buf_is_valid(workspace_buf) then
            vim.api.nvim_buf_delete(workspace_buf, { force = true })
        end
        workspace_visible = false
        workspace_buf = nil
        workspace_win = nil
    end
end

function setup_file_watcher()
    if not current_workspace_path then
        current_workspace_path = get_current_file_directory()
    end
    
    local watcher = vim.loop.new_fs_event()
    local json_path = current_workspace_path .. "/workspace.json"
    watcher:start(json_path, {}, function(err)
        if not err then
            vim.schedule(function()
                update_workspace()
            end)
        end
    end)
end

function update_workspace()
    if not workspace_buf or not vim.api.nvim_buf_is_valid(workspace_buf) then return end
    
    -- Make sure we have the latest path
    if not current_workspace_path then
        current_workspace_path = get_current_file_directory()
    end
    
    local json_path = current_workspace_path .. "/workspace.json"
    local ok, data = pcall(function()
        return vim.fn.readfile(json_path)
    end)
    
    if ok then
        local formatted = {}
        -- Header
        table.insert(formatted, string.format("%-20s | %-25s | %s", "Name", "Type", "Value"))
        table.insert(formatted, string.rep("-", 70))
        
        -- Parse and format entries
        for _, line in ipairs(data) do
            -- Directly capture all three components
            local name, value, type_str = line:match("^%s*(.-):%s*(.-)%s*%((.-)%)%s*$")
            if name and value and type_str then
                -- Clean up value
                value = value:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                -- Truncate long values
                if #value > 30 then
                    value = value:sub(1, 27) .. "..."
                end
                table.insert(formatted, string.format("%-20s | %-25s | %s", 
                    name, type_str, value))
            end
        end
        
        vim.api.nvim_buf_set_lines(workspace_buf, 0, -1, false, formatted)
    else
        vim.api.nvim_buf_set_lines(workspace_buf, 0, -1, false, {"No workspace data available"})
    end
end

-- Julia code execution function
local function send_to_julia(code)
    if not julia:is_open() then
        julia:open()
    end
    -- Update current workspace path based on current file
    current_workspace_path = get_current_file_directory()
    julia:send([[println("\027[2J")]])  -- Clear terminal
    julia:send(code)
    -- Modified line to export workspace to the file's directory
    local export_cmd = string.format([[export_workspace("%s"); print("\x1b[1A\x1b[K")]], 
                                     current_workspace_path:gsub([[\]], [[\\]]))
    julia:send(export_cmd)
    vim.defer_fn(update_workspace, 100)
end

-- Julia environment setup - expanded to set workspace path
function setup_julia_environment()
    -- Update the workspace path when setting up environment
    current_workspace_path = get_current_file_directory()
    
    if not julia:is_open() then
        julia:open()
        vim.cmd('wincmd k')
    end

    -- Key mappings
    vim.keymap.set("n", "<F5>", function()
        send_to_julia(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
    end, { buffer = true })

    vim.keymap.set("n", "<F6>", function()
        send_to_julia(vim.api.nvim_get_current_line())
    end, { buffer = true })

    vim.keymap.set("n", "<F7>", function()
        send_to_julia(get_cell_content())
    end, { buffer = true })

    vim.keymap.set("v", "<F8>", function()
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local lines = vim.api.nvim_buf_get_lines(0, start_pos[2]-1, end_pos[2], false)
        send_to_julia(table.concat(lines, "\n"))
    end, { buffer = true })
end

-- Add an autocmd to update workspace path on file change
vim.api.nvim_create_autocmd({"BufEnter", "BufNew"}, {
    pattern = {"*.jl"},
    callback = function()
        current_workspace_path = get_current_file_directory()
    end
})

local function get_cell_content()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    
    if lines[current_line] and lines[current_line]:match("^#%%") then
        current_line = current_line + 1
    end
    
    local start_line = current_line
    local end_line = current_line
    
    while start_line > 1 and not lines[start_line-1]:match("^#%%") do
        start_line = start_line - 1
    end
    
    while end_line < #lines and not lines[end_line+1]:match("^#%%") do
        end_line = end_line + 1
    end
    
    return table.concat(vim.api.nvim_buf_get_lines(0, start_line-1, end_line, false), "\n")
end

-- Plugin configurations
require('nvim-tree').setup()
require('lualine').setup()


-- Configure LSP and autocompletion
local cmp = require('cmp')
local lspkind = require('lspkind')
local luasnip = require('luasnip')

require('luasnip.loaders.from_vscode').lazy_load()
require('nvim-autopairs').setup()
require('mason').setup()
require('mason-lspconfig').setup({
    ensure_installed = { 'julials' }, -- Julia LSP
})

-- Configure LSP
local lspconfig = require('lspconfig')
lspconfig.julials.setup({})

-- Enhanced completion setup
cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'buffer' },
        { name = 'path' },
    }),
    formatting = {
        format = lspkind.cmp_format({
            mode = 'symbol_text',
            maxwidth = 50,
            menu = {
                buffer = "[Buf]",
                nvim_lsp = "[LSP]",
                luasnip = "[Snip]",
                path = "[Path]",
            }
        })
    },
})

-- Autopairs integration
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
