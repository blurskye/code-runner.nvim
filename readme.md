# 🚀 code-runner.nvim

A fast, flexible code runner for Neovim. Run code in 20+ languages with a single keypress, or define project-specific commands via `coderun.json`.

https://github.com/blurskye/code-runner.nvim/assets/145671529/cf42120c-6b99-4cbe-a97e-953736591721

## ✨ Features

- **20+ languages** supported out of the box
- **Project-specific commands** via `coderun.json`
- **Security-first**: prompts before executing untrusted configs
- **Multiple terminal backends**: toggleterm, sky-term, or built-in
- **File watching**: auto-reloads when `coderun.json` changes
- **Custom keybinds** per project

## 📦 Installation

### lazy.nvim

```lua
{
    "blurskye/code-runner.nvim",
    dependencies = {
        "MunifTanjim/nui.nvim", -- optional, for better prompts
        "akinsho/toggleterm.nvim", -- optional, for terminal
    },
    config = function()
        require("code-runner").setup()
    end,
}
```

### packer.nvim

```lua
use {
    "blurskye/code-runner.nvim",
    requires = {
        "MunifTanjim/nui.nvim",
        "akinsho/toggleterm.nvim",
    },
    config = function()
        require("code-runner").setup()
    end,
}
```

## ⚙️ Configuration

```lua
require("code-runner").setup({
    keymap = "<F5>",           -- Run code
    interrupt_keymap = "<F2>", -- Stop execution
    debug = false,             -- Enable debug logging

    -- Override or add language commands
    commands = {
        python = 'python3 -u "$dir/$fileName"',
        javascript = 'node "$dir/$fileName"',
        -- Add your own...
    },

    -- Map file extensions to languages
    extensions = {
        python = { "py", "pyw" },
        javascript = { "js", "mjs" },
        -- Add your own...
    },
})
```

### Supported Languages

Python, JavaScript, TypeScript, Lua, Ruby, Go, C, C++, Java, Bash, Rust, PHP, Perl, Zig, Kotlin, Swift, R, Julia, Elixir, Haskell, Scala, Dart

## 📁 Project Configuration

Create a `coderun.json` in your project root for custom commands:

```json
{
    "run": {
        "command": "npm run dev",
        "keybind": "<F5>"
    },
    "test": {
        "command": "npm test",
        "keybind": "<F6>"
    },
    "build": {
        "command": "npm run build",
        "keybind": "<F7>"
    }
}
```

### Variables

| Variable | Description |
|----------|-------------|
| `$filePath` | Full path to current file |
| `$fileName` | Current file name with extension |
| `$fileNameWithoutExt` | Current file name without extension |
| `$fileExtension` | Current file extension |
| `$dir` | Directory of current file |
| `$coderunDir` | Directory containing `coderun.json` |

## 🔧 Commands

| Command | Description |
|---------|-------------|
| `:CodeRunnerRun` | Run current file |
| `:CodeRunnerInterrupt` | Stop running code |
| `:CodeRunnerReload` | Reload configuration |
| `:CodeRunnerDebug` | Toggle debug mode |

## 🔒 Security

When a `coderun.json` is detected, you'll be prompted to review and accept it before any commands are executed. The plugin remembers your choice (per file hash) until the config changes.

## 📄 License

MIT

## 🤝 Contributing

Issues and PRs welcome!
