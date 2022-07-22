# lsp_lines.nvim

`lsp_lines` is a simple neovim plugin that renders diagnostics using virtual
lines on top of the real line of code.

![A screenshot of the plugin in action](screenshot.png)

Font is [Fira Code][font], a classic.
Theme is [tokyonight.nvim][theme].

[font]: https://github.com/tonsky/FiraCode
[theme]: https://github.com/folke/tokyonight.nvim

# Background

LSPs provide lots of useful diagnostics for code (typically: errors, warnings,
linting). By default they're displayed using virtual text at the end of the
line which is in many cases good enough, but often there's more than one
diagnostic per line. It's also quite common to have more than one diagnostic
per line, but again, there's no handy way to read the whole thing.

`lsp_lines` solves this issue.

# Development

Patches welcome. Reports bugs via the bug tracker or [public inbox][list]. This
works well in its current state. Please report any issues you may find.

[list]: https://lists.sr.ht/~whynothugo/public-inbox

I've considered using the normal virtual text for all diagnostics and only
using virtual lines for the currently focused line, but that requires some
extra work I haven't had the time for.

# Installation

Using packer.nvim (this should probably be registered _after_ `lspconfig`):

```lua
use({
  "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
  config = function()
    require("lsp_lines").setup()
  end,
})
```

You can algo just clone the repo into neovim's plug-in directory:

    mkdir -p $HOME/.local/share/nvim/site/pack/plugins/start/
    cd $HOME/.local/share/nvim/site/pack/plugins/start/
    git clone git@git.sr.ht:~whynothugo/lsp_lines.nvim

And then in `init.lua`:

    require("lsp_lines").setup()

It's recommended to also remove the regular virtual text diagnostics to avoid
pointless duplication:

```lua
-- Disable virtual_text since it's redundant due to lsp_lines.
vim.diagnostic.config({
  virtual_text = false,
})
```

# Configuration

This plugin's functionality can be disabled with:

```lua
vim.diagnostic.config({ virtual_lines = false })
```

And it can be re-enabled via:

```lua
vim.diagnostic.config({ virtual_lines = true })
```

The prefix icon shown to the left of diagnostics can be configured with:

```lua
vim.diagnostic.config({ virtual_lines = { prefix = "🔥" } })
```

# Contributing

- Discussion or patches: ~whynothugo/lsp_lines.nvim@lists.sr.ht
- Issues: https://todo.sr.ht/~whynothugo/lsp_lines.nvim
- Tips: https://ko-fi.com/whynothugo

# Licence

This project is licensed under the ISC licence. See LICENCE for more details.
