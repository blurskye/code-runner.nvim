-- local M = {}

-- function M.setup(opts)
--   M.opts = opts or {}
--   M.opts.commands_path = M.opts.commands_path or vim.fn.stdpath('config') .. '/lua/code-runner/commands.json'
--   M.opts.keymap = M.opts.keymap or '<F5>'

--   -- Set the keymap
--   vim.api.nvim_set_keymap('n', M.opts.keymap, ':lua require("code-runner").run_code()<CR>',
--     { noremap = true, silent = true })
-- end

-- function M.run_code()
--   print("stating")
--   local file_path = vim.fn.expand("%:p")
--   local file_extension = vim.fn.fnamemodify(file_path, ":e")

--   local cmd

--   if file_extension == 'py' then
--     cmd = 'python -u %s'
--   end

--   if cmd then
--     cmd = string.format(cmd, file_path)
--     print("Running command: " .. cmd)
--     vim.cmd("execute 'TermExec cmd=\"" .. cmd .. "\"'", false)
--   else
--     print("Error: Could not construct command for file extension " .. file_extension)
--   end
-- end

-- return M
local M = {}

-- Default commands
M.commands = {
    py = 'python -u %s',
    -- Add more default commands here
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

    -- Set the keymap
    vim.api.nvim_set_keymap('n', M.opts.keymap, ':lua require("code-runner").run_code()<CR>',
        { noremap = true, silent = true })
end

function M.run_code()
    -- if not _G.tmux_started then
    --   print("Starting tmux")
    --   vim.cmd(
    --     [[execute 'TermExec cmd="[ -z "$TMUX" ] && (tmux has-session -t nvim 2>/dev/null || tmux new-session -d -s nvim) && tmux attach -t nvim"']])
    --   _G.tmux_started = true
    -- end
    if not _G.tmux_started then
        print("Starting tmux")
        vim.cmd(
            [[execute 'TermExec cmd="bash -c \\"[ -z \\\\\\"$TMUX\\\\\\" ] && (tmux has-session -t nvim 2>/dev/null || tmux new-session -d -s nvim) && tmux attach -t nvim\\""']])
        _G.tmux_started = true
    end
    print("Starting")
    local file_path = vim.fn.expand("%:p")
    local file_extension = vim.fn.fnamemodify(file_path, ":e")

    local cmd = M.commands[file_extension]

    if cmd then
        cmd = string.format(cmd, file_path)
        print("Running command: " .. cmd)
        vim.cmd("execute 'TermExec cmd=\"" .. cmd .. "\"'")
    else
        print("Error: Could not construct command for file extension " .. file_extension)
    end
end

return M
