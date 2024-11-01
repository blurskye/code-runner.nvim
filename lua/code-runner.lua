-- lua/code-runner.lua

local M = {}
local uv = vim.loop
local Job = require('plenary.job') -- We'll use plenary for asynchronous job handling

-- Default configurations
M.defaults = {
    keymap = '<F5>', -- Keymap to run the code
    interrupt_keymap = '<F2>', -- Keymap to interrupt the running code
    commands = {
        python = "python3 -u \"$dir/$fileName\"",
        java = "cd \"$dir\" && javac \"$fileName\" && java \"$fileNameWithoutExt\"",
        typescript = "deno run \"$dir/$fileName\"",
        rust = "cargo run",
        c = "cd \"$dir\" && gcc \"$fileName\" -o \"$fileNameWithoutExt\" && \"$dir/$fileNameWithoutExt\"",
        cpp = "cd \"$dir\" && g++ \"$fileName\" -o \"$dir/$fileNameWithoutExt\" && \"$dir/$fileNameWithoutExt\"",
        javascript = "node \"$dir/$fileName\"",
        php = "php \"$dir/$fileName\"",
        ruby = "ruby \"$dir/$fileName\"",
        go = "go run \"$dir/$fileName\"",
        perl = "perl \"$dir/$fileName\"",
        bash = "bash \"$dir/$fileName\"",
        lisp = "sbcl --script \"$dir/$fileName\"",
        fortran = "cd \"$dir\" && gfortran \"$fileName\" -o \"$fileNameWithoutExt\" && \"$dir/$fileNameWithoutExt\"",
        haskell = "runhaskell \"$dir/$fileName\"",
        dart = "dart run \"$dir/$fileName\"",
        pascal = "cd \"$dir\" && fpc \"$fileName\" && \"$dir/$fileNameWithoutExt\"",
        nim = "nim compile --run \"$dir/$fileName\""
    },
    extensions = {
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
}

M.config = {}

-- Function to merge user options with defaults
local function merge_tables(default, user)
    if not user then return default end
    for k, v in pairs(user) do
        if type(v) == "table" and type(default[k] or false) == "table" then
            merge_tables(default[k], v)
        else
            default[k] = v
        end
    end
    return default
end

-- Find the path to coderun.json by searching up the directory tree
function M.find_coderun_json_path(start_path)
    local path = start_path or vim.fn.expand("%:p:h")
    while path ~= "/" and path ~= "." do
        local json_path = path .. "/coderun.json"
        if vim.fn.filereadable(json_path) == 1 then
            return json_path
        end
        path = vim.fn.fnamemodify(path, ":h")
    end
    return nil
end

-- Load JSON configuration from coderun.json
function M.load_json_config(json_path)
    local file, err = io.open(json_path, "r")
    if not file then
        vim.notify("Error opening coderun.json: " .. err, vim.log.levels.ERROR)
        return {}
    end
    local content = file:read("*all")
    file:close()
    local success, json_data = pcall(vim.fn.json_decode, content)
    if not success then
        vim.notify("Failed to parse coderun.json", vim.log.levels.ERROR)
        return {}
    end
    return json_data
end

-- Generate command based on the current file and configuration
function M.generate_command(config)
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local file_dir = vim.fn.fnamemodify(file_path, ":h")
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local file_name_without_ext = vim.fn.fnamemodify(file_path, ":t:r")
    local file_extension = vim.fn.fnamemodify(file_path, ":e")

    local cmd = config.command
        :gsub("$dir", file_dir)
        :gsub("$fileName", file_name)
        :gsub("$fileNameWithoutExt", file_name_without_ext)
        :gsub("$fileExtension", file_extension)
        :gsub("$filePath", file_path)

    return cmd
end

-- Run the generated command asynchronously
function M.run_command(cmd)
    if M.current_job and M.current_job:is_running() then
        vim.notify("A job is already running. Press interrupt key to stop it.", vim.log.levels.WARN)
        return
    end

    vim.notify("Running: " .. cmd, vim.log.levels.INFO)

    -- Open a new split terminal
    vim.cmd("split")
    vim.cmd("terminal")
    local term_buf = vim.api.nvim_get_current_buf()

    -- Start the job
    M.current_job = Job:new({
        command = "bash",
        args = { "-c", cmd },
        on_exit = function(j, return_val)
            vim.schedule(function()
                vim.api.nvim_buf_set_lines(term_buf, -1, -1, false, { "\nProcess exited with code " .. return_val })
                vim.api.nvim_buf_set_option(term_buf, "modifiable", false)
                vim.notify("Process exited with code " .. return_val, vim.log.levels.INFO)
            end)
        end,
        on_stdout = function(j, data)
            if data then
                vim.schedule(function()
                    vim.api.nvim_buf_set_lines(term_buf, -1, -1, false, { data })
                end)
            end
        end,
        on_stderr = function(j, data)
            if data then
                vim.schedule(function()
                    vim.api.nvim_buf_set_lines(term_buf, -1, -1, false, { data })
                end)
            end
        end,
    }):start()
end

-- Interrupt the running job
function M.send_interrupt()
    if M.current_job and M.current_job:is_running() then
        M.current_job:stop()
        vim.notify("Job interrupted", vim.log.levels.INFO)
    else
        vim.notify("No running job to interrupt", vim.log.levels.WARN)
    end
end

-- Set up keybindings
function M.set_keymaps()
    local keymap = M.config.keymap
    local interrupt_keymap = M.config.interrupt_keymap

    -- Unmap existing keymaps to avoid duplicates
    vim.api.nvim_set_keymap('n', keymap, '', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', interrupt_keymap, '', { noremap = true, silent = true })

    -- Bind the run key
    vim.api.nvim_set_keymap('n', keymap, "<Cmd>lua require('code-runner').run()<CR>", { noremap = true, silent = true })

    -- Bind the interrupt key
    vim.api.nvim_set_keymap('n', interrupt_keymap, "<Cmd>lua require('code-runner').send_interrupt()<CR>", { noremap = true, silent = true })
end

-- Run the code
function M.run()
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    if file_path == "" then
        vim.notify("No file is currently open.", vim.log.levels.WARN)
        return
    end

    local file_extension = vim.fn.fnamemodify(file_path, ":e")
    local language = nil

    -- Find the language based on the file extension
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

    -- Get the command for the language
    local command = M.config.commands[language]
    if not command then
        vim.notify("No command configured for language: " .. language, vim.log.levels.ERROR)
        return
    end

    local cmd = M.generate_command({ command = command })
    M.run_command(cmd)
end

-- Load configuration (defaults overridden by coderun.json if available)
function M.load_configuration()
    local current_dir = vim.fn.expand("%:p:h")
    local json_path = M.find_coderun_json_path(current_dir)
    if json_path then
        local json_config = M.load_json_config(json_path)
        merge_tables(M.config, json_config)
    else
        merge_tables(M.config, M.defaults)
    end
end

-- Setup function to initialize the plugin
function M.setup(user_opts)
    -- Merge user options with defaults
    merge_tables(M.defaults, user_opts)
    M.config = vim.deepcopy(M.defaults)

    -- Load configurations (including coderun.json if present)
    M.load_configuration()

    -- Set keybindings
    M.set_keymaps()

    -- Watch for changes in coderun.json
    M.start_watching()
end

-- Start watching for changes in coderun.json
function M.start_watching()
    local json_path = M.find_coderun_json_path()
    if not json_path then return end

    if M.fs_event then
        M.fs_event:stop()
        M.fs_event:close()
    end

    M.fs_event = uv.new_fs_event()
    M.fs_event:start(json_path, {}, vim.schedule_wrap(function(err, filename, events)
        if err then
            vim.notify("Error watching coderun.json: " .. err, vim.log.levels.ERROR)
            return
        end
        if events.change then
            vim.notify("coderun.json changed. Reloading configuration...", vim.log.levels.INFO)
            M.config = vim.deepcopy(M.defaults)
            M.load_configuration()
            M.set_keymaps()
        end
    end))
end

return M
