-- local M = {}
-- local uv = vim.loop

-- -- Default configurations
-- M.defaults = {
--     keymap = '<F5>',
--     interrupt_keymap = '<F2>',
--     commands = {
--         python = "python3 -u \"$dir/$fileName\"",
--         -- Include all default language commands here...
--     },
--     extensions = {
--         python = { "py" },
--         -- Include all default language extensions here...
--     },
--     debug = false, -- Debug mode flag
-- }

-- M.config = {}
-- M.watch_handle = nil
-- M.lock = false

-- -- Debug logging function
-- local function log_debug(message)
--     if M.config.debug then
--         vim.notify("[CodeRunner DEBUG] " .. message, vim.log.levels.INFO)
--     end
-- end

-- -- Utility function to merge tables
-- local function merge_tables(default, user)
--     if not user then return default end
--     for k, v in pairs(user) do
--         if type(v) == "table" and type(default[k]) == "table" then
--             default[k] = merge_tables(default[k], v)
--         else
--             default[k] = v
--         end
--     end
--     return default
-- end

-- -- Find the path to coderun.json
-- function M.find_coderun_json_path()
--     local path = vim.fn.expand("%:p:h")
--     log_debug("Starting search for coderun.json from: " .. path)
--     while path and path ~= "/" do
--         local json_path = path .. "/coderun.json"
--         log_debug("Checking: " .. json_path)
--         if vim.fn.filereadable(json_path) == 1 then
--             log_debug("Found coderun.json at: " .. json_path)
--             return json_path
--         end
--         local parent = vim.fn.fnamemodify(path, ":h")
--         if parent == path then -- Reached the root
--             break
--         end
--         path = parent
--     end
--     log_debug("coderun.json not found")
--     return nil
-- end

-- -- Load JSON configuration
-- function M.load_json_config(json_path)
--     local file = io.open(json_path, "r")
--     if not file then
--         vim.notify("Failed to open coderun.json at " .. json_path, vim.log.levels.ERROR)
--         return nil
--     end
--     local content = file:read("*all")
--     file:close()
--     local success, json_data = pcall(vim.fn.json_decode, content)
--     if not success then
--         vim.notify("Failed to parse coderun.json. Please check JSON syntax.", vim.log.levels.ERROR)
--         return nil
--     end
--     log_debug("Successfully loaded coderun.json")
--     return json_data
-- end

-- -- Generate command
-- function M.generate_command(command_template)
--     local bufnr = vim.api.nvim_get_current_buf()
--     local file_path = vim.api.nvim_buf_get_name(bufnr)
--     local file_dir = vim.fn.fnamemodify(file_path, ":h")
--     local file_name = vim.fn.fnamemodify(file_path, ":t")
--     local file_name_without_ext = vim.fn.fnamemodify(file_path, ":t:r")
--     local file_extension = vim.fn.fnamemodify(file_path, ":e")
--     local coderun_dir = M.coderun_dir or file_dir

--     local cmd = command_template
--         :gsub("$dir", file_dir)
--         :gsub("$fileName", file_name)
--         :gsub("$fileNameWithoutExt", file_name_without_ext)
--         :gsub("$fileExtension", file_extension)
--         :gsub("$filePath", file_path)
--         :gsub("$coderunDir", coderun_dir)

--     return cmd
-- end

-- -- Run the command
-- function M.run_command(cmd)
--     if M.lock then
--         vim.notify("CodeRunner is busy. Please wait...", vim.log.levels.WARN)
--         return
--     end

--     M.lock = true
--     vim.cmd("SendToSkyTerm " .. cmd)
--     vim.notify("Running: " .. cmd, vim.log.levels.INFO)

--     vim.defer_fn(function()
--         M.lock = false
--     end, 1000)
-- end

-- -- Run the code
-- function M.run()
--     log_debug("Run function called")
--     local cmd = nil

--     -- First, attempt to get command from coderun.json based on keymap
--     if M.config.coderun_commands and next(M.config.coderun_commands) then
--         cmd = M.config.coderun_commands[M.config.keymap]
--         if cmd then
--             log_debug("Found command in coderun.json for keymap " .. M.config.keymap)
--             cmd = M.generate_command(cmd)
--             M.run_command(cmd)
--             return
--         else
--             log_debug("No command in coderun.json for keymap " .. M.config.keymap)
--         end
--     else
--         log_debug("No coderun_commands found")
--     end

--     -- Fallback to language default
--     log_debug("Falling back to language default command")
--     local bufnr = vim.api.nvim_get_current_buf()
--     local file_path = vim.api.nvim_buf_get_name(bufnr)
--     if file_path == "" then
--         vim.notify("No file is currently open.", vim.log.levels.WARN)
--         return
--     end

--     local file_extension = vim.fn.fnamemodify(file_path, ":e")
--     local language = nil

--     for lang, exts in pairs(M.config.extensions) do
--         for _, ext in ipairs(exts) do
--             if ext == file_extension then
--                 language = lang
--                 break
--             end
--         end
--         if language then break end
--     end

--     if not language then
--         vim.notify("Unsupported file extension: " .. file_extension, vim.log.levels.ERROR)
--         return
--     end

--     local command = M.config.commands[language]
--     if not command then
--         vim.notify("No command configured for language: " .. language, vim.log.levels.ERROR)
--         return
--     end

--     cmd = M.generate_command(command)
--     M.run_command(cmd)
-- end

-- -- Interrupt the running command
-- function M.send_interrupt()
--     vim.cmd("SendToSkyTerm Ctrl+C")
--     vim.notify("Interrupt signal sent.", vim.log.levels.INFO)
-- end

-- -- Set up keybindings
-- function M.set_keymaps()
--     -- Clear previous keymaps if they exist
--     if M.config.keymap and vim.fn.maparg(M.config.keymap, 'n') ~= '' then
--         vim.api.nvim_del_keymap('n', M.config.keymap)
--     end

--     if M.config.interrupt_keymap and vim.fn.maparg(M.config.interrupt_keymap, 'n') ~= '' then
--         vim.api.nvim_del_keymap('n', M.config.interrupt_keymap)
--     end

--     -- Bind the run key
--     vim.api.nvim_set_keymap('n', M.config.keymap, "<Cmd>lua require('code-runner').run()<CR>", { noremap = true, silent = true })

--     -- Bind the interrupt key
--     vim.api.nvim_set_keymap('n', M.config.interrupt_keymap, "<Cmd>lua require('code-runner').send_interrupt()<CR>", { noremap = true, silent = true })

--     -- Set keymaps from coderun.json
--     if M.config.coderun_keybinds then
--         for keybind, cmd in pairs(M.config.coderun_keybinds) do
--             -- Clear the keybind if it exists
--             if vim.fn.maparg(keybind, 'n') ~= '' then
--                 vim.api.nvim_del_keymap('n', keybind)
--             end
--             vim.api.nvim_set_keymap('n', keybind, "<Cmd>lua require('code-runner').run_custom('" .. cmd .. "')<CR>", { noremap = true, silent = true })
--             log_debug("Set keybind: " .. keybind .. " for command: " .. cmd)
--         end
--     end
-- end

-- -- Run custom command from coderun.json
-- function M.run_custom(command)
--     local cmd = M.generate_command(command)
--     M.run_command(cmd)
-- end

-- -- Load configuration
-- function M.load_configuration()
--     M.config = vim.deepcopy(M.defaults)
--     local json_path = M.find_coderun_json_path()
--     if json_path then
--         M.coderun_dir = vim.fn.fnamemodify(json_path, ":h")
--         local json_config = M.load_json_config(json_path)
--         if json_config then
--             -- Process custom commands and keybinds
--             M.config.coderun_commands = {}
--             M.config.coderun_keybinds = {}
--             for _, entry in pairs(json_config) do
--                 if entry.command and entry.keybind then
--                     M.config.coderun_commands[entry.keybind] = entry.command
--                     M.config.coderun_keybinds[entry.keybind] = entry.command
--                     log_debug("Loaded command from coderun.json: keybind=" .. entry.keybind .. ", command=" .. entry.command)
--                 end
--             end
--         else
--             log_debug("Failed to load json_config")
--         end
--     else
--         M.coderun_dir = nil
--         log_debug("coderun.json not found during configuration load")
--     end
-- end

-- -- Watch for changes in coderun.json
-- function M.start_watching()
--     if M.watch_handle then
--         M.watch_handle:stop()
--         M.watch_handle:close()
--         M.watch_handle = nil
--     end

--     local json_path = M.find_coderun_json_path()
--     if not json_path then return end

--     M.watch_handle = uv.new_fs_event()
--     M.watch_handle:start(json_path, {}, vim.schedule_wrap(function()
--         vim.notify("coderun.json changed. Reloading configuration...", vim.log.levels.INFO)
--         M.load_configuration()
--         M.set_keymaps()
--     end))
-- end

-- -- Set up autocmds to reload configuration on buffer enter and leave
-- function M.setup_autocmds()
--     -- Create an augroup to prevent duplicate autocmds
--     vim.cmd([[
--         augroup CodeRunnerAutocmds
--             autocmd!
--             autocmd BufEnter,BufLeave * lua require('code-runner').on_buffer_event()
--         augroup END
--     ]])
-- end

-- -- Function to handle buffer events
-- function M.on_buffer_event()
--     log_debug("Buffer event triggered. Reloading configuration.")
--     M.load_configuration()
--     M.set_keymaps()
-- end

-- -- Setup function
-- function M.setup(user_opts)
--     M.defaults = merge_tables(M.defaults, user_opts)
--     M.config = vim.deepcopy(M.defaults)
--     M.load_configuration()
--     M.set_keymaps()
--     M.start_watching()
--     M.setup_autocmds() -- Set up the autocmds
-- end

-- return M
local M = {}
local uv = vim.loop

-- Default configurations
M.defaults = {
    keymap = '<F5>',
    interrupt_keymap = '<F2>',
    commands = {
        python = "python3 -u \"$dir/$fileName\"",
        -- Include all default language commands here...
    },
    extensions = {
        python = { "py" },
        -- Include all default language extensions here...
    },
    debug = false, -- Debug mode flag
}

M.config = {}
M.watch_handle = nil
M.lock = false
M.previous_keybinds = {}

-- Debug logging function
local function log_debug(message)
    if M.config.debug then
        vim.notify("[CodeRunner DEBUG] " .. message, vim.log.levels.INFO)
    end
end

-- Utility function to merge tables
local function merge_tables(default, user)
    if not user then return default end
    for k, v in pairs(user) do
        if type(v) == "table" and type(default[k]) == "table" then
            default[k] = merge_tables(default[k], v)
        else
            default[k] = v
        end
    end
    return default
end

-- Find the path to coderun.json
function M.find_coderun_json_path()
    local path = vim.fn.expand("%:p:h")
    log_debug("Starting search for coderun.json from: " .. path)
    while path and path ~= "/" do
        local json_path = path .. "/coderun.json"
        log_debug("Checking: " .. json_path)
        if vim.fn.filereadable(json_path) == 1 then
            log_debug("Found coderun.json at: " .. json_path)
            return json_path
        end
        local parent = vim.fn.fnamemodify(path, ":h")
        if parent == path then -- Reached the root
            break
        end
        path = parent
    end
    log_debug("coderun.json not found")
    return nil
end

-- Load JSON configuration
function M.load_json_config(json_path)
    local file = io.open(json_path, "r")
    if not file then
        vim.notify("Failed to open coderun.json at " .. json_path, vim.log.levels.ERROR)
        return nil
    end
    local content = file:read("*all")
    file:close()
    local success, json_data = pcall(vim.fn.json_decode, content)
    if not success then
        vim.notify("Failed to parse coderun.json. Please check JSON syntax.", vim.log.levels.ERROR)
        return nil
    end
    log_debug("Successfully loaded coderun.json")
    return json_data
end

-- Generate command
function M.generate_command(command_template)
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local file_dir = vim.fn.fnamemodify(file_path, ":h")
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local file_name_without_ext = vim.fn.fnamemodify(file_path, ":t:r")
    local file_extension = vim.fn.fnamemodify(file_path, ":e")
    local coderun_dir = M.coderun_dir or file_dir

    local cmd = command_template
        :gsub("$dir", file_dir)
        :gsub("$fileName", file_name)
        :gsub("$fileNameWithoutExt", file_name_without_ext)
        :gsub("$fileExtension", file_extension)
        :gsub("$filePath", file_path)
        :gsub("$coderunDir", coderun_dir)

    return cmd
end

-- Run the command
function M.run_command(cmd)
    if M.lock then
        vim.notify("CodeRunner is busy. Please wait...", vim.log.levels.WARN)
        return
    end

    M.lock = true
    vim.cmd("SendToSkyTerm " .. cmd)
    vim.notify("Running: " .. cmd, vim.log.levels.INFO)

    vim.defer_fn(function()
        M.lock = false
    end, 1000)
end

-- Run the code
function M.run()
    log_debug("Run function called")
    local cmd = nil

    -- First, attempt to get command from coderun.json based on keymap
    if M.config.coderun_commands and next(M.config.coderun_commands) then
        cmd = M.config.coderun_commands[M.config.keymap]
        if cmd then
            log_debug("Found command in coderun.json for keymap " .. M.config.keymap)
            cmd = M.generate_command(cmd)
            M.run_command(cmd)
            return
        else
            log_debug("No command in coderun.json for keymap " .. M.config.keymap)
        end
    else
        log_debug("No coderun_commands found")
    end

    -- Fallback to language default
    log_debug("Falling back to language default command")
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    if file_path == "" then
        vim.notify("No file is currently open.", vim.log.levels.WARN)
        return
    end

    local file_extension = vim.fn.fnamemodify(file_path, ":e")
    local language = nil

    for lang, exts in pairs(M.config.extensions) do
        for _, ext in ipairs(exts) do
            if ext == file_extension then
                language = lang
                break
            end
        end
        if language then break end
    end

    if not language then
        vim.notify("Unsupported file extension: " .. file_extension, vim.log.levels.ERROR)
        return
    end

    local command = M.config.commands[language]
    if not command then
        vim.notify("No command configured for language: " .. language, vim.log.levels.ERROR)
        return
    end

    cmd = M.generate_command(command)
    M.run_command(cmd)
end

-- Interrupt the running command
function M.send_interrupt()
    vim.cmd("SendToSkyTerm Ctrl+C")
    vim.notify("Interrupt signal sent.", vim.log.levels.INFO)
end

-- Set up keybindings
function M.set_keymaps()
    -- Unbind previous keymaps if they exist
    if M.previous_keybinds and next(M.previous_keybinds) then
        for _, keybind in ipairs(M.previous_keybinds) do
            if vim.fn.maparg(keybind, 'n') ~= '' then
                vim.api.nvim_del_keymap('n', keybind)
                log_debug("Unbound previous keybind: " .. keybind)
            end
        end
    end

    M.previous_keybinds = {}

    -- Bind the run key
    vim.api.nvim_set_keymap('n', M.config.keymap, "<Cmd>lua require('code-runner').run()<CR>", { noremap = true, silent = true })
    table.insert(M.previous_keybinds, M.config.keymap)

    -- Bind the interrupt key
    vim.api.nvim_set_keymap('n', M.config.interrupt_keymap, "<Cmd>lua require('code-runner').send_interrupt()<CR>", { noremap = true, silent = true })
    table.insert(M.previous_keybinds, M.config.interrupt_keymap)

    -- Set keymaps from coderun.json
    if M.config.coderun_keybinds then
        for keybind, cmd in pairs(M.config.coderun_keybinds) do
            vim.api.nvim_set_keymap('n', keybind, "<Cmd>lua require('code-runner').run_custom('" .. cmd .. "')<CR>", { noremap = true, silent = true })
            table.insert(M.previous_keybinds, keybind)
            log_debug("Set keybind: " .. keybind .. " for command: " .. cmd)
        end
    end
end

-- Run custom command from coderun.json
function M.run_custom(command)
    local cmd = M.generate_command(command)
    M.run_command(cmd)
end

-- Load configuration
function M.load_configuration()
    M.config = vim.deepcopy(M.defaults)
    local json_path = M.find_coderun_json_path()
    if json_path then
        M.coderun_dir = vim.fn.fnamemodify(json_path, ":h")
        local json_config = M.load_json_config(json_path)
        if json_config then
            -- Process custom commands and keybinds
            M.config.coderun_commands = {}
            M.config.coderun_keybinds = {}
            for _, entry in pairs(json_config) do
                if entry.command and entry.keybind then
                    M.config.coderun_commands[entry.keybind] = entry.command
                    M.config.coderun_keybinds[entry.keybind] = entry.command
                    log_debug("Loaded command from coderun.json: keybind=" .. entry.keybind .. ", command=" .. entry.command)
                end
            end
        else
            log_debug("Failed to load json_config")
        end
    else
        M.coderun_dir = nil
        log_debug("coderun.json not found during configuration load")
    end
end

-- Watch for changes in coderun.json
function M.start_watching()
    if M.watch_handle then
        M.watch_handle:stop()
        M.watch_handle:close()
        M.watch_handle = nil
    end

    local json_path = M.find_coderun_json_path()
    if not json_path then return end

    M.watch_handle = uv.new_fs_event()
    M.watch_handle:start(json_path, {}, vim.schedule_wrap(function()
        vim.notify("coderun.json changed. Reloading configuration...", vim.log.levels.INFO)
        M.load_configuration()
        M.set_keymaps()
    end))
end

-- Set up autocmds to reload configuration on buffer enter and leave
function M.setup_autocmds()
    -- Create an augroup to prevent duplicate autocmds
    vim.cmd([[
        augroup CodeRunnerAutocmds
            autocmd!
            autocmd BufEnter,BufLeave * lua require('code-runner').on_buffer_event()
        augroup END
    ]])
end

-- Function to handle buffer events
function M.on_buffer_event()
    log_debug("Buffer event triggered. Reloading configuration.")
    M.load_configuration()
    M.set_keymaps()
end

-- Setup function
function M.setup(user_opts)
    M.defaults = merge_tables(M.defaults, user_opts)
    M.config = vim.deepcopy(M.defaults)
    M.load_configuration()
    M.set_keymaps()
    M.start_watching()
    M.setup_autocmds() -- Set up the autocmds
end

return M
