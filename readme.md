<head>
<div align="center">
<img src="https://raw.githubusercontent.com/blurskye/code-runner.nvim/main/banner.png">

<!-- ### Stand Up For <span style="color:green"> Humanity </span>, Oppose <span style="color:red">Genocide</span> and <span style="color:red">Suppression</span>
### Condemn <span style="color:red">75 years </span> of <span style="color:red"> Brutal Occupation </span> and <span style="color:red"> Genocide </span>
### <span style="color:green">Support PALESTINE<img src="https://raw.githubusercontent.com/blurskye/code-runner.nvim/main/icon.png" alt="heart" style="vertical-align: middle; position: relative; top: -2px;"></span>
</div> -->
</head>
<div align="center">

<body>
<h1> 🚀 Code Runner for Neovim 🚀 </h1>

</div>

This is a Neovim plugin that allows you to run code in various languages directly from your editor. It supports a wide range of languages out of the box and can be easily extended to support more.

## 📦 Installation

You can install this plugin with your favorite plugin manager. Here's an example using `lazy.nvim`:

### For lazy.nvim use

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

## ⚙️ Configuration

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
  run_tmux = false, -- If true, runs 'tmux new-session -A -s nvim' and 'ToggleTerm'. Default is false.
})
```
## Usage

After you've set up the plugin, you can run your code by pressing the keymap you've set in the configuration (default is `<F5>`). The plugin will run the appropriate command for the language of the current file.

# Experimental Features
<details>
<summary>Click to expand!</summary>

- <details>
  <summary>Experimental Feature: Ability to have coderun.json</summary>

  ```json
  {
    "run project": {
      "command" : "npm run start",
      "keybind": "<F7>"
    },
    "deploy project": {
      "command": "npm run deploy",
      "keybind": "<F6>"
    }
  }
  ```
    This file can be in any directory above or in the same directory as the script. If it's not found, the default commands for each language will be used. These defaults can also be changed from the setup function. See above for more details.

  to use this experimental feature, you will have to use the branch alt-testing
  (will be merged in a few weeks of testing)
  like this
  
    ```lua
    {
      {
        "blueskye/code-runner.nvim",
        branch = "alt-testing",
        dependencies = {
          "akinsho/toggleterm.nvim",
        },
        config = function()
          require('code-runner').setup({
            -- configuration options
          })
        end,
      }
    }
    ```
</details>
</details>
<div align="center">

## 🚀 Ready to launch your code directly from Neovim? Install Code Runner now! 🚀
### ⚠️it is advisable to learn how to use tmux and configure tmux to your likeing and to enable run_tmux, however by default this plugin wont use tmux⚠️


</div>
</body>