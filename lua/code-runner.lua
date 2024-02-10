-- local M = {}

-- -- Default commands
-- -- M.commands = {
-- --     py = 'python -u %s',
-- --     -- todo more commands
-- -- }

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

--     -- Overwrite the default commands with the user-provided commands
--     if M.opts.commands then
--         for k, v in pairs(M.opts.commands) do
--             M.commands[k] = v
--         end
--     end

--     if M.opts.run_tmux ~= false then
--         vim.cmd("TermExec cmd='tmux new-session -A -s nvim'")
--         vim.cmd("ToggleTerm")
--     end

--     -- Set the keymap
--     vim.api.nvim_set_keymap('n', M.opts.keymap, ':lua require("code-runner").run_code()<CR>',
--         { noremap = true, silent = true })
-- end

-- -- function M.run_code()
-- --     print("Starting")
-- --     local file_path = vim.fn.expand("%:p")
-- --     local file_extension = vim.fn.fnamemodify(file_path, ":e")

-- --     local cmd = M.commands[file_extension]

-- --     if cmd then
-- --         cmd = string.format(cmd, file_path)
-- --         print("Running command: " .. cmd)
-- --         vim.cmd("execute 'TermExec cmd=\"" .. cmd .. "\"'")
-- --     else
-- --         print("Error: Could not construct command for file extension " .. file_extension)
-- --     end
-- -- end

-- -- function M.run_code()
-- --     print("Starting")
-- --     local file_path = vim.fn.expand("%:p")
-- --     local file_dir = vim.fn.expand("%:p:h")
-- --     local file_name = vim.fn.expand("%:t")
-- --     local file_name_without_ext = vim.fn.expand("%:r:t")
-- --     local file_extension = vim.fn.fnamemodify(file_path, ":e")

-- --     local cmd = M.commands[file_extension]

-- --     if cmd then
-- --         cmd = cmd:gsub("$dir", file_dir)
-- --         cmd = cmd:gsub("$fileName", file_name)
-- --         cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
-- --         print("Running command: " .. cmd)
-- --         vim.cmd("execute 'TermExec cmd=\"" .. cmd .. "\"'")
-- --     else
-- --         print("Error: Could not construct command for file extension " .. file_extension)
-- --     end
-- -- end

-- function M.run_code()
--     print("Starting")
--     local file_path = vim.fn.expand("%:p")
--     local file_dir = vim.fn.expand("%:p:h")
--     local file_name = vim.fn.expand("%:t")
--     local file_name_without_ext = vim.fn.expand("%:r:t")
--     local file_extension = vim.fn.fnamemodify(file_path, ":e")

--     local language = M.extensions[file_extension]
--     local cmd = M.commands[language]

--     if cmd then
--         cmd = cmd:gsub("$dir", file_dir)
--         cmd = cmd:gsub("$fileName", file_name)
--         cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
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

function M.setup(opts)
    M.opts = opts or {}
    M.opts.keymap = M.opts.keymap or '<F5>'

    -- Overwrite the default commands with the user-provided commands
    if M.opts.commands then
        for k, v in pairs(M.opts.commands) do
            M.commands[k] = v
        end
    end

    -- Overwrite the default extensions with the user-provided extensions
    if M.opts.extensions then
        for k, v in pairs(M.opts.extensions) do
            M.extensions[k] = v
        end
    end

    if M.opts.run_tmux ~= false then
        vim.cmd("TermExec cmd='tmux new-session -A -s nvim'")
        vim.cmd("ToggleTerm")
    end

    -- Set the keymap
    vim.api.nvim_set_keymap('n', M.opts.keymap, ':lua require("code-runner").run_code()<CR>',
        { noremap = true, silent = true })
end

function M.run_code()
    print("Starting")
    local file_path = vim.fn.expand("%:p")
    local file_dir = vim.fn.expand("%:p:h")
    local file_name = vim.fn.expand("%:t")
    local file_name_without_ext = vim.fn.expand("%:r:t")
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
