local M = {}
local uv = vim.loop

-- Default configurations
M.defaults = {
    keymap = '<F5>',
    interrupt_keymap = '<F2>',
    commands = {
        python = "python3 -u \"$dir/$fileName\"",
        java = "cd \"$dir\" && javac \"$fileName\" && java \"$fileNameWithoutExt\"",
        typescript = "deno run \"$dir/$fileName\"",
        rust = "cd \"$dir\" && rustc \"$fileName\" && \"$dir/$fileNameWithoutExt\"",
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
M.watch_handle = nil
M.lock = false

-- Utility function to merge tables
local function merge_tables(default, user)
    if not user then return default end
    for k, v in pairs(user) do
        if type(v) == "table" and type(default[k] or false) == "table" then
            default[k] = merge_tables(default[k], v)
        else
            default[k] = v
        end
    end
    return default
end

-- Find the path to coderun.json
function M.find_coderun_json_path(start_path)
    local path = start_path or vim.fn.expand("%:p:h")
    while path and path ~= "/" do
        local json_path = path .. "/coderun.json"
        if vim.fn.filereadable(json_path) == 1 then
            return json_path
        end
        path = vim.fn.fnamemodify(path, ":h")
    end
    return nil
end

-- Load JSON configuration
function M.load_json_config(json_path)
    local file = io.open(json_path, "r")
    if not file then return {} end
    local content = file:read("*all")
    file:close()
    local success, json_data = pcall(vim.fn.json_decode, content)
    if not success then return {} end
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
        vim.notify("Please wait a moment before running another command.", vim.log.levels.WARN)
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

    local cmd = M.generate_command(command)
    M.run_command(cmd)
end

-- Interrupt the running command
function M.send_interrupt()
    vim.cmd("SendToSkyTerm Ctrl+C")
    vim.notify("Interrupt signal sent.", vim.log.levels.INFO)
end

-- Set up keybindings
function M.set_keymaps()
    -- Clear previous keymaps if they exist
    if M.config.keymap and vim.fn.maparg(M.config.keymap, 'n') ~= '' then
        vim.api.nvim_del_keymap('n', M.config.keymap)
    end

    if M.config.interrupt_keymap and vim.fn.maparg(M.config.interrupt_keymap, 'n') ~= '' then
        vim.api.nvim_del_keymap('n', M.config.interrupt_keymap)
    end

    -- Bind the run key
    vim.api.nvim_set_keymap('n', M.config.keymap, "<Cmd>lua require('code-runner').run()<CR>", { noremap = true, silent = true })

    -- Bind the interrupt key
    vim.api.nvim_set_keymap('n', M.config.interrupt_keymap, "<Cmd>lua require('code-runner').send_interrupt()<CR>", { noremap = true, silent = true })

    -- Set keymaps from coderun.json
    if M.config.custom_keybinds then
        for _, bind in pairs(M.config.custom_keybinds) do
            vim.api.nvim_set_keymap('n', bind.keybind, "<Cmd>lua require('code-runner').run_custom('" .. bind.command .. "')<CR>", { noremap = true, silent = true })
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
            M.config.custom_keybinds = {}
            for name, entry in pairs(json_config) do
                table.insert(M.config.custom_keybinds, {
                    command = entry.command,
                    keybind = entry.keybind
                })
            end
        end
    end
end

-- Watch for changes in coderun.json
function M.start_watching()
    if M.watch_handle then
        M.watch_handle:stop()
        M.watch_handle:close()
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

-- Setup function
function M.setup(user_opts)
    M.defaults = merge_tables(M.defaults, user_opts)
    M.load_configuration()
    M.set_keymaps()
    M.start_watching()
end

return M
