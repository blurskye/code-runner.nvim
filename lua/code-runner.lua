local M = {}

function M.unbind_commands(json_data)
	local modes = { "n", "i", "v", "t" }

	if json_data then
		for _, v in pairs(json_data) do
			if v.command and v.keybind then
				for _, mode in ipairs(modes) do
					vim.api.nvim_set_keymap(mode, v.keybind, "", { noremap = true, silent = true })
				end
			end
		end
	end
end

function M.adjust_command_path()
	if M.coderun_json_dir then
		return M.coderun_json_dir
	end

	return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
end

local function keybind_exists(keybind)
	local modes = { "n", "i", "v", "t" }
	for _, mode in ipairs(modes) do
		local keymaps = vim.api.nvim_get_keymap(mode)
		for _, map in pairs(keymaps) do
			if map.lhs == keybind then
				return true
			end
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
	local buf_type = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "buftype")
	local terminal_win = nil
	if buf_type == "terminal" then
		terminal_win = vim.api.nvim_get_current_win()
	else
		local windows = vim.api.nvim_list_wins()
		for _, win in ipairs(windows) do
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
				terminal_win = win
				break
			end
		end
		if not terminal_win then
			vim.cmd(M.toggle_term_command)

			local windows = vim.api.nvim_list_wins()
			for _, win in ipairs(windows) do
				local buf = vim.api.nvim_win_get_buf(win)
				if vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
					terminal_win = win
					break
				end
			end
		end
	end
	if terminal_win then
		vim.api.nvim_set_current_win(terminal_win)
		vim.defer_fn(function()
			vim.api.nvim_exec("startinsert", false)
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, true, true), "n", true)
			vim.defer_fn(function()
				if M.toggle_term_command == "ToggleSkyTerm" then
					vim.cmd(M.toggle_term_command)
				else
					vim.api.nvim_set_current_win(current_win)
				end
				if current_mode:sub(1, 1) == "i" then
					vim.defer_fn(function()
						vim.api.nvim_exec("startinsert", false)
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
	if json_data then
		for _, v in pairs(json_data) do
			if v.command and v.keybind then
				local file_buffer = vim.api.nvim_buf_get_name(0)

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

				local modes = { "n", "i", "v", "t" }
				for _, mode in ipairs(modes) do
					vim.api.nvim_set_keymap(
						mode,
						v.keybind,
						"<Cmd>lua require('code-runner').run_command('" .. cmd .. "')<CR>",
						{ noremap = true, silent = true }
					)
				end
			end
		end
	end
end

function M.preview_file(file_path)
	if not file_path or not vim.fn.filereadable(file_path) then
		print("Invalid file path: " .. tostring(file_path))
		return
	end

	local preview_buf = vim.api.nvim_create_buf(false, true)
	local file_content = vim.fn.readfile(file_path)
	vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, file_content)

	local filetype = vim.fn.fnamemodify(file_path, ":e")
	vim.api.nvim_buf_set_option(preview_buf, "filetype", filetype)

	local win_id =
		vim.api.nvim_open_win(preview_buf, true, { relative = "editor", width = 80, height = 24, row = 1, col = 1 })

	vim.api.nvim_command("split")
	local message_win_id = vim.api.nvim_get_current_win()

	local message_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(message_win_id, message_buf)

	vim.api.nvim_buf_set_lines(
		message_buf,
		0,
		-1,
		false,
		{ "Press <C-y> to trust " .. file_path, "Press <C-n> to not trust " .. file_path }
	)

	vim.api.nvim_buf_set_keymap(preview_buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(
		preview_buf,
		"n",
		"<C-y>",
		':lua print("User trusts the file."); q<CR>',
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		preview_buf,
		"n",
		"<C-n>",
		':lua print("User does not trust the file."); q<CR>',
		{ noremap = true, silent = true }
	)
end

function M.load_json()
	local win_id = vim.api.nvim_get_current_win()
	if win_id == 0 then
		return nil
	end

	local buf_id = vim.api.nvim_win_get_buf(win_id)
	local file_path = vim.api.nvim_buf_get_name(buf_id)
	local file_dir = vim.fn.fnamemodify(file_path, ":h")
	local root_dir = "/"
	while file_dir ~= root_dir do
		local json_path = file_dir .. "/coderun.json"
		local file = io.open(json_path, "r")

		if file then
			local content = file:read("*all")
			file:close()

			local success, data = pcall(vim.fn.json_decode, content)
			if success then
				M.coderun_json_dir = json_path
				return data
			else
				print("Invalid coderun.json. Defaulting to default bindings.")
				return nil
			end
		end

		local parent_dir = vim.fn.fnamemodify(file_dir, ":h")
		if parent_dir == file_dir then
			M.coderun_json_dir = nil
			break
		end
		file_dir = parent_dir
	end

	return nil
end

function M.trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function M.run_command(command)
	if M.running_command then
		return
	end
	M.running_command = true
	local values = {}

	for cmd in string.gmatch(command, "([^&&]+)") do
		cmd = M.trim(cmd)
		for var in string.gmatch(cmd, "`%${(.-)}%`") do
			if not values[var] then
				local value = vim.fn.input("Enter value for " .. var .. ": ")
				if value == "" then
					M.running_command = false
					return
				end
				values[var] = value
			end
			cmd = cmd:gsub("`%${" .. var .. "}%`", values[var])
		end
		if cmd:sub(1, 1) == ":" then
			vim.api.nvim_command(cmd)
		else
			if M.toggle_term_command == "ToggleSkyTerm" then
				vim.api.nvim_command("SendToSkyTerm " .. cmd)
			else
				vim.api.nvim_command("TermExec cmd='" .. cmd .. "'")
			end
		end
	end
	M.running_command = false
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
	nim = "nim compile --run $dir/$fileName",
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
	nim = { "nim" },
}

function M.generate_commands_table(file_extension)
	local commands_table = {}
	for language, extensions in pairs(M.extensions) do
		for _, extension in ipairs(extensions) do
			if extension == file_extension then
				commands_table["run " .. language .. " project"] = {
					command = M.commands[language],
					keybind = M.opts.keymap,
				}
			end
		end
	end
	return commands_table
end

function M.setup(opts)
	M.opts = opts or {}
	M.opts.keymap = M.opts.keymap or "<F5>"

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
	end

	M.opts.interrupt_keymap = M.opts.interrupt_keymap or "<F2>"
	local modes = { "n", "i", "v", "t" }
	for _, mode in ipairs(modes) do
		vim.api.nvim_set_keymap(
			mode,
			M.opts.interrupt_keymap,
			"<Cmd>lua require('code-runner').send_interrupt()<CR>",
			{ noremap = true, silent = true }
		)
	end

	local sky_term_module = pcall(require, "sky-term")

	if sky_term_module then
		M.toggle_term_command = "ToggleSkyTerm"
	else
		M.toggle_term_command = "ToggleTerm"
	end

	-- Defer the loading of JSON and binding of commands
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			M.initialize()
		end,
	})

	vim.api.nvim_exec(
		[[
        augroup CodeRunner
            autocmd!
            autocmd BufEnter * lua require('code-runner').handle_buffer_enter()
            autocmd BufLeave * lua require('code-runner').handle_buffer_exit()
        augroup END
    ]],
		false
	)
end
function M.initialize()
	M.coderun_json = M.load_json()
	if M.coderun_json then
		M.bind_commands(M.coderun_json)
	else
		local file_extension = vim.fn.expand("%:e")
		M.coderun_json = M.generate_commands_table(file_extension)
		M.bind_commands(M.coderun_json)
	end
	vim.notify("toggle_term_command: " .. M.toggle_term_command)
end

-- function M.handle_buffer_enter()
--     local buf_id = vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win())

--     local buftype = vim.api.nvim_buf_get_option(buf_id, 'buftype')
--     if buftype ~= 'terminal' and (buftype == 'nofile' or buftype == '') then
--         M.coderun_json = M.load_json()
--         M.json_data = M.load_json()

--         if (M.coderun_json) then
--             M.bind_commands(M.coderun_json)
--         else
--             M.coderun_json = M.generate_commands_table(vim.fn.expand("%:e"))
--             M.bind_commands(M.coderun_json)
--         end
--     end
-- end
-- function M.handle_buffer_exit()
--     local buf_id = vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win())

--     local buftype = vim.api.nvim_buf_get_option(buf_id, 'buftype')
--     if (buftype == 'nofile' or buftype == "") and buftype ~= "terminal" then
--         if M.coderun_json then
--             M.unbind_commands(M.coderun_json)
--         else
--             local file_extension = vim.fn.expand("%:e")
--             M.unbind_commands(M.generate_commands_table(file_extension))
--         end
--     end
-- end
function M.handle_buffer_enter()
	local buf_id = vim.api.nvim_get_current_buf()
	-- local buftype = vim.api.nvim_buf_get_option(buf_id, "buftype")

	-- local buftype = vim.api.nvim_buf_get_option(0, "buftype")
	--

	local buftype = tostring(vim.bo.buftype)
	print("entering buff type is " .. vim.bo.buftype)
	-- Load and bind commands for non-terminal buffers
	-- if buftype ~= 'terminal' then
	if buftype ~= "terminal" and (buftype == "nofile" or buftype == "") then
		M.coderun_json = M.load_json()
		if M.coderun_json then
			M.bind_commands(M.coderun_json)
		else
			local file_extension = vim.fn.expand("%:e")
			M.coderun_json = M.generate_commands_table(file_extension)
			M.bind_commands(M.coderun_json)
		end
	end
end

function M.handle_buffer_exit()
	local buf_id = vim.api.nvim_get_current_buf()
	-- local buftype = vim.api.nvim_buf_get_option(buf_id, "buftype")
	-- local buftype = vim.api.nvim_buf_get_option(0, "buftype")
	local buftype = tostring(vim.bo.buftype)
	print("exiting buff type is  " .. vim.bo.buftype)
	-- Unbind commands only when leaving non-terminal buffers
	-- if buftype ~= 'terminal' then
	if buftype == "" then
		if M.coderun_json then
			M.unbind_commands(M.coderun_json)
		else
			local file_extension = vim.fn.expand("%:e")
			M.unbind_commands(M.generate_commands_table(file_extension))
		end
	end
end

return M
