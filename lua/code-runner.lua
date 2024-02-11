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

function M.find_coderun_file(dir)
    local file_path = dir .. "/coderun.json"
    if vim.fn.filereadable(file_path) == 1 then
        return file_path
    elseif dir == "/" then
        return nil
    else
        return M.find_coderun_file(vim.fn.fnamemodify(dir, ":h"))
    end
end

function M.run_code()
    local file_name = vim.fn.expand("%:t")
    local file_dir = vim.fn.expand("%:p:h")
    local file_name_without_ext = vim.fn.fnamemodify(file_name, ":r")

    local coderun_file = M.find_coderun_file(file_dir)
    if coderun_file then
        local file = io.open(coderun_file, "r")
        local content = file:read("*all")
        file:close()
        local coderun = vim.fn.json_decode(content)
        local task = coderun["run the project"]
        if task then
            local cmd = task["command"]
            cmd = cmd:gsub("$dir", file_dir)
            cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
            cmd = cmd:gsub("$fileName", file_name)
            print("Running command: " .. cmd)
            vim.cmd("execute 'TermExec cmd=\"" .. cmd .. "\"'")
            return
        end
    end

    local file_ext = vim.fn.expand("%:e")
    for lang, exts in pairs(M.extensions) do
        for _, ext in ipairs(exts) do
            if ext == file_ext then
                local cmd = M.commands[lang]
                cmd = cmd:gsub("$dir", file_dir)
                cmd = cmd:gsub("$fileNameWithoutExt", file_name_without_ext)
                cmd = cmd:gsub("$fileName", file_name)
                print("Running command: " .. cmd)
                vim.cmd("execute 'TermExec cmd=\"" .. cmd .. "\"'")
                return
            end
        end
    end

    print("No command found for this file type")
end

return M
