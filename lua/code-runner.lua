---@class CodeRunner
---@field config CodeRunnerConfig
---@field defaults CodeRunnerConfig
---@field watch_handle userdata|nil
---@field lock boolean
---@field interrupting boolean
---@field previous_keybinds string[]
---@field accepted_configs table<string, string>
---@field rejected_configs table<string, boolean>
---@field prompt_active boolean
---@field coderun_dir string|nil
local M = {}

local uv = vim.loop or vim.uv -- Support both old and new API

---@class CodeRunnerConfig
---@field keymap string
---@field interrupt_keymap string
---@field commands table<string, string>
---@field extensions table<string, string[]>
---@field debug boolean
---@field coderun_commands table<string, string>
---@field coderun_keybinds table<string, string>

-- Default configurations
M.defaults = {
    keymap = '<F5>',
    interrupt_keymap = '<F2>',
    commands = {
        python = 'python3 -u "$dir/$fileName"',
        javascript = 'node "$dir/$fileName"',
        typescript = 'ts-node "$dir/$fileName"',
        lua = 'lua "$dir/$fileName"',
        ruby = 'ruby "$dir/$fileName"',
        go = 'go run "$filePath"',
        c = 'gcc "$dir/$fileName" -o "$dir/$fileNameWithoutExt" && "$dir/$fileNameWithoutExt"',
        cpp = 'g++ "$dir/$fileName" -o "$dir/$fileNameWithoutExt" && "$dir/$fileNameWithoutExt"',
        java = 'javac "$dir/$fileName" && java -cp "$dir" "$fileNameWithoutExt"',
        sh = 'bash "$dir/$fileName"',
        rust = 'rustc "$dir/$fileName" -o "$dir/$fileNameWithoutExt" && "$dir/$fileNameWithoutExt"',
        php = 'php "$dir/$fileName"',
        perl = 'perl "$dir/$fileName"',
        zig = 'zig run "$dir/$fileName"',
        kotlin = 'kotlinc "$dir/$fileName" -include-runtime -d "$dir/$fileNameWithoutExt.jar" && java -jar "$dir/$fileNameWithoutExt.jar"',
        swift = 'swift "$dir/$fileName"',
        r = 'Rscript "$dir/$fileName"',
        julia = 'julia "$dir/$fileName"',
        elixir = 'elixir "$dir/$fileName"',
        haskell = 'runhaskell "$dir/$fileName"',
        scala = 'scala "$dir/$fileName"',
        dart = 'dart run "$dir/$fileName"',
    },
    extensions = {
        python = { 'py', 'pyw' },
        javascript = { 'js', 'mjs', 'cjs' },
        typescript = { 'ts', 'mts', 'cts' },
        lua = { 'lua' },
        ruby = { 'rb' },
        go = { 'go' },
        c = { 'c', 'h' },
        cpp = { 'cpp', 'cc', 'cxx', 'c++', 'hpp' },
        java = { 'java' },
        sh = { 'sh', 'bash', 'zsh' },
        rust = { 'rs' },
        php = { 'php' },
        perl = { 'pl', 'pm' },
        zig = { 'zig' },
        kotlin = { 'kt', 'kts' },
        swift = { 'swift' },
        r = { 'r', 'R' },
        julia = { 'jl' },
        elixir = { 'ex', 'exs' },
        haskell = { 'hs' },
        scala = { 'scala', 'sc' },
        dart = { 'dart' },
    },
    debug = false,
}

-- State
M.config = {}
M.watch_handle = nil
M.lock = false
M.interrupting = false
M.previous_keybinds = {}
M.accepted_configs = {}
M.rejected_configs = {}
M.prompt_active = false
M.coderun_dir = nil

---Log debug message if debug mode is enabled
---@param message string
local function log_debug(message)
    if M.config.debug then
        vim.notify('[CodeRunner] ' .. message, vim.log.levels.DEBUG)
    end
end

---Log error message
---@param message string
local function log_error(message)
    vim.notify('[CodeRunner] ' .. message, vim.log.levels.ERROR)
end

---Log warning message
---@param message string
local function log_warn(message)
    vim.notify('[CodeRunner] ' .. message, vim.log.levels.WARN)
end

---Log info message
---@param message string
local function log_info(message)
    vim.notify('[CodeRunner] ' .. message, vim.log.levels.INFO)
end

---Deep merge two tables
---@param default table
---@param user table|nil
---@return table
local function deep_merge(default, user)
    if not user then
        return vim.deepcopy(default)
    end
    local result = vim.deepcopy(default)
    for k, v in pairs(user) do
        if type(v) == 'table' and type(result[k]) == 'table' then
            result[k] = deep_merge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

---Check if a file exists and is readable
---@param path string
---@return boolean
local function file_exists(path)
    local stat = uv.fs_stat(path)
    return stat ~= nil and stat.type == 'file'
end

---Read file contents safely
---@param path string
---@return string|nil, string|nil
local function read_file(path)
    local fd = uv.fs_open(path, 'r', 438)
    if not fd then
        return nil, 'Failed to open file'
    end

    local stat = uv.fs_fstat(fd)
    if not stat then
        uv.fs_close(fd)
        return nil, 'Failed to stat file'
    end

    local content = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)

    if not content then
        return nil, 'Failed to read file'
    end

    return content, nil
end

---Find coderun.json by traversing up the directory tree
---@return string|nil
function M.find_coderun_json_path()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == '' then
        return nil
    end

    local path = vim.fn.fnamemodify(bufname, ':p:h')
    log_debug('Searching for coderun.json from: ' .. path)

    local max_iterations = 100 -- Prevent infinite loops
    local iterations = 0

    while path and path ~= '' and iterations < max_iterations do
        iterations = iterations + 1
        local json_path = path .. '/coderun.json'

        if file_exists(json_path) then
            log_debug('Found coderun.json at: ' .. json_path)
            return json_path
        end

        local parent = vim.fn.fnamemodify(path, ':h')
        if parent == path then
            break
        end
        path = parent
    end

    log_debug('coderun.json not found')
    return nil
end


---Check if nui.nvim is available
---@return boolean
local function has_nui()
    local ok = pcall(require, 'nui.popup')
    return ok
end

---Show prompt to accept or reject coderun.json using vim.ui.select as fallback
---@param json_path string
---@param content string
---@param hash string
---@param callback fun(accepted: boolean)
local function show_accept_prompt(json_path, content, hash, callback)
    if M.prompt_active then
        log_debug('Prompt already active, skipping')
        return
    end
    M.prompt_active = true

    local function on_accept()
        M.accepted_configs[json_path] = hash
        M.prompt_active = false
        log_debug('User accepted coderun.json')
        if callback then
            callback(true)
        end
    end

    local function on_reject()
        M.rejected_configs[json_path] = true
        M.prompt_active = false
        log_debug('User rejected coderun.json')
        if callback then
            callback(false)
        end
    end

    -- Try nui.nvim first for better UX
    if has_nui() then
        local Popup = require('nui.popup')

        local lines = { '```json' }
        for line in content:gmatch('[^\r\n]+') do
            table.insert(lines, line)
        end
        table.insert(lines, '```')

        local popup = Popup({
            enter = true,
            focusable = true,
            border = {
                style = 'rounded',
                text = {
                    top = ' Accept coderun.json? (y)es / (n)o ',
                    top_align = 'center',
                },
            },
            position = '50%',
            size = {
                width = '80%',
                height = '60%',
            },
            buf_options = {
                modifiable = true,
                readonly = false,
            },
            win_options = {
                cursorline = true,
            },
        })

        popup:mount()

        -- Set content after mount
        vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(popup.bufnr, 'modifiable', false)
        vim.api.nvim_buf_set_option(popup.bufnr, 'filetype', 'markdown')

        local function close_popup(accepted)
            popup:unmount()
            if accepted then
                on_accept()
            else
                on_reject()
            end
        end

        -- Key mappings
        local opts = { noremap = true, nowait = true }
        popup:map('n', 'y', function() close_popup(true) end, opts)
        popup:map('n', 'Y', function() close_popup(true) end, opts)
        popup:map('n', 'n', function() close_popup(false) end, opts)
        popup:map('n', 'N', function() close_popup(false) end, opts)
        popup:map('n', '<Esc>', function() close_popup(false) end, opts)
        popup:map('n', 'q', function() close_popup(false) end, opts)

        -- Scroll mappings
        for _, key in ipairs({ 'j', 'k', 'h', 'l', '<Up>', '<Down>', '<Left>', '<Right>', '<C-d>', '<C-u>' }) do
            popup:map('n', key, key, opts)
        end
    else
        -- Fallback to vim.ui.select
        vim.ui.select({ 'Yes', 'No' }, {
            prompt = 'Accept coderun.json from ' .. json_path .. '?',
        }, function(choice)
            if choice == 'Yes' then
                on_accept()
            else
                on_reject()
            end
        end)
    end
end

---Parse and validate JSON config
---@param content string
---@return table|nil, string|nil
local function parse_json_config(content)
    local ok, data = pcall(vim.fn.json_decode, content)
    if not ok then
        return nil, 'Invalid JSON syntax'
    end

    if type(data) ~= 'table' then
        return nil, 'Config must be a JSON object'
    end

    -- Validate structure
    for key, entry in pairs(data) do
        if type(entry) ~= 'table' then
            return nil, string.format('Entry "%s" must be an object', key)
        end
        if not entry.command or type(entry.command) ~= 'string' then
            return nil, string.format('Entry "%s" missing valid "command" field', key)
        end
        if not entry.keybind or type(entry.keybind) ~= 'string' then
            return nil, string.format('Entry "%s" missing valid "keybind" field', key)
        end
    end

    return data, nil
end

---Load JSON configuration with user confirmation
---@param json_path string
---@param callback fun(config: table|nil)
function M.load_json_config(json_path, callback)
    callback = callback or function() end

    if M.rejected_configs[json_path] then
        log_debug('Config previously rejected: ' .. json_path)
        callback(nil)
        return
    end

    local content, err = read_file(json_path)
    if not content then
        log_error('Failed to read coderun.json: ' .. (err or 'unknown error'))
        callback(nil)
        return
    end

    local hash = vim.fn.sha256(content)
    log_debug('Config hash: ' .. hash:sub(1, 16) .. '...')

    -- Check if already accepted with same hash
    if M.accepted_configs[json_path] == hash then
        log_debug('Config previously accepted (unchanged)')
        local data, parse_err = parse_json_config(content)
        if not data then
            log_error('Failed to parse coderun.json: ' .. parse_err)
            callback(nil)
            return
        end
        callback(data)
        return
    end

    -- Prompt user for new or changed config
    show_accept_prompt(json_path, content, hash, function(accepted)
        if not accepted then
            log_info('Using default configuration')
            callback(nil)
            return
        end

        local data, parse_err = parse_json_config(content)
        if not data then
            log_error('Failed to parse coderun.json: ' .. parse_err)
            callback(nil)
            return
        end

        callback(data)
    end)
end


---Generate command by substituting variables
---@param command_template string
---@return string
function M.generate_command(command_template)
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)

    if file_path == '' then
        return command_template
    end

    local file_dir = vim.fn.fnamemodify(file_path, ':p:h')
    local file_name = vim.fn.fnamemodify(file_path, ':t')
    local file_name_without_ext = vim.fn.fnamemodify(file_path, ':t:r')
    local file_extension = vim.fn.fnamemodify(file_path, ':e')

    -- Escape special characters for shell
    local function escape(s)
        return s:gsub('\\', '\\\\')
    end

    local substitutions = {
        ['$filePath'] = escape(file_path),
        ['$fileNameWithoutExt'] = escape(file_name_without_ext),
        ['$fileName'] = escape(file_name),
        ['$fileExtension'] = escape(file_extension),
        ['$dir'] = escape(file_dir),
        ['$coderunDir'] = escape(M.coderun_dir or file_dir),
    }

    local cmd = command_template
    -- Sort by length descending to avoid partial replacements
    local keys = {}
    for k in pairs(substitutions) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b) return #a > #b end)

    for _, key in ipairs(keys) do
        cmd = cmd:gsub('%' .. key:gsub('%$', '%$'), substitutions[key])
    end

    return cmd
end

---Execute command in terminal
---@param cmd string
function M.run_command(cmd)
    if M.lock then
        log_warn('CodeRunner is busy, please wait...')
        return
    end

    M.lock = true

    -- Prepend cd if we have a coderun directory
    if M.coderun_dir then
        local escaped_dir = vim.fn.shellescape(M.coderun_dir)
        cmd = 'cd ' .. escaped_dir .. ' && ' .. cmd
    end

    log_debug('Executing: ' .. cmd)

    -- Try multiple terminal integrations
    local executed = false

    -- Try sky-term first (original integration)
    if not executed and pcall(function()
        vim.cmd('SendToSkyTerm ' .. cmd)
    end) then
        executed = true
        log_debug('Executed via sky-term')
    end

    -- Try toggleterm
    if not executed then
        local ok, toggleterm = pcall(require, 'toggleterm')
        if ok then
            local Terminal = require('toggleterm.terminal').Terminal
            local term = Terminal:new({
                cmd = cmd,
                direction = 'horizontal',
                close_on_exit = false,
            })
            term:toggle()
            executed = true
            log_debug('Executed via toggleterm')
        end
    end

    -- Fallback to built-in terminal
    if not executed then
        vim.cmd('split | terminal ' .. cmd)
        executed = true
        log_debug('Executed via built-in terminal')
    end

    -- Release lock after delay
    vim.defer_fn(function()
        M.lock = false
    end, 500)
end

---Get language from file extension
---@param extension string
---@return string|nil
local function get_language_from_extension(extension)
    for lang, exts in pairs(M.config.extensions) do
        for _, ext in ipairs(exts) do
            if ext:lower() == extension:lower() then
                return lang
            end
        end
    end
    return nil
end

---Run code for current buffer
function M.run()
    log_debug('Run triggered')

    -- Check for coderun.json command first
    if M.config.coderun_commands and M.config.coderun_commands[M.config.keymap] then
        local cmd = M.generate_command(M.config.coderun_commands[M.config.keymap])
        M.run_command(cmd)
        return
    end

    -- Fallback to language detection
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)

    if file_path == '' then
        log_warn('No file is currently open')
        return
    end

    local extension = vim.fn.fnamemodify(file_path, ':e')
    local language = get_language_from_extension(extension)

    if not language then
        log_error('Unsupported file extension: ' .. extension)
        return
    end

    local command_template = M.config.commands[language]
    if not command_template then
        log_error('No command configured for: ' .. language)
        return
    end

    local cmd = M.generate_command(command_template)
    M.run_command(cmd)
end

---Run a custom command
---@param command string
function M.run_custom(command)
    local cmd = M.generate_command(command)
    M.run_command(cmd)
end

---Send interrupt signal to terminal
function M.send_interrupt()
    if M.interrupting then
        return
    end
    M.interrupting = true

    local current_mode = vim.api.nvim_get_mode().mode

    -- Try sky-term first
    local ok = pcall(function()
        require('sky-term').toggle_term_wrapper()
    end)

    if ok then
        vim.defer_fn(function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, true, true), 'n', true)
            vim.defer_fn(function()
                pcall(function()
                    require('sky-term').toggle_term_wrapper()
                end)
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
    else
        -- Fallback: send Ctrl-C to terminal buffer
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].buftype == 'terminal' then
                local chan = vim.b[buf].terminal_job_id
                if chan then
                    vim.fn.chansend(chan, '\x03')
                    log_debug('Sent interrupt to terminal')
                    break
                end
            end
        end
        M.interrupting = false
    end
end


---Safely delete a keymap
---@param mode string
---@param key string
local function safe_del_keymap(mode, key)
    local ok = pcall(vim.api.nvim_del_keymap, mode, key)
    if ok then
        log_debug('Unbound keymap: ' .. key)
    end
end

---Set up keybindings
function M.set_keymaps()
    -- Unbind previous keymaps
    for _, keybind in ipairs(M.previous_keybinds or {}) do
        safe_del_keymap('n', keybind)
    end
    M.previous_keybinds = {}

    local opts = { noremap = true, silent = true, desc = 'CodeRunner' }

    -- Main run keymap
    vim.keymap.set('n', M.config.keymap, function()
        require('code-runner').run()
    end, vim.tbl_extend('force', opts, { desc = 'Run code' }))
    table.insert(M.previous_keybinds, M.config.keymap)

    -- Interrupt keymap
    vim.keymap.set('n', M.config.interrupt_keymap, function()
        require('code-runner').send_interrupt()
    end, vim.tbl_extend('force', opts, { desc = 'Interrupt execution' }))
    table.insert(M.previous_keybinds, M.config.interrupt_keymap)

    -- Custom keybinds from coderun.json
    if M.config.coderun_keybinds then
        for keybind, cmd in pairs(M.config.coderun_keybinds) do
            vim.keymap.set('n', keybind, function()
                require('code-runner').run_custom(cmd)
            end, vim.tbl_extend('force', opts, { desc = 'Run: ' .. cmd:sub(1, 30) }))
            table.insert(M.previous_keybinds, keybind)
            log_debug('Set keybind: ' .. keybind)
        end
    end
end

---Load configuration from coderun.json or defaults
function M.load_configuration()
    -- Reset to defaults
    M.config = deep_merge(M.defaults, {})
    M.coderun_dir = nil
    M.config.coderun_commands = {}
    M.config.coderun_keybinds = {}

    local json_path = M.find_coderun_json_path()

    if not json_path then
        M.set_keymaps()
        return
    end

    M.load_json_config(json_path, function(json_config)
        if json_config then
            M.coderun_dir = vim.fn.fnamemodify(json_path, ':h')

            for name, entry in pairs(json_config) do
                if entry.command and entry.keybind then
                    M.config.coderun_commands[entry.keybind] = entry.command
                    M.config.coderun_keybinds[entry.keybind] = entry.command
                    log_debug('Loaded command "' .. name .. '" on ' .. entry.keybind)
                end
            end
        end
        M.set_keymaps()
    end)
end

---Stop watching coderun.json
function M.stop_watching()
    if M.watch_handle then
        pcall(function()
            M.watch_handle:stop()
            M.watch_handle:close()
        end)
        M.watch_handle = nil
        log_debug('Stopped file watcher')
    end
end

---Start watching coderun.json for changes
function M.start_watching()
    M.stop_watching()

    local json_path = M.find_coderun_json_path()
    if not json_path then
        return
    end

    M.watch_handle = uv.new_fs_event()
    if not M.watch_handle then
        log_debug('Failed to create file watcher')
        return
    end

    local debounce_timer = nil
    local function on_change(err, filename, events)
        if err then
            log_debug('Watch error: ' .. err)
            return
        end

        -- Debounce rapid changes
        if debounce_timer then
            debounce_timer:stop()
            debounce_timer:close()
        end

        debounce_timer = uv.new_timer()
        debounce_timer:start(100, 0, vim.schedule_wrap(function()
            debounce_timer:stop()
            debounce_timer:close()
            debounce_timer = nil

            log_info('coderun.json changed, reloading...')
            -- Clear accepted hash to prompt for re-acceptance
            M.accepted_configs[json_path] = nil
            M.rejected_configs[json_path] = nil
            M.load_configuration()
        end))
    end

    local ok, err = pcall(function()
        M.watch_handle:start(json_path, {}, vim.schedule_wrap(on_change))
    end)

    if ok then
        log_debug('Watching: ' .. json_path)
    else
        log_debug('Failed to watch file: ' .. (err or 'unknown'))
    end
end

---Handle buffer events
function M.on_buffer_event()
    -- Debounce buffer events
    if M._buffer_event_timer then
        M._buffer_event_timer:stop()
        M._buffer_event_timer:close()
    end

    M._buffer_event_timer = uv.new_timer()
    M._buffer_event_timer:start(50, 0, vim.schedule_wrap(function()
        if M._buffer_event_timer then
            M._buffer_event_timer:stop()
            M._buffer_event_timer:close()
            M._buffer_event_timer = nil
        end

        log_debug('Buffer event - reloading config')
        M.load_configuration()
        M.start_watching()
    end))
end

---Set up autocommands
function M.setup_autocmds()
    local group = vim.api.nvim_create_augroup('CodeRunner', { clear = true })

    vim.api.nvim_create_autocmd('BufEnter', {
        group = group,
        pattern = '*',
        callback = function()
            -- Only trigger for real files
            local buftype = vim.bo.buftype
            if buftype == '' then
                M.on_buffer_event()
            end
        end,
        desc = 'CodeRunner: reload config on buffer enter',
    })

    vim.api.nvim_create_autocmd('VimLeavePre', {
        group = group,
        callback = function()
            M.stop_watching()
        end,
        desc = 'CodeRunner: cleanup on exit',
    })
end

---Create user commands
function M.setup_commands()
    vim.api.nvim_create_user_command('CodeRunnerRun', function()
        M.run()
    end, { desc = 'Run current file' })

    vim.api.nvim_create_user_command('CodeRunnerInterrupt', function()
        M.send_interrupt()
    end, { desc = 'Interrupt running code' })

    vim.api.nvim_create_user_command('CodeRunnerReload', function()
        M.accepted_configs = {}
        M.rejected_configs = {}
        M.load_configuration()
        M.start_watching()
        log_info('Configuration reloaded')
    end, { desc = 'Reload CodeRunner configuration' })

    vim.api.nvim_create_user_command('CodeRunnerDebug', function()
        M.config.debug = not M.config.debug
        log_info('Debug mode: ' .. (M.config.debug and 'ON' or 'OFF'))
    end, { desc = 'Toggle debug mode' })
end

---Setup the plugin
---@param opts table|nil User configuration
function M.setup(opts)
    -- Merge user options with defaults
    M.defaults = deep_merge(M.defaults, opts or {})
    M.config = deep_merge(M.defaults, {})

    -- Initialize state
    M.accepted_configs = {}
    M.rejected_configs = {}
    M.previous_keybinds = {}
    M.prompt_active = false
    M.lock = false
    M.interrupting = false

    -- Setup components
    M.setup_commands()
    M.setup_autocmds()
    M.load_configuration()

    log_debug('CodeRunner initialized')
end

return M
