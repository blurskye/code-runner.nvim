local M = {}
local function table_to_string(data, indent)
    if not data then
        return ""
    end

    local str = ""
    for k, v in pairs(data) do
        if type(v) == "table" then
            str = str .. string.rep(" ", indent) .. "- " .. table_to_string(v, indent + 2) .. "\n"
        else
            str = str .. string.rep(" ", indent) .. tostring(v) .. "\n"
        end
    end

    return str
end

-- function M.unbind_commands(json_data)
--     for _, data in pairs(json_data) do
--         if vim.api.nvim_get_keymap('n')[data.key] then
--             vim.api.nvim_del_keymap('n', data.key)
--         end
--     end
-- end

function M.unbind_commands(json_data)
    if (json_data) then
        for _, v in pairs(json_data) do
            if v.command and v.keybind then
                -- Unbind the keymap in normal mode
                vim.api.nvim_set_keymap('n', v.keybind, '', { noremap = true, silent = true })
            end
        end
    end
end

-- function M.bind_commands(json_data)
--     if (json_data) then
--         for _, v in pairs(json_data) do
--             if v.command and v.keybind then
--                 local file_buffer = vim.api.nvim_buf_get_name(0)
--                 local file_path = '"' .. file_buffer .. '"'

--                 local file_dir = vim.fn.fnamemodify(file_path, ":h")
--                 local file_name = vim.fn.fnamemodify(file_path, ":t")
--                 local file_name_without_ext = vim.fn.fnamemodify(file_path, ":r:t")
--                 local file_extension = vim.fn.fnamemodify(file_path, ":e")

--                 local cmd = v.command
--                 cmd = cmd:gsub("$dir", file_dir)
--                 cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
--                 cmd = cmd:gsub("$fileName", file_name)
--                 cmd = cmd:gsub("$fileExtension", file_extension)
--                 cmd = cmd:gsub("$filePath", file_path)



--                 vim.api.nvim_set_keymap('n', v.keybind,
--                     ":TermExec cmd='" .. cmd .. "'<CR>",
--                     { noremap = true, silent = true })
--             end
--         end
--     end
-- end
-- function M.bind_commands(json_data)
--     if (json_data) then
--         for _, v in pairs(json_data) do
--             if v.command and v.keybind then
--                 local file_buffer = vim.api.nvim_buf_get_name(0)
--                 local file_path = file_buffer

--                 local file_dir = vim.fn.fnamemodify(file_path, ":h")
--                 local file_name = vim.fn.fnamemodify(file_path, ":t")
--                 local file_name_without_ext = vim.fn.fnamemodify(file_path, ":r:t")
--                 local file_extension = vim.fn.fnamemodify(file_path, ":e")

--                 local cmd = v.command
--                 cmd = cmd:gsub("$dir", file_dir)
--                 cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
--                 cmd = cmd:gsub("$fileName", file_name)
--                 cmd = cmd:gsub("$fileExtension", file_extension)
--                 cmd = cmd:gsub("$filePath", file_path)

--                 vim.api.nvim_set_keymap('n', v.keybind,
--                     ":TermExec cmd='" .. cmd .. "'<CR>",
--                     { noremap = true, silent = true })
--             end
--         end
--     end
-- end


-- function M.bind_commands(json_data)
--     if (json_data) then
--         for _, v in pairs(json_data) do
--             if v.command and v.keybind then
--                 local file_buffer = vim.api.nvim_buf_get_name(0)

--                 local file_path = '"' .. file_buffer .. '"'
--                 local file_dir = '"' .. vim.fn.fnamemodify(file_buffer, ":h") .. '"'
--                 local file_name = '"' .. vim.fn.fnamemodify(file_buffer, ":t") .. '"'
--                 local file_name_without_ext = '"' .. vim.fn.fnamemodify(file_buffer, ":t:r") .. '"'
--                 local file_extension = '"' .. vim.fn.fnamemodify(file_buffer, ":e") .. '"'

--                 local cmd = v.command
--                 cmd = cmd:gsub("$dir", file_dir)
--                 cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
--                 cmd = cmd:gsub("$fileName", file_name)
--                 cmd = cmd:gsub("$fileExtension", file_extension)
--                 cmd = cmd:gsub("$filePath", file_path)

--                 vim.api.nvim_set_keymap('n', v.keybind,
--                     ":TermExec cmd='" .. cmd .. "'<CR>",
--                     { noremap = true, silent = true })
--             end
--         end
--     end
-- end
function M.adjust_command_path()
    local data = M.coderun_json -- Accessing cached loaded data

    if data then
        return data.dir or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h") -- Use data.dir or current dir
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
                cmd = cmd:gsub("$dir", file_dir)
                cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
                cmd = cmd:gsub("$fileName", file_name)
                cmd = cmd:gsub("$fileExtension", file_extension)
                cmd = cmd:gsub("$filePath", file_path)



                -- Check if the keybind already exists
                -- local exists = keybind_exists(v.keybind)

                if true then
                    -- Keybind doesn't exist, safe to bind it
                    vim.api.nvim_set_keymap('n', v.keybind,
                        ":TermExec cmd='" .. cmd .. "'<CR>",
                        { noremap = true, silent = true })
                else
                    -- Keybind already exists, handle appropriately
                    print("Keybind " .. v.keybind .. " already exists! Skipping binding.")
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

            -- Return the whole JSON data as a Lua table
            return data
        end

        local parent_dir = vim.fn.fnamemodify(file_dir, ":h")
        if parent_dir == file_dir then -- We've reached the root directory
            break
        end
        file_dir = parent_dir
    end

    return nil
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
    -- if (M.json_data) then
    --     M.bind_commands(M.json_data)
    -- else
    --     local file_extension = vim.fn.expand("%:e")
    --     M.bind_commands(M.generate_commands_table(file_extension))
    -- end
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
    print("buff type if (" .. buftype .. ")")
    if buftype == 'nofile' then
        print("tried to unbind")
        if M.coderun_json then
            M.unbind_commands(M.coderun_json)
        else
            local file_extension = vim.fn.expand("%:e")
            M.bind_commands(M.generate_commands_table(file_extension))
        end
    end
end

return M
