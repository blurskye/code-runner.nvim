<div align="center">

### Stand Up For Humanity, Oppose Genocide and Suppression
### Condemn 75 years of Brutal Occupation and Genocide
### <span style="color:green">Support PALESTINE![Animated Emoji](https://path-to-your-gif.com/animated-emoji.gif)</span>

</div>
<div align="center">

# 🚀 Code Runner for Neovim 🚀

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
})
```

<div align="center">

## 🚀 Ready to launch your code directly from Neovim? Install Code Runner now! 🚀

</div>
