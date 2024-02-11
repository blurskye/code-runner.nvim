local M = {}

M.commands = {
    python = "python3 -u $dir/$fileName",
}

M.extensions = {
    python = { "py" },
}

M.bindings = {} -- Table to store bindings for each buffer

function M.setup(opts)
    -- ... original setup logic ...
    M.opts = opts or {}
    M.opts.keymap = M.opts.keymap or '<F5>'

    -- Overwrite the default commands and extensions with the user-provided commands
    if M.opts.commands then
        for k, v in pairs(M.opts.commands) do
            M.commands[k] = v
        end
    end
    if M.opts.extensions then
        for k, v in pairs(M.opts.extensions) do
            M.extensions[k] = v
        end
    end

    -- if M.opts.run_tmux ~= false then
    --     vim.cmd("TermExec cmd='tmux new-session -A -s nvim'")
    --     vim.cmd("ToggleTerm")
    -- end
    if M.opts.run_tmux == true then
        vim.cmd("TermExec cmd='tmux new-session -A -s nvim'")
        vim.cmd("ToggleTerm")
    end

    -- Set the keymap
    vim.api.nvim_set_keymap('n', M.opts.keymap, ':lua require("code-runner").run_code()<CR>',
        { noremap = true, silent = true })
    -- Bind a function to run on buffer/window changes
    vim.api.nvim_command([[
    autocmd BufWinEnter * lua require("code-runner").update_bindings()
  ]])
end

function M.find_coderun_json(dir)
    local path = dir .. "/coderun.json"
    if vim.fn.filereadable(path) then
        return path
    end
    local parent_dir = vim.fn.fnamemodify(dir, ":h")
    if parent_dir ~= dir then -- Avoid infinite loop
        return M.find_coderun_json(parent_dir)
    end
end

function M.load_coderun_config(path)
    local config = vim.fn.json_decode(vim.fn.readfile(path))
    return config
end

function M.update_bindings()
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local coderun_path = M.find_coderun_json(vim.fn.fnamemodify(file_path, ":h"))

    -- Unbind previous bindings for this buffer
    if M.bindings[bufnr] then
        for _, binding in pairs(M.bindings[bufnr]) do
            vim.api.nvim_del_keymap(binding.mode, binding.key)
        end
        M.bindings[bufnr] = nil
    end

    if coderun_path then
        local config = M.load_coderun_config(coderun_path)
        local bindings = {}
        for name, action in pairs(config) do
            local key = action.keybind or name
            vim.api.nvim_set_keymap('n', key, string.format(":lua require('code-runner').run_command('%s')<CR>", name),
                { noremap = true, silent = true })
            table.insert(bindings, { mode = 'n', key = key }) -- Store binding for unbind later
        end
        M.bindings[bufnr] = bindings
    else
        -- Use default commands
        -- ... (implement logic to set default keymap if needed) ...
    end
end

function M.run_command(name)
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local coderun_path = M.find_coderun_json(vim.fn.fnamemodify(file_path, ":h"))
    local config = coderun_path and M.load_coderun_config(coderun_path) or {}
    local command = config[name] and config[name].command

    if command then
        -- ... (process command with placeholders and execute) ...
    else
        print("Error: Command '" .. name .. "' not found in coderun.json or default commands")
    end
end

function M.run_code()
    print("Starting")
    -- Get the current window's buffer number
    local bufnr = vim.api.nvim_win_get_buf(0)
    -- Check if the current window contains a terminal, if so then run the code in the window above
    if vim.api.nvim_buf_get_option(bufnr, "buftype") == "terminal" then
        local wins = vim.api.nvim_tabpage_list_wins(0)
        for i, win in ipairs(wins) do
            if win == vim.api.nvim_get_current_win() and i > 1 then
                bufnr = vim.api.nvim_win_get_buf(wins[i - 1])
                break
            end
        end
    end
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local file_dir = vim.fn.fnamemodify(file_path, ":h")
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local file_name_without_ext = vim.fn.fnamemodify(file_path, ":r:t")
    local file_extension = vim.fn.fnamemodify(file_path, ":e")

    local language
    for lang, exts in pairs(M.extensions) do
        for _, ext in ipairs(exts) do
            if ext == file_extension then
                language = lang
                break
            end
        end
        if language then break end
    end
end

return M
