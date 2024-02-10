local M = {}

-- Default commands
M.commands = {
    py = 'python -u %s',
    -- todo more commands
}

function M.setup(opts)
    M.opts = opts or {}
    M.opts.keymap = M.opts.keymap or '<F5>'

    -- Overwrite the default commands with the user-provided commands
    if M.opts.commands then
        for k, v in pairs(M.opts.commands) do
            M.commands[k] = v
        end
    end

    if M.opts.run_tmux ~= false then
        vim.cmd("TermExec cmd='tmux new-session -A -s nvim'")
    end

    -- Set the keymap
    vim.api.nvim_set_keymap('n', M.opts.keymap, ':lua require("code-runner").run_code()<CR>',
        { noremap = true, silent = true })
end

-- function M.run_code()
--     print("Starting")
--     local file_path = vim.fn.expand("%:p")
--     local file_extension = vim.fn.fnamemodify(file_path, ":e")

--     local cmd = M.commands[file_extension]

--     if cmd then
--         cmd = string.format(cmd, file_path)
--         print("Running command: " .. cmd)
--         vim.cmd("execute 'TermExec cmd=\"" .. cmd .. "\"'")
--     else
--         print("Error: Could not construct command for file extension " .. file_extension)
--     end
-- end

function M.run_code()
    print("Starting")
    local file_path = vim.fn.expand("%:p")
    local file_dir = vim.fn.expand("%:p:h")
    local file_name = vim.fn.expand("%:t")
    local file_name_without_ext = vim.fn.expand("%:r:t")
    local file_extension = vim.fn.fnamemodify(file_path, ":e")

    local cmd = M.commands[file_extension]

    if cmd then
        cmd = cmd:gsub("$dir", file_dir)
        cmd = cmd:gsub("$fileName", file_name)
        cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
        print("Running command: " .. cmd)
        vim.cmd("execute 'TermExec cmd=\"" .. cmd .. "\"'")
    else
        print("Error: Could not construct command for file extension " .. file_extension)
    end
end

return M
