# Code Runner for Neovim

This is a Neovim plugin that allows you to run code in various languages directly from your editor. It supports a wide range of languages out of the box and can be easily extended to support more.

## Installation

You can install this plugin with your favorite plugin manager. Here's an example using `lazy.nvim`:
## for lazy.nvim use
```lua
{
  {
    "blueskye/code-runner.nvim",
    dependencies = {
      "akinsho/toggleterm.nvim",
    },
    config = function()
      require('code-runner').setup({
        -- configuration options
      })
    end,
  },
}
```


## Configuration

You can configure this plugin by calling the `setup` function. Here's an example configuration with all available options:

```lua
require('code-runner').setup({
  keymap = '<F5>', -- Keymap to run the code. Default is '<F5>'.
  -- it has a lot of language run commands by default, can add or overwrite them as needed like this
  commands = { -- Custom commands for languages.
    python = "python3 -u $dir/$fileName",
  },
  extensions = { -- File extensions for languages.
    python = { "py" },

  },
  run_tmux = true, -- If true, runs 'tmux new-session -A -s nvim' and 'ToggleTerm'. Default is false.
})
```

In the `commands` and `extensions` tables, you can overwrite the default commands and extensions for each language. The `$dir`, `$fileName`, and `$fileNameWithoutExt` placeholders in the commands will be replaced with the directory, file name, and file name without extension of the current file, respectively.

If `run_tmux` is set to `true`, the plugin will run `tmux new-session -A -s nvim` and `ToggleTerm` when the `setup` function is called. This can be useful if you want to run your code in a tmux session.

## Usage

After you've set up the plugin, you can run your code by pressing the keymap you've set in the configuration (default is `<F5>`). The plugin will run the appropriate command for the language of the current file.

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is licensed under the MIT License. See the LICENSE file for details.