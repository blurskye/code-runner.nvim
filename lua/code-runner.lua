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
-- M.previous_keybinds = {}
-- M.accepted_configs = {}

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

-- -- Show prompt to accept or reject coderun.json
-- local function show_accept_prompt(json_path, content, hash, callback)
--     local Popup = require('nui.popup')
--     local event = require('nui.utils.autocmd').event

--     -- Wrap content in ```json for syntax highlighting
--     local lines = {"```json"}
--     for line in content:gmatch("[^\r\n]+") do
--         table.insert(lines, line)
--     end
--     table.insert(lines, "```")

--     local popup = Popup({
--         enter = true,
--         focusable = true,
--         border = {
--             style = "rounded",
--             text = {
--                 top = " Accept coderun.json? [y/n] ",
--                 top_align = "center",
--             },
--         },
--         position = "50%",
--         size = {
--             width = "80%",
--             height = "60%",
--         },
--         buf_options = {
--             modifiable = false,
--             readonly = true,
--             filetype = "markdown",  -- Set filetype for syntax highlighting
--         },
--         win_options = {
--             cursorline = true,
--         },
--     })

--     -- Set buffer lines
--     vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)

--     -- Map keys for scrolling and accepting/rejecting
--     popup:map("n", "<Esc>", function()
--         popup:unmount()
--         if callback then callback(false) end
--     end, { noremap = true })

--     -- Allow scrolling with arrow keys and hjkl
--     local scroll_mappings = { k = 'k', j = 'j', h = 'h', l = 'l', ['<Up>'] = 'k', ['<Down>'] = 'j', ['<Left>'] = 'h', ['<Right>'] = 'l' }
--     for key, cmd in pairs(scroll_mappings) do
--         popup:map('n', key, cmd, { noremap = true, nowait = true })
--     end

--     local accept = nil

--     popup:map('n', 'y', function()
--         accept = true
--         popup:unmount()
--         if accept then
--             M.accepted_configs[json_path] = hash
--             log_debug("User accepted coderun.json at " .. json_path)
--             if callback then callback(true) end
--         end
--     end, { noremap = true })

--     popup:map('n', 'n', function()
--         accept = false
--         popup:unmount()
--         log_debug("User rejected coderun.json at " .. json_path)
--         if callback then callback(false) end
--     end, { noremap = true })

--     -- Mount the popup
--     popup:mount()

--     -- Automatically focus on the popup window
--     vim.api.nvim_set_current_win(popup.winid)
-- end

-- -- Load JSON configuration
-- function M.load_json_config(json_path, callback)
--     local file = io.open(json_path, "r")
--     if not file then
--         vim.notify("Failed to open coderun.json at " .. json_path, vim.log.levels.ERROR)
--         if callback then callback(nil) end
--         return
--     end
--     local content = file:read("*all")
--     file:close()

--     local hash = vim.fn.sha256(content)
--     log_debug("Computed hash: " .. hash)

--     -- Check if hash matches accepted hash
--     if M.accepted_configs[json_path] == hash then
--         log_debug("coderun.json has been previously accepted")
--         local success, json_data = pcall(vim.fn.json_decode, content)
--         if not success then
--             vim.notify("Failed to parse coderun.json. Please check JSON syntax.", vim.log.levels.ERROR)
--             if callback then callback(nil) end
--             return
--         end
--         log_debug("Successfully loaded coderun.json")
--         if callback then callback(json_data) end
--     else
--         -- Prompt the user to accept or reject
--         show_accept_prompt(json_path, content, hash, function(accepted)
--             if accepted then
--                 local success, json_data = pcall(vim.fn.json_decode, content)
--                 if not success then
--                     vim.notify("Failed to parse coderun.json. Please check JSON syntax.", vim.log.levels.ERROR)
--                     if callback then callback(nil) end
--                     return
--                 end
--                 log_debug("Successfully loaded coderun.json")
--                 if callback then callback(json_data) end
--             else
--                 vim.notify("coderun.json was rejected. Using default configuration.", vim.log.levels.INFO)
--                 if callback then callback(nil) end
--             end
--         end)
--     end
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

--     -- If we have a coderun directory, prepend cd command
--     if M.coderun_dir then
--         -- Escape spaces in path
--         local escaped_dir = M.coderun_dir:gsub(" ", "\\ ")
--         cmd = "cd " .. escaped_dir .. " && " .. cmd
--     end

--     vim.cmd("SendToSkyTerm " .. cmd)
--     if M.config.debug then
--         vim.notify("Running: " .. cmd, vim.log.levels.INFO)
--     end

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
--     if M.interrupting then
--         return
--     end
--     M.interrupting = true
--     local current_mode = vim.api.nvim_get_mode().mode

--     require('sky-term').toggle_term_wrapper()
--     vim.defer_fn(function()
--         vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, true, true), 'n', true)
--         vim.defer_fn(function()
--             require('sky-term').toggle_term_wrapper()
--             if current_mode:sub(1, 1) == 'i' then
--                 vim.defer_fn(function()
--                     vim.cmd('startinsert')
--                     M.interrupting = false
--                 end, 50)
--             else
--                 M.interrupting = false
--             end
--         end, 50)
--     end, 100)
-- end

-- -- Set up keybindings
-- function M.set_keymaps()
--     -- Unbind previous keymaps if they exist
--     if M.previous_keybinds and next(M.previous_keybinds) then
--         for _, keybind in ipairs(M.previous_keybinds) do
--             if vim.fn.maparg(keybind, 'n') ~= '' then
--                 vim.api.nvim_del_keymap('n', keybind)
--                 log_debug("Unbound previous keybind: " .. keybind)
--             end
--         end
--     end

--     M.previous_keybinds = {}

--     -- Bind the run key
--     vim.api.nvim_set_keymap('n', M.config.keymap, "<Cmd>lua require('code-runner').run()<CR>", { noremap = true, silent = true })
--     table.insert(M.previous_keybinds, M.config.keymap)

--     -- Bind the interrupt key
--     vim.api.nvim_set_keymap('n', M.config.interrupt_keymap, "<Cmd>lua require('code-runner').send_interrupt()<CR>", { noremap = true, silent = true })
--     table.insert(M.previous_keybinds, M.config.interrupt_keymap)

--     -- Set keymaps from coderun.json
--     if M.config.coderun_keybinds then
--         for keybind, cmd in pairs(M.config.coderun_keybinds) do
--             vim.api.nvim_set_keymap('n', keybind, "<Cmd>lua require('code-runner').run_custom('" .. cmd .. "')<CR>", { noremap = true, silent = true })
--             table.insert(M.previous_keybinds, keybind)
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
--         M.load_json_config(json_path, function(json_config)
--             if json_config then
--                 -- Process custom commands and keybinds
--                 M.config.coderun_commands = {}
--                 M.config.coderun_keybinds = {}
--                 for _, entry in pairs(json_config) do
--                     if entry.command and entry.keybind then
--                         M.config.coderun_commands[entry.keybind] = entry.command
--                         M.config.coderun_keybinds[entry.keybind] = entry.command
--                         log_debug("Loaded command from coderun.json: keybind=" .. entry.keybind .. ", command=" .. entry.command)
--                     end
--                 end
--             else
--                 log_debug("Failed to load json_config")
--             end
--             M.set_keymaps()
--         end)
--     else
--         M.coderun_dir = nil
--         log_debug("coderun.json not found during configuration load")
--         M.set_keymaps()
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
--         vim.notify("coderun.json changed.", vim.log.levels.INFO)
--         -- Reload configuration
--         M.load_configuration()
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
--     M.start_watching()
-- end

-- -- Setup function
-- function M.setup(user_opts)
--     M.defaults = merge_tables(M.defaults, user_opts)
--     M.config = vim.deepcopy(M.defaults)
--     M.load_configuration()
--     M.setup_autocmds()
-- end

-- return M





-- local M = {}
-- local uv = vim.loop

-- -- Default configurations
-- M.defaults = {
--     keymap = '<F5>',
--     interrupt_keymap = '<F2>',
--     commands = {
--         python = "python3 -u \"$dir/$fileName\"",
--         javascript = "node \"$dir/$fileName\"",
--         typescript = "ts-node \"$dir/$fileName\"",
--         lua = "lua \"$dir/$fileName\"",
--         ruby = "ruby \"$dir/$fileName\"",
--         go = "go run \"$filePath\"",
--         c = "gcc \"$dir/$fileName\" -o \"$dir/$fileNameWithoutExt\" && \"$dir/$fileNameWithoutExt\"",
--         cpp = "g++ \"$dir/$fileName\" -o \"$dir/$fileNameWithoutExt\" && \"$dir/$fileNameWithoutExt\"",
--         java = "javac \"$dir/$fileName\" && java -cp \"$dir\" \"$fileNameWithoutExt\"",
--         sh = "bash \"$dir/$fileName\"",
--         rust = "rustc \"$dir/$fileName\" && \"$dir/$fileNameWithoutExt\"",
--         php = "php \"$dir/$fileName\"",
--         perl = "perl \"$dir/$fileName\"",
--         -- Add more languages as needed
--     },
--     extensions = {
--         python = { "py" },
--         javascript = { "js" },
--         typescript = { "ts" },
--         lua = { "lua" },
--         ruby = { "rb" },
--         go = { "go" },
--         c = { "c" },
--         cpp = { "cpp", "cc", "cxx", "c++" },
--         java = { "java" },
--         sh = { "sh" },
--         rust = { "rs" },
--         php = { "php" },
--         perl = { "pl", "pm" },
--         -- Add more extensions as needed
--     },
--     debug = false, -- Debug mode flag
-- }

-- M.config = {}
-- M.watch_handle = nil
-- M.lock = false
-- M.previous_keybinds = {}
-- M.accepted_configs = {}
-- M.prompt_active = false -- Add this flag

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

-- -- Show prompt to accept or reject coderun.json
-- local function show_accept_prompt(json_path, content, hash, callback)
--     if M.prompt_active then
--         log_debug("Prompt is already active; skipping additional prompt.")
--         return
--     end
--     M.prompt_active = true

--     local Popup = require('nui.popup')

--     -- Wrap content in ```json for syntax highlighting
--     local lines = {"```json"}
--     for line in content:gmatch("[^\r\n]+") do
--         table.insert(lines, line)
--     end
--     table.insert(lines, "```")

--     local popup = Popup({
--         enter = true,
--         focusable = true,
--         border = {
--             style = "rounded",
--             text = {
--                 top = " Accept coderun.json? [y/n] ",
--                 top_align = "center",
--             },
--         },
--         position = "50%",
--         size = {
--             width = "80%",
--             height = "60%",
--         },
--         buf_options = {
--             modifiable = false,
--             readonly = true,
--             filetype = "markdown",  -- Set filetype for syntax highlighting
--         },
--         win_options = {
--             cursorline = true,
--         },
--     })

--     -- Set buffer lines
--     vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)

--     -- Map keys for scrolling and accepting/rejecting
--     popup:map("n", "<Esc>", function()
--         popup:unmount()
--         M.prompt_active = false
--         if callback then callback(false) end
--     end, { noremap = true })

--     -- Allow scrolling with arrow keys and hjkl
--     local scroll_mappings = { k = 'k', j = 'j', h = 'h', l = 'l', ['<Up>'] = 'k', ['<Down>'] = 'j', ['<Left>'] = 'h', ['<Right>'] = 'l' }
--     for key, cmd in pairs(scroll_mappings) do
--         popup:map('n', key, cmd, { noremap = true, nowait = true })
--     end

--     popup:map('n', 'y', function()
--         popup:unmount()
--         M.accepted_configs[json_path] = hash
--         M.prompt_active = false
--         log_debug("User accepted coderun.json at " .. json_path)
--         if callback then callback(true) end
--     end, { noremap = true })

--     popup:map('n', 'n', function()
--         popup:unmount()
--         M.prompt_active = false
--         log_debug("User rejected coderun.json at " .. json_path)
--         if callback then callback(false) end
--     end, { noremap = true })

--     -- Mount the popup
--     popup:mount()

--     -- Automatically focus on the popup window
--     vim.api.nvim_set_current_win(popup.winid)
-- end

-- -- Load JSON configuration
-- function M.load_json_config(json_path, callback)
--     local file = io.open(json_path, "r")
--     if not file then
--         vim.notify("Failed to open coderun.json at " .. json_path, vim.log.levels.ERROR)
--         if callback then callback(nil) end
--         return
--     end
--     local content = file:read("*all")
--     file:close()

--     local hash = vim.fn.sha256(content)
--     log_debug("Computed hash: " .. hash)

--     -- Check if hash matches accepted hash
--     if M.accepted_configs[json_path] == hash then
--         log_debug("coderun.json has been previously accepted")
--         local success, json_data = pcall(vim.fn.json_decode, content)
--         if not success then
--             vim.notify("Failed to parse coderun.json. Please check JSON syntax.", vim.log.levels.ERROR)
--             if callback then callback(nil) end
--             return
--         end
--         log_debug("Successfully loaded coderun.json")
--         if callback then callback(json_data) end
--     else
--         -- Prompt the user to accept or reject
--         show_accept_prompt(json_path, content, hash, function(accepted)
--             if accepted then
--                 local success, json_data = pcall(vim.fn.json_decode, content)
--                 if not success then
--                     vim.notify("Failed to parse coderun.json. Please check JSON syntax.", vim.log.levels.ERROR)
--                     if callback then callback(nil) end
--                     return
--                 end
--                 log_debug("Successfully loaded coderun.json")
--                 M.accepted_configs[json_path] = hash -- Save accepted hash
--                 if callback then callback(json_data) end
--             else
--                 vim.notify("coderun.json was rejected. Using default configuration.", vim.log.levels.INFO)
--                 if callback then callback(nil) end
--             end
--         end)
--     end
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

--     -- If we have a coderun directory, prepend cd command
--     if M.coderun_dir then
--         -- Escape spaces in path
--         local escaped_dir = M.coderun_dir:gsub(" ", "\\ ")
--         cmd = "cd " .. escaped_dir .. " && " .. cmd
--     end

--     vim.cmd("SendToSkyTerm " .. cmd)
--     if M.config.debug then
--         vim.notify("Running: " .. cmd, vim.log.levels.INFO)
--     end

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
--     if M.interrupting then
--         return
--     end
--     M.interrupting = true
--     local current_mode = vim.api.nvim_get_mode().mode

--     require('sky-term').toggle_term_wrapper()
--     vim.defer_fn(function()
--         vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, true, true), 'n', true)
--         vim.defer_fn(function()
--             require('sky-term').toggle_term_wrapper()
--             if current_mode:sub(1, 1) == 'i' then
--                 vim.defer_fn(function()
--                     vim.cmd('startinsert')
--                     M.interrupting = false
--                 end, 50)
--             else
--                 M.interrupting = false
--             end
--         end, 50)
--     end, 100)
-- end

-- -- Set up keybindings
-- function M.set_keymaps()
--     -- Unbind previous keymaps if they exist
--     if M.previous_keybinds and next(M.previous_keybinds) then
--         for _, keybind in ipairs(M.previous_keybinds) do
--             if vim.fn.maparg(keybind, 'n') ~= '' then
--                 vim.api.nvim_del_keymap('n', keybind)
--                 log_debug("Unbound previous keybind: " .. keybind)
--             end
--         end
--     end

--     M.previous_keybinds = {}

--     -- Bind the run key
--     vim.api.nvim_set_keymap('n', M.config.keymap, "<Cmd>lua require('code-runner').run()<CR>", { noremap = true, silent = true })
--     table.insert(M.previous_keybinds, M.config.keymap)

--     -- Bind the interrupt key
--     vim.api.nvim_set_keymap('n', M.config.interrupt_keymap, "<Cmd>lua require('code-runner').send_interrupt()<CR>", { noremap = true, silent = true })
--     table.insert(M.previous_keybinds, M.config.interrupt_keymap)

--     -- Set keymaps from coderun.json
--     if M.config.coderun_keybinds then
--         for keybind, cmd in pairs(M.config.coderun_keybinds) do
--             vim.api.nvim_set_keymap('n', keybind, "<Cmd>lua require('code-runner').run_custom('" .. cmd .. "')<CR>", { noremap = true, silent = true })
--             table.insert(M.previous_keybinds, keybind)
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
--         M.load_json_config(json_path, function(json_config)
--             if json_config then
--                 -- Process custom commands and keybinds
--                 M.config.coderun_commands = {}
--                 M.config.coderun_keybinds = {}
--                 for _, entry in pairs(json_config) do
--                     if entry.command and entry.keybind then
--                         M.config.coderun_commands[entry.keybind] = entry.command
--                         M.config.coderun_keybinds[entry.keybind] = entry.command
--                         log_debug("Loaded command from coderun.json: keybind=" .. entry.keybind .. ", command=" .. entry.command)
--                     end
--                 end
--             else
--                 log_debug("Failed to load json_config")
--             end
--             M.set_keymaps()
--         end)
--     else
--         M.coderun_dir = nil
--         log_debug("coderun.json not found during configuration load")
--         M.set_keymaps()
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
--         vim.notify("coderun.json changed.", vim.log.levels.INFO)
--         -- Reload configuration
--         M.load_configuration()
--     end))
-- end

-- -- **Modified setup_autocmds function**
-- function M.setup_autocmds()
--     -- Create an augroup to prevent duplicate autocmds
--     local group = vim.api.nvim_create_augroup("CodeRunnerAutocmds", { clear = true })
--     vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave" }, {
--         group = group,
--         callback = function()
--             M.on_buffer_event()
--         end,
--     })
-- end

-- -- Function to handle buffer events
-- function M.on_buffer_event()
--     log_debug("Buffer event triggered. Reloading configuration.")
--     M.load_configuration()
--     M.start_watching()
-- end

-- -- Setup function
-- function M.setup(user_opts)
--     M.defaults = merge_tables(M.defaults, user_opts)
--     M.config = vim.deepcopy(M.defaults)
--     M.load_configuration()
--     M.setup_autocmds()
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
        javascript = "node \"$dir/$fileName\"",
        typescript = "ts-node \"$dir/$fileName\"",
        lua = "lua \"$dir/$fileName\"",
        ruby = "ruby \"$dir/$fileName\"",
        go = "go run \"$filePath\"",
        c = "gcc \"$dir/$fileName\" -o \"$dir/$fileNameWithoutExt\" && \"$dir/$fileNameWithoutExt\"",
        cpp = "g++ \"$dir/$fileName\" -o \"$dir/$fileNameWithoutExt\" && \"$dir/$fileNameWithoutExt\"",
        java = "javac \"$dir/$fileName\" && java -cp \"$dir\" \"$fileNameWithoutExt\"",
        sh = "bash \"$dir/$fileName\"",
        rust = "rustc \"$dir/$fileName\" && \"$dir/$fileNameWithoutExt\"",
        php = "php \"$dir/$fileName\"",
        perl = "perl \"$dir/$fileName\"",
        -- Add more languages as needed
    },
    extensions = {
        python = { "py" },
        javascript = { "js" },
        typescript = { "ts" },
        lua = { "lua" },
        ruby = { "rb" },
        go = { "go" },
        c = { "c" },
        cpp = { "cpp", "cc", "cxx", "c++" },
        java = { "java" },
        sh = { "sh" },
        rust = { "rs" },
        php = { "php" },
        perl = { "pl", "pm" },
        -- Add more extensions as needed
    },
    debug = false, -- Debug mode flag
}

M.config = {}
M.watch_handle = nil
M.lock = false
M.previous_keybinds = {}
M.accepted_configs = {}
M.prompt_active = false

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

-- Show prompt to accept or reject coderun.json
local function show_accept_prompt(json_path, content, hash, callback)
    if M.prompt_active then
        log_debug("Prompt is already active; skipping additional prompt.")
        return
    end
    M.prompt_active = true

    local Popup = require('nui.popup')

    -- Wrap content in ```json for syntax highlighting
    local lines = {"```json"}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    table.insert(lines, "```")

    local popup = Popup({
        enter = true,
        focusable = true,
        border = {
            style = "rounded",
            text = {
                top = " Accept coderun.json? [y/n] ",
                top_align = "center",
            },
        },
        position = "50%",
        size = {
            width = "80%",
            height = "60%",
        },
        buf_options = {
            modifiable = false,
            readonly = true,
            filetype = "markdown",  -- Set filetype for syntax highlighting
        },
        win_options = {
            cursorline = true,
        },
    })

    -- Set buffer lines
    vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)

    -- Map keys for scrolling and accepting/rejecting
    popup:map("n", "<Esc>", function()
        popup:unmount()
        M.prompt_active = false
        if callback then callback(false) end
    end, { noremap = true })

    -- Allow scrolling with arrow keys and hjkl
    local scroll_mappings = { k = 'k', j = 'j', h = 'h', l = 'l', ['<Up>'] = 'k', ['<Down>'] = 'j', ['<Left>'] = 'h', ['<Right>'] = 'l' }
    for key, cmd in pairs(scroll_mappings) do
        popup:map('n', key, cmd, { noremap = true, nowait = true })
    end

    popup:map('n', 'y', function()
        popup:unmount()
        M.accepted_configs[json_path] = hash
        M.prompt_active = false
        log_debug("User accepted coderun.json at " .. json_path)
        if callback then callback(true) end
    end, { noremap = true })

    popup:map('n', 'n', function()
        popup:unmount()
        M.prompt_active = false
        log_debug("User rejected coderun.json at " .. json_path)
        if callback then callback(false) end
    end, { noremap = true })

    -- Mount the popup
    popup:mount()

    -- Automatically focus on the popup window
    vim.api.nvim_set_current_win(popup.winid)
end

-- Load JSON configuration
function M.load_json_config(json_path, callback)
    local file = io.open(json_path, "r")
    if not file then
        vim.notify("Failed to open coderun.json at " .. json_path, vim.log.levels.ERROR)
        if callback then callback(nil) end
        return
    end
    local content = file:read("*all")
    file:close()

    local hash = vim.fn.sha256(content)
    log_debug("Computed hash: " .. hash)

    -- Check if hash matches accepted hash
    if M.accepted_configs[json_path] == hash then
        log_debug("coderun.json has been previously accepted")
        local success, json_data = pcall(vim.fn.json_decode, content)
        if not success then
            vim.notify("Failed to parse coderun.json. Please check JSON syntax.", vim.log.levels.ERROR)
            if callback then callback(nil) end
            return
        end
        log_debug("Successfully loaded coderun.json")
        if callback then callback(json_data) end
    else
        -- Prompt the user to accept or reject
        show_accept_prompt(json_path, content, hash, function(accepted)
            if accepted then
                local success, json_data = pcall(vim.fn.json_decode, content)
                if not success then
                    vim.notify("Failed to parse coderun.json. Please check JSON syntax.", vim.log.levels.ERROR)
                    if callback then callback(nil) end
                    return
                end
                log_debug("Successfully loaded coderun.json")
                M.accepted_configs[json_path] = hash -- Save accepted hash
                if callback then callback(json_data) end
            else
                vim.notify("coderun.json was rejected. Using default configuration.", vim.log.levels.INFO)
                if callback then callback(nil) end
            end
        end)
    end
end

-- Generate command
function M.generate_command(command_template)
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local file_dir = vim.fn.fnamemodify(file_path, ":h")
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local file_name_without_ext = vim.fn.fnamemodify(file_path, ":t:r")
    local file_extension = vim.fn.fnamemodify(file_path, ":e")
    local coderun_dir = M.coderun_dir

    local cmd = command_template
        :gsub("$dir", file_dir)
        :gsub("$fileName", file_name)
        :gsub("$fileNameWithoutExt", file_name_without_ext)
        :gsub("$fileExtension", file_extension)
        :gsub("$filePath", file_path)
        :gsub("$coderunDir", coderun_dir or "")
    return cmd
end

-- Run the command
function M.run_command(cmd)
    if M.lock then
        vim.notify("CodeRunner is busy. Please wait...", vim.log.levels.WARN)
        return
    end

    M.lock = true

    -- If we have a coderun directory, prepend cd command
    if M.coderun_dir then
        -- Escape spaces in path
        local escaped_dir = M.coderun_dir:gsub(" ", "\\ ")
        cmd = "cd " .. escaped_dir .. " && " .. cmd
    end

    vim.cmd("SendToSkyTerm " .. cmd)
    if M.config.debug then
        vim.notify("Running: " .. cmd, vim.log.levels.INFO)
    end

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
    if M.interrupting then
        return
    end
    M.interrupting = true
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
    M.coderun_dir = nil -- Initialize to nil
    local json_path = M.find_coderun_json_path()
    if json_path then
        M.load_json_config(json_path, function(json_config)
            if json_config then
                M.coderun_dir = vim.fn.fnamemodify(json_path, ":h") -- Set only if accepted
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
                log_debug("User rejected coderun.json or failed to load json_config")
            end
            M.set_keymaps()
        end)
    else
        log_debug("coderun.json not found during configuration load")
        M.set_keymaps()
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
        vim.notify("coderun.json changed.", vim.log.levels.INFO)
        -- Reload configuration
        M.load_configuration()
    end))
end

-- Setup autocmds using Neovim Lua API
function M.setup_autocmds()
    -- Create an augroup to prevent duplicate autocmds
    local group = vim.api.nvim_create_augroup("CodeRunnerAutocmds", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave" }, {
        group = group,
        callback = function()
            M.on_buffer_event()
        end,
    })
end

-- Function to handle buffer events
function M.on_buffer_event()
    log_debug("Buffer event triggered. Reloading configuration.")
    M.load_configuration()
    M.start_watching()
end

-- Setup function
function M.setup(user_opts)
    M.defaults = merge_tables(M.defaults, user_opts)
    M.config = vim.deepcopy(M.defaults)
    M.load_configuration()
    M.setup_autocmds()
end

return M
