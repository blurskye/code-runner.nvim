<head>
<div align="center">
<img src="https://raw.githubusercontent.com/blurskye/code-runner.nvim/main/banner.png">

<h4> "all that is necessary for evil to triumph is for good man to do nothing", do something, anything </h4>
</head>


<body>
<h1> 🚀 Code Runner for Neovim 🚀 </h1>

</div>


https://github.com/blurskye/code-runner.nvim/assets/145671529/cf42120c-6b99-4cbe-a97e-953736591721


This is a Neovim plugin that allows you to run code in various languages directly from your editor. It supports a wide range of languages out of the box and can be easily extended to support more.

## 📦 Installation

You can install this plugin with your favorite plugin manager. Here's an example using `lazy.nvim`:

### For lazy.nvim use

```lua
{
  {
    "blurskye/code-runner.nvim",
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
for beginners

After you've set up the plugin, you can run your code by pressing the keymap you've set in the configuration (default is `<F5>`). The plugin will run the appropriate command for the language of the current file.
but for people who need a bit more juice out of the plugin

- it is multi modal
- - it searchs in the script dir for a coderun.json file, expects it to be in the following format 
```json
{
  "run the project"{
    "command":"npm run start",
    "keybind": "<F5>"
  },
  "deploy the project":{
    "command" : "npm run deploy",
    "keybind":"<F6>"
  }
  -- $dir uses the coderun.json's directory and rest of the coderun variables are the same as the currently open script
}
```
- - However if a coderun.json is not found, it will defualt to language default to run the code, in which case it can be the ones passed in setup function(it overwrites the ones set by default in app)



<div align="center">

## 🚀 Ready to launch your code directly from Neovim? Install Code Runner now! 🚀
### ⚠️it is advisable to learn how to use tmux and configure tmux to your likeing and to enable run_tmux, however by default this plugin wont use tmux⚠️


</div>
</body>

<h1 align="center"> 🌟 We Love Your Contributions! 🌟 </h1>
<p align="center>
Got an idea to make this plugin even better? We'd love to hear it! 📣

- **Feature Enhancements**: If you have a suggestion, don't hesitate to open an issue. We're always looking for ways to improve! 💡
- **Pull Requests**: Ready to roll up your sleeves and make a change yourself? Submit a pull request! We appreciate your initiative. 🛠️

Thank you for using this plugin and being a part of our community. Your support means the world to us! 🌍💖
</p>
