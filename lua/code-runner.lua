local M = {}

function M.unbind_commands(json_data)
    local modes = { 'n', 'i', 'v', 't' }

    if (json_data) then
        for _, v in pairs(json_data) do
            if v.command and v.keybind then
                for _, mode in ipairs(modes) do
                    -- Unbind the keymap in all modes
                    vim.api.nvim_set_keymap(mode, v.keybind, '', { noremap = true, silent = true })
                end
            end
        end
    end
end

function M.adjust_command_path()
    if M.coderun_json_dir then
        return M.coderun_json_dir
    end

    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h") -- Default to current dir
end

local function keybind_exists(keybind)
    local keymaps = vim.api.nvim_get_keymap('n') -- 'n' for normal mode
    for _, map in pairs(keymaps) do
        if map.lhs == keybind then
            return true
        end
    end
    return false
end

function M.send_interrupt()
    if M.interupting then
        return
    end
    M.interupting = true
    local current_win = vim.api.nvim_get_current_win()
    local current_mode = vim.api.nvim_get_mode().mode
    -- Check if the current buffer is a terminal
    local buf_type = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), 'buftype')
    local terminal_win = nil
    if buf_type == 'terminal' then
        terminal_win = vim.api.nvim_get_current_win()
    else
        -- Get a list of all open windows
        local windows = vim.api.nvim_list_wins()
        for _, win in ipairs(windows) do
            -- Check if the window's buffer is a terminal
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.api.nvim_buf_get_option(buf, 'buftype') == 'terminal' then
                terminal_win = win
                break
            end
        end
        if not terminal_win then
            -- Open a new terminal if no terminal buffer was found
            vim.api.nvim_exec(':ToggleTerm', false)


            local windows = vim.api.nvim_list_wins()
            for _, win in ipairs(windows) do
                -- Check if the window's buffer is a terminal
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.api.nvim_buf_get_option(buf, 'buftype') == 'terminal' then
                    terminal_win = win
                    break
                end
            end
        end
    end
    if terminal_win then
        vim.api.nvim_set_current_win(terminal_win)
        vim.defer_fn(function()
            -- Send Ctrl+C to the terminal buffer
            vim.api.nvim_exec('startinsert', false)
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, true, true), 'n', true)
            vim.defer_fn(function()
                -- Switch back to the original window
                vim.api.nvim_set_current_win(current_win)
                print("current mode: " .. current_mode)
                if current_mode:sub(1, 1) == 'i' then
                    vim.defer_fn(function()
                        vim.api.nvim_exec('startinsert', false)
                        M.interupting = false
                    end, 50)
                else
                    M.interupting = false
                end
            end, 50)
        end, 100)
    end
end

function M.bind_commands(json_data)
    if (json_data) then
        for _, v in pairs(json_data) do
            if v.command and v.keybind then
                local file_buffer = vim.api.nvim_buf_get_name(0)

                -- local file_path = '"' .. file_buffer .. '"'
                local file_path = '"' .. M.adjust_command_path() .. '"'
                local file_dir = '"' .. vim.fn.fnamemodify(file_buffer, ":h") .. '"'
                local file_name = '"' .. vim.fn.fnamemodify(file_buffer, ":t") .. '"'
                local file_name_without_ext = '"' .. vim.fn.fnamemodify(file_buffer, ":t:r") .. '"'
                local file_extension = '"' .. vim.fn.fnamemodify(file_buffer, ":e") .. '"'

                local cmd = v.command
                cmd = cmd:gsub("$dir", file_path)
                cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
                cmd = cmd:gsub("$fileName", file_name)
                cmd = cmd:gsub("$fileExtension", file_extension)
                cmd = cmd:gsub("$filePath", file_path)

                local modes = { 'n', 'i', 'v', 't' }
                for _, mode in ipairs(modes) do
                    if string.sub(v.command, 1, 1) == ":" then
                        vim.api.nvim_set_keymap(mode, v.keybind,
                            "<Cmd>" .. string.sub(v.command, 2) .. "<CR>",
                            { noremap = true, silent = true })
                    elseif string.match(v.command, "`{.-}`") then
                        vim.api.nvim_set_keymap(mode, v.keybind,
                            "<Cmd>lua require('code-runner').complete_variables_in_commands(" ..
                            vim.fn.json_encode(v) .. ")<CR>",
                            { noremap = true, silent = true })
                    else
                        vim.api.nvim_set_keymap(mode, v.keybind,
                            "<Cmd>TermExec cmd='" .. cmd .. "'<CR>",
                            { noremap = true, silent = true })
                    end
                end
            end
        end
    end
end

function M.load_json()
    local bufnr = vim.api.nvim_win_get_buf(0)
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local file_dir = vim.fn.fnamemodify(file_path, ":h")
    local root_dir = "/"

    while file_dir ~= root_dir do
        local json_path = file_dir .. "/coderun.json"
        local file = io.open(json_path, "r")

        if file then
            local content = file:read("*all")
            file:close()

            local data = vim.fn.json_decode(content)
            M.coderun_json_dir = file_dir
            return data
        end

        local parent_dir = vim.fn.fnamemodify(file_dir, ":h")
        if parent_dir == file_dir then -- We've reached the root directory
            M.coderun_json_dir = nil
            break
        end
        file_dir = parent_dir
    end

    return nil
end

function M.complete_variables_in_commands(v)
    local command = v.command
    local variables = {}

    for var in string.gmatch(command, "{(.-)}") do
        -- Open a floating window and prompt the user for input
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { var .. " = " })
        vim.api.nvim_buf_set_option(buf, 'modifiable', true)
        local win_opts = {
            relative = "editor",
            width = 20,
            height = 1,
            col = math.floor((vim.o.columns - 20) / 2),
            row = math.floor((vim.o.lines - 1) / 2),
            style = "minimal",
            border = "rounded",
        }
        local win = vim.api.nvim_open_win(buf, true, win_opts)

        -- Wait for the user to input the value and press Enter
        vim.api.nvim_command('startinsert')
        vim.api.nvim_buf_attach(buf, false, {
            on_lines = function()
                local value = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
                if string.sub(value, -1) == "\n" then
                    -- The user has pressed Enter, close the floating window
                    vim.api.nvim_win_close(win, true)

                    -- Remove the trailing newline and " = " from the value
                    value = string.sub(value, 1, -4)

                    -- Replace the variable in the command with the value
                    command = string.gsub(command, "{" .. var .. "}", value)
                end
            end,
        })
        vim.api.nvim_command(command)
    end
end

M.commands = {
    java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
    python = "python3 -u $dir/$fileName",
    typescript = "deno run $dir/$fileName",
    rust = "cd $dir && rustc $fileName && $dir/$fileNameWithoutExt",
    c = "cd $dir && gcc $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt",
    cpp = "cd $dir && g++ $fileName -o $dir/$fileNameWithoutExt && $dir/$fileNameWithoutExt",
    javascript = "node $dir/$fileName",
    php = "php $dir/$fileName",
    ruby = "ruby $dir/$fileName",
    go = "go run $dir/$fileName",
    perl = "perl $dir/$fileName",
    bash = "bash $dir/$fileName",
    lisp = "sbcl --script $dir/$fileName",
    fortran = "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt",
    haskell = "runhaskell $dir/$fileName",
    dart = "dart run $dir/$fileName",
    pascal = "cd $dir && fpc $fileName && $dir/$fileNameWithoutExt",
    nim = "nim compile --run $dir/$fileName"
}

M.extensions = {
    python = { "py" },
    java = { "java" },
    typescript = { "ts" },
    rust = { "rs" },
    c = { "c" },
    cpp = { "cpp", "cxx", "hpp", "hxx" },
    javascript = { "js" },
    php = { "php" },
    ruby = { "rb" },
    go = { "go" },
    perl = { "pl" },
    bash = { "sh" },
    lisp = { "lisp" },
    fortran = { "f", "f90" },
    haskell = { "hs" },
    dart = { "dart" },
    pascal = { "pas" },
    nim = { "nim" }
}
function M.generate_commands_table(file_extension)
    local commands_table = {}
    for language, extensions in pairs(M.extensions) do
        for _, extension in ipairs(extensions) do
            if extension == file_extension then
                commands_table["run " .. language .. " project"] = {
                    command = M.commands[language],
                    keybind = M.opts.keymap
                }
            end
        end
    end
    return commands_table
end

function M.setup(opts)
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

    if M.opts.run_tmux ~= false then
        vim.cmd("TermExec cmd='tmux new-session -A -s nvim'")
        vim.cmd("ToggleTerm")
    end
    M.coderun_json = M.load_json()
    if (M.coderun_json) then
        M.bind_commands(M.coderun_json)
    else
        M.coderun_json = M.generate_commands_table(vim.fn.expand("%:e"))
        M.bind_commands(M.coderun_json)
    end
    vim.api.nvim_exec([[
            augroup CodeRunner
                autocmd!
                autocmd BufEnter * lua require('code-runner').handle_buffer_enter()
                autocmd BufLeave * lua require('code-runner').handle_buffer_exit()
                augroup END
                ]], false)
    M.opts.interrupt_keymap = M.opts.interrupt_keymap or '<F2>'
    local modes = { 'n', 'i', 'v', 't' }
    for _, mode in ipairs(modes) do
        vim.api.nvim_set_keymap(mode, M.opts.interrupt_keymap, "<Cmd>lua require('code-runner').send_interrupt()<CR>",
            { noremap = true, silent = true })
    end
end

function M.handle_buffer_enter()
    local buftype = vim.api.nvim_buf_get_option(0, 'buftype')
    if buftype ~= 'terminal' and buftype ~= 'nofile' and buftype == '' then
        M.coderun_json = M.load_json()
        M.json_data = M.load_json()
        -- print(M.table_to_string(M.json_data))

        if (M.coderun_json) then
            M.bind_commands(M.coderun_json)
        else
            M.coderun_json = M.generate_commands_table(vim.fn.expand("%:e"))
            M.bind_commands(M.coderun_json)
        end
    end
end

function M.handle_buffer_exit()
    local buftype = vim.api.nvim_buf_get_option(0, 'buftype')
    -- print("buff type if (" .. buftype .. ")")
    if buftype == 'nofile' or buftype == "" then
        -- print("tried to unbind")
        if M.coderun_json then
            M.unbind_commands(M.coderun_json)
        else
            local file_extension = vim.fn.expand("%:e")
            M.bind_commands(M.generate_commands_table(file_extension))
        end
    end
end

return M
