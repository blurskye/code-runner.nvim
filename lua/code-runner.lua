local M = {}
local uv = vim.loop
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local Text = require("nui.text")
local Line = require("nui.line")

function M.unbind_commands(json_data)
    local modes = { 'n', 'i', 'v', 't' }

    if json_data and type(json_data) == "table" then
        for _, v in pairs(json_data) do
            if v.command and v.keybind then
                for _, mode in ipairs(modes) do
                    vim.api.nvim_set_keymap(mode, v.keybind, '', { noremap = true, silent = true })
                end
            end
        end
    end
end

function M.adjust_command_path()
    return M.coderun_json_dir or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
end

local function keybind_exists(keybind)
    local keymaps = vim.api.nvim_get_keymap('n')
    for _, map in pairs(keymaps) do
        if map.lhs == keybind then
            return true
        end
    end
    return false
end

function M.send_interrupt()
    if M.interrupting then
        return
    end
    M.interrupting = true
    local current_win = vim.api.nvim_get_current_win()
    local current_mode = vim.api.nvim_get_mode().mode
    
    require('sky-term').toggle_term_wrapper()
    vim.defer_fn(function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, true, true), 'n', true)
        vim.defer_fn(function()
            require('sky-term').toggle_term_wrapper()
            if current_mode:sub(1, 1) == 'i' then
                vim.defer_fn(function()
                    vim.cmd('startinsert')
                    M.interrupting = false
                end, 50)
            else
                M.interrupting = false
            end
        end, 50)
    end, 100)
end

function M.bind_commands(json_data)
    if json_data and type(json_data) == "table" then
        for _, v in pairs(json_data) do
            if v.command and v.keybind then
                local file_buffer = vim.api.nvim_buf_get_name(0)
                local file_path = '"' .. M.adjust_command_path() .. '"'
                local file_dir = '"' .. vim.fn.fnamemodify(file_buffer, ":h") .. '"'
                local file_name = '"' .. vim.fn.fnamemodify(file_buffer, ":t") .. '"'
                local file_name_without_ext = '"' .. vim.fn.fnamemodify(file_buffer, ":t:r") .. '"'
                local file_extension = '"' .. vim.fn.fnamemodify(file_buffer, ":e") .. '"'

                local cmd = v.command
                    :gsub("$dir", file_dir)
                    :gsub("$fileNameWithoutExt", file_name_without_ext)
                    :gsub("$fileName", file_name)
                    :gsub("$fileExtension", file_extension)
                    :gsub("$filePath", file_path)

                local modes = { 'n', 'i', 'v', 't' }
                for _, mode in ipairs(modes) do
                    if string.sub(v.command, 1, 1) == ":" then
                        vim.api.nvim_set_keymap(mode, v.keybind,
                            "<Cmd>" .. string.sub(v.command, 2) .. "<CR>",
                            { noremap = true, silent = true })
                    elseif string.match(v.command, "`%${(.-)}%`") then
                        vim.api.nvim_set_keymap(mode, v.keybind,
                            "<Cmd>lua require('code-runner').complete_variables_in_commands('" .. cmd .. "')<CR>",
                            { noremap = true, silent = true })
                    else
                        vim.api.nvim_set_keymap(mode, v.keybind,
                            "<Cmd>lua require('sky-term').send_to_term('" .. cmd .. "')<CR>",
                            { noremap = true, silent = true })
                    end
                end
            end
        end
    end
end

function M.find_coderun_json_path()
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local file_dir = vim.fn.fnamemodify(file_path, ":h")
    local root_dir = "/"

    while file_dir ~= root_dir do
        local json_path = file_dir .. "/coderun.json"
        if vim.fn.filereadable(json_path) == 1 then
            return json_path
        end
        local parent_dir = vim.fn.fnamemodify(file_dir, ":h")
        if parent_dir == file_dir then
            break
        end
        file_dir = parent_dir
    end
    return nil
end

function M.load_json()
    local json_path = M.find_coderun_json_path()
    
    if json_path then
        local file = io.open(json_path, "r")
        if file then
            local content = file:read("*all")
            file:close()
            local success, json_data = pcall(vim.fn.json_decode, content)
            if success and type(json_data) == "table" then
                local json_dir = vim.fn.fnamemodify(json_path, ":h")
                if not vim.deep_equal(json_data, M.last_loaded_json) then
                    M.show_confirmation_popup(json_data, json_path, json_dir)
                end
            end
        end
    else
        -- No JSON found, use default configuration
        M.coderun_json_dir = nil
        local default_commands = M.generate_commands_table(vim.fn.expand("%:e"))
        M.bind_commands(default_commands)
    end
end

-- function M.show_confirmation_popup(json_data, json_path, file_dir)
--     if M.confirmation_popup then
--         M.confirmation_popup:unmount()
--     end

--     M.confirmation_popup = Popup({
--         enter = true,
--         focusable = true,
--         border = {
--             style = "rounded",
--             text = {
--                 top = " Confirm coderun.json ",
--                 top_align = "center",
--             },
--         },
--         position = {
--             row = "50%",
--             col = "50%",
--         },
--         size = {
--             width = "80%",
--             height = "60%",
--         },
--         relative = "editor",
--     })

--     local formatted_json = vim.fn.json_encode(json_data)
--     formatted_json = vim.fn.substitute(formatted_json, '[{}]', '{\n}', 'g')
--     formatted_json = vim.fn.substitute(formatted_json, '":"', '": "', 'g')
--     formatted_json = vim.fn.substitute(formatted_json, '","', '",\n"', 'g')

--     local content = string.format([[
-- A coderun.json file has been found at:
-- %s

-- Contents:
-- %s

-- Do you want to use this configuration?
-- Press 'y' to accept, 'n' to reject and use default configuration.
--     ]], json_path, formatted_json)

--     M.confirmation_popup:mount()
--     vim.api.nvim_buf_set_lines(M.confirmation_popup.bufnr, 0, -1, false, vim.split(content, "\n"))
--     vim.api.nvim_buf_set_option(M.confirmation_popup.bufnr, "modifiable", false)

--     M.confirmation_popup:map("n", "y", function()
--         M.confirmation_popup:unmount()
--         M.coderun_json_dir = file_dir
--         M.last_loaded_json = json_data
--         M.bind_commands(json_data)
--         M.confirmation_popup = nil
--     end, { noremap = true })

--     M.confirmation_popup:map("n", "n", function()
--         M.confirmation_popup:unmount()
--         M.coderun_json_dir = nil
--         M.last_loaded_json = nil
--         local default_commands = M.generate_commands_table(vim.fn.expand("%:e"))
--         M.bind_commands(default_commands)
--         M.confirmation_popup = nil
--     end, { noremap = true })

--     M.confirmation_popup:on(event.BufLeave, function()
--         M.confirmation_popup:unmount()
--         M.confirmation_popup = nil
--     end)
-- end
function M.show_confirmation_popup(json_data, json_path, file_dir)
    if M.confirmation_popup then
        M.confirmation_popup:unmount()
    end

    M.confirmation_popup = Popup({
        enter = true,
        focusable = true,
        border = {
            style = "rounded",
            text = {
                top = " Confirm coderun.json ",
                top_align = "center",
            },
        },
        position = "50%",
        size = {
            width = "80%",
            height = "60%",
        },
        buf_options = {
            modifiable = true,
            readonly = false,
            filetype = "markdown",
        },
    })

    local function set_content()
        local lines = {}
        table.insert(lines, "A coderun.json file has been found at:")
        table.insert(lines, "`" .. json_path .. "`")
        table.insert(lines, "")
        table.insert(lines, "Contents:")
        table.insert(lines, "")
        table.insert(lines, "```json")
        
        -- Read and format JSON content
        local json_content = vim.fn.readfile(json_path)
        for _, line in ipairs(json_content) do
            table.insert(lines, line)
        end
        
        table.insert(lines, "```")
        table.insert(lines, "")
        table.insert(lines, "Do you want to use this configuration?")
        table.insert(lines, "Press 'y' to accept, 'n' to reject and use default configuration.")

        local bufnr = M.confirmation_popup.bufnr
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end

    M.confirmation_popup:mount()
    set_content()

    M.confirmation_popup:map("n", "y", function()
        M.confirmation_popup:unmount()
        M.coderun_json_dir = file_dir
        M.last_loaded_json = json_data
        M.bind_commands(json_data)
        M.confirmation_popup = nil
    end, { noremap = true })

    M.confirmation_popup:map("n", "n", function()
        M.confirmation_popup:unmount()
        M.coderun_json_dir = nil
        M.last_loaded_json = nil
        local default_commands = M.generate_commands_table(vim.fn.expand("%:e"))
        M.bind_commands(default_commands)
        M.confirmation_popup = nil
    end, { noremap = true })

    M.confirmation_popup:on(event.BufLeave, function()
        M.confirmation_popup:unmount()
        M.confirmation_popup = nil
    end)
end

function M.complete_variables_in_commands(command)
    local cmd = command
    local values = {}

    for var in string.gmatch(cmd, "`%${(.-)}%`") do
        if not values[var] then
            local value = vim.fn.input('Enter value for ' .. var .. ': ')
            values[var] = value
        end
        cmd = cmd:gsub("`%${" .. var .. "}%`", values[var])
    end
    require('sky-term').send_to_term(cmd)
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

    M.last_loaded_json = nil
    M.load_json()

    M.opts.interrupt_keymap = M.opts.interrupt_keymap or '<F2>'
    local modes = { 'n', 'i', 'v', 't' }
    for _, mode in ipairs(modes) do
        vim.api.nvim_set_keymap(mode, M.opts.interrupt_keymap,
            "<Cmd>lua require('code-runner').send_interrupt()<CR>",
            { noremap = true, silent = true })
    end

    -- Start watching coderun.json
    M.start_watching_coderun_json()
end

function M.start_watching_coderun_json()
    M.last_modified_time = 0
    M.watch_timer = vim.loop.new_timer()
    
    M.watch_timer:start(0, 1000, vim.schedule_wrap(function()
        local json_path = M.find_coderun_json_path()
        if json_path then
            local stat = vim.loop.fs_stat(json_path)
            if stat and stat.mtime.sec > M.last_modified_time then
                M.last_modified_time = stat.mtime.sec
                M.load_json()
            end
        elseif M.last_loaded_json then
            -- Reset to default if JSON file is removed
            M.coderun_json_dir = nil
            M.last_loaded_json = nil
            local default_commands = M.generate_commands_table(vim.fn.expand("%:e"))
            M.bind_commands(default_commands)
        end
    end))
end


return M
