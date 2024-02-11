-- local M = {}

-- M.commands = {
--     java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
--     python = "python3 -u $dir/$fileName",
--     typescript = "deno run $dir/$fileName",
--     rust = "cd $dir && rustc $fileName && $dir/$fileNameWithoutExt",
--     c = "cd $dir && gcc $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt",
--     cpp = "cd $dir && g++ $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt",
--     javascript = "node $dir/$fileName",
--     php = "php $dir/$fileName",
--     ruby = "ruby $dir/$fileName",
--     go = "go run $dir/$fileName",
--     perl = "perl $dir/$fileName",
--     bash = "bash $dir/$fileName",
--     lisp = "sbcl --script $dir/$fileName",
--     fortran = "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt",
--     haskell = "runhaskell $dir/$fileName",
--     dart = "dart run $dir/$fileName",
--     pascal = "cd $dir && fpc $fileName && $dir/$fileNameWithoutExt",
--     nim = "nim compile --run $dir/$fileName"
-- }

-- M.extensions = {
--     python = { "py" },
--     java = { "java" },
--     typescript = { "ts" },
--     rust = { "rs" },
--     c = { "c" },
--     cpp = { "cpp", "cxx", "hpp", "hxx" },
--     javascript = { "js" },
--     php = { "php" },
--     ruby = { "rb" },
--     go = { "go" },
--     perl = { "pl" },
--     bash = { "sh" },
--     lisp = { "lisp" },
--     fortran = { "f", "f90" },
--     haskell = { "hs" },
--     dart = { "dart" },
--     pascal = { "pas" },
--     nim = { "nim" }
-- }

-- function M.setup(opts)
--     M.opts = opts or {}
--     M.opts.keymap = M.opts.keymap or '<F5>'

--     -- Overwrite the default commands and extensions with the user-provided commands
--     if M.opts.commands then
--         for k, v in pairs(M.opts.commands) do
--             M.commands[k] = v
--         end
--     end
--     if M.opts.extensions then
--         for k, v in pairs(M.opts.extensions) do
--             M.extensions[k] = v
--         end
--     end

--     -- if M.opts.run_tmux ~= false then
--     --     vim.cmd("TermExec cmd='tmux new-session -A -s nvim'")
--     --     vim.cmd("ToggleTerm")
--     -- end
--     if M.opts.run_tmux == true then
--         vim.cmd("TermExec cmd='tmux new-session -A -s nvim'")
--         vim.cmd("ToggleTerm")
--     end

--     -- Set the keymap
--     vim.api.nvim_set_keymap('n', M.opts.keymap, ':lua require("code-runner").run_code()<CR>',
--         { noremap = true, silent = true })
-- end

-- function M.run_code()
--     print("Starting")
--     -- Get the current window's buffer number
--     local bufnr = vim.api.nvim_win_get_buf(0)
--     -- Check if the current window contains a terminal, if so then run the code in the window above
--     if vim.api.nvim_buf_get_option(bufnr, "buftype") == "terminal" then
--         local wins = vim.api.nvim_tabpage_list_wins(0)
--         for i, win in ipairs(wins) do
--             if win == vim.api.nvim_get_current_win() and i > 1 then
--                 bufnr = vim.api.nvim_win_get_buf(wins[i - 1])
--                 break
--             end
--         end
--     end
--     local file_path = vim.api.nvim_buf_get_name(bufnr)
--     local file_dir = vim.fn.fnamemodify(file_path, ":h")
--     local file_name = vim.fn.fnamemodify(file_path, ":t")
--     local file_name_without_ext = vim.fn.fnamemodify(file_path, ":r:t")
--     local file_extension = vim.fn.fnamemodify(file_path, ":e")

--     local language
--     for lang, exts in pairs(M.extensions) do
--         for _, ext in ipairs(exts) do
--             if ext == file_extension then
--                 language = lang
--                 break
--             end
--         end
--         if language then break end
--     end

--     local cmd = M.commands[language]

--     if cmd then
--         cmd = cmd:gsub("$dir", file_dir)
--         cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
--         cmd = cmd:gsub("$fileName", file_name)
--         print("Running command: " .. cmd)
--         vim.cmd("execute 'TermExec cmd=\"" .. cmd .. "\"'")
--     else
--         print("Error: Could not construct command for language " .. (language or file_extension))
--     end
-- end

-- return M
local M = {}

M.commands = {
    java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
    python = "python3 -u $dir/$fileName",
    typescript = "deno run $dir/$fileName",
    rust = "cd $dir && rustc $fileName && $dir/$fileNameWithoutExt",
    c = "cd $dir && gcc $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt",
    cpp = "cd $dir && g++ $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt",
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

function M.find_coderun_json(dir)
    local f = io.open(dir .. "/coderun.json", "r")
    if f ~= nil then
        io.close(f)
        return dir .. "/coderun.json"
    elseif dir == "" then
        return nil
    else
        return M.find_coderun_json(vim.fn.fnamemodify(dir, ":h"))
    end
end

function M.setup(opts)
    M.opts = opts or {}
    M.opts.keymap = M.opts.keymap or '<F5>'

    local coderun_json_path = M.find_coderun_json(vim.fn.getcwd())
    if coderun_json_path ~= nil then
        local coderun_json = vim.fn.json_decode(vim.fn.readfile(coderun_json_path))
        for k, v in pairs(coderun_json) do
            if type(v) == "table" and v.command then
                M.commands[k] = v.command
                M.opts.keymap = v.keybind or M.opts.keymap
            end
        end
    else
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
    end

    if M.opts.run_tmux == true then
        vim.cmd("TermExec cmd='tmux new-session -A -s nvim'")
        vim.cmd("ToggleTerm")
    end

    vim.api.nvim_set_keymap('n', M.opts.keymap, ':lua require("code-runner").run_code()<CR>',
        { noremap = true, silent = true })
end

function M.run_code()
    print("Starting")
    local bufnr = vim.api.nvim_win_get_buf(0)
    if vim.api.nvim_buf_get_option(bufnr, "buftype") == "terminal" then
        local wins = vim.api.nvim_tabpage_list_wins(0)
        for i, win in ipairs(wins) do
            if win == vim.api.nvim_get_current_win() and i > 1 then
                bufnr = vim.api.nvim_win_get_buf(wins[i - 1])
                break
            end
        end
    end
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local file_dir = vim.fn.fnamemodify(file_path, ":h")
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local file_name_without_ext = vim.fn.fnamemodify(file_path, ":r:t")
    local file_extension = vim.fn.fnamemodify(file_path, ":e")

    local language
    for lang, exts in pairs(M.extensions) do
        for _, ext in ipairs(exts) do
            if ext == file_extension then
                language = lang
                break
            end
        end
        if language then break end
    end

    local cmd = M.commands[language]
    if cmd then
        cmd = cmd:gsub("$dir", file_dir)
        cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
        cmd = cmd:gsub("$fileName", file_name)
        print("Running command: " .. cmd)
        vim.cmd("execute 'TermExec cmd=\"" .. cmd .. "\"'")
    else
        print("Error: Could not construct command for language " .. (language or file_extension))
    end
end

return M
