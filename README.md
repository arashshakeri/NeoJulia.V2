# NeoJulia.v2

A Neovim configuration that provides an RStudio-inspired integrated development environment for Julia. This project aims to bring the intuitive workflow of RStudio to Neovim users working with Julia, combining the power of modal editing with interactive Julia development.

![Screenshot From 2025-02-18 02-03-02](https://github.com/user-attachments/assets/484a49a2-55c5-46db-996b-27a42b010a47)


## Features

- RStudio-inspired interface with:
  - Interactive Julia REPL in a horizontal split
  - Real-time workspace viewer showing variables and their values (similar to RStudio's Environment pane)
  - Code cell execution support (like RStudio's chunks)
- LSP integration for code completion and analysis
- Automatic workspace variable tracking
- Multiple code execution modes:
  - Current line (like RStudio's Ctrl+Enter)
  - Selection
  - Cell (similar to RStudio's chunk execution)
  - Entire file

## Prerequisites

- Neovim >= 0.9.0
- Julia >= 1.6
- Git
- A Nerd Font installed and configured in your terminal (for icons)

## Installation

### 1. Install System Dependencies

Choose your distribution:

```bash
# On Ubuntu/Debian
apt install neovim julia git

# On macOS
brew install neovim julia git

# On Arch Linux
pacman -S neovim julia git
```

### 2. Install Julia Language Server

Start Julia REPL and install the Language Server:
```julia
# Start Julia REPL
julia

# Press ']' to enter package mode
add LanguageServer
```

### 3. Install Required Neovim Plugins

Using your preferred package manager (example using Packer):

```lua
use {
    'nvim-tree/nvim-tree.lua',
    'nvim-lualine/lualine.nvim',
    'akinsho/toggleterm.nvim',
    'neovim/nvim-lspconfig',
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    'onsails/lspkind.nvim',
    'windwp/nvim-autopairs',
}
```

### 4. Configuration Setup

```bash
mkdir -p ~/.config/nvim/lua
cp init.lua ~/.config/nvim/lua/
```

## Keymappings

### Code Execution
| Key          | Mode    | Action                                    |
|--------------|---------|-------------------------------------------|
| `<F5>`       | Normal  | Execute entire file                       |
| `<F6>`       | Normal  | Execute current line                      |
| `<F7>`       | Normal  | Execute current cell (bounded by `#%%`)   |
| `<F8>`       | Visual  | Execute selected code                     |

### Terminal Navigation
| Key          | Mode      | Action                                  |
|--------------|-----------|------------------------------------------|
| `<C-h>`      | Terminal  | Move to left window                     |
| `<C-j>`      | Terminal  | Move to bottom window                   |
| `<C-k>`      | Terminal  | Move to top window                      |
| `<C-l>`      | Terminal  | Move to right window                    |
| `<C-\><C-n>` | Terminal  | Exit terminal mode (return to normal)   |

### LSP Navigation
| Key          | Mode    | Action                                    |
|--------------|---------|-------------------------------------------|
| `gd`         | Normal  | Go to definition                          |
| `gr`         | Normal  | Show references                           |
| `K`          | Normal  | Show hover documentation                  |
| `<leader>rn` | Normal  | Rename symbol                            |
| `[d`         | Normal  | Go to previous diagnostic                 |
| `]d`         | Normal  | Go to next diagnostic                    |

### Code Completion
| Key           | Mode    | Action                                   |
|---------------|---------|------------------------------------------|
| `<C-Space>`   | Insert  | Trigger completion                       |
| `<C-b>`       | Insert  | Scroll docs backwards                    |
| `<C-f>`       | Insert  | Scroll docs forwards                     |
| `<C-e>`       | Insert  | Close completion window                  |
| `<CR>`        | Insert  | Confirm completion                       |
| `<Tab>`       | Insert  | Next completion item                     |
| `<S-Tab>`     | Insert  | Previous completion item                 |

### Workspace Management
| Key            | Mode    | Action                                  |
|----------------|---------|------------------------------------------|
| `<leader>w`    | Normal  | Toggle workspace viewer                  |
| `<leader>r`    | Normal  | Refresh workspace view                   |

## Detailed Usage Guide

### Starting a Session

1. Open a Julia file in Neovim:
   ```bash
   nvim myfile.jl
   ```

2. The Julia REPL will automatically open in a horizontal split when you first execute code.

### Code Execution

#### Using Code Cells
Similar to RStudio's chunks, cells are defined using `#%%` markers:

```julia
#%%
# Data Import
using CSV
data = CSV.read("mydata.csv", DataFrame)

#%%
# Data Analysis
describe(data)
```

- Move cursor inside a cell
- Press `<F7>` to execute the entire cell

#### Line-by-Line Execution
- Position cursor on a line
- Press `<F6>` to execute (similar to RStudio's Ctrl+Enter)

#### Visual Selection
- Select code in visual mode (`v`)
- Press `<F8>` to execute selection

#### Full File Execution
- Press `<F5>` to run the entire file

### Workspace Viewer

Toggle the workspace viewer to see your variables:
- Shows all variables in your Julia session
- Updates in real-time as you execute code
- Displays:
  - Variable names
  - Types (like RStudio's environment pane)
  - Preview of values (truncated for readability)

## Project Structure

```
~/.config/nvim/
├── lua/
│   └── init.lua          # Main configuration file
└── workspace.json        # Auto-generated workspace data
```

## Customization

### Terminal Appearance
```lua
-- In init.lua, modify create_julia_terminal():
julia = Terminal:new({
    direction = "horizontal",  -- Change to "vertical" for side split
    size = 11,                -- Adjust terminal height
    -- Add additional toggleterm.nvim options
})
```

### Workspace Viewer
```lua
-- Adjust workspace viewer width
vim.api.nvim_win_set_width(workspace_win, 85)  -- Change 85 to desired width

-- Modify excluded variables in Julia export_workspace()
excluded_names = Set([
    "eval",
    "export_workspace",
    "minimal_print",
    "include"
    -- Add your exclusions here
])
```

### Custom Keymapping Configuration

You can customize these keymappings by modifying your `init.lua`. Here's how to change them:

```lua
-- Example: Change F5 to F9 for full file execution
vim.keymap.set("n", "<F9>", function()
    send_to_julia(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
end, { buffer = true })

-- Example: Change workspace toggle to different key
vim.keymap.set("n", "<leader>ws", function()
    toggle_workspace()
end, { noremap = true, silent = true })
```

## Troubleshooting

### Common Issues

1. Workspace viewer not updating:
   - Check directory permissions
   - Verify workspace.json creation
   - Look for Julia error messages in REPL

2. LSP features not working:
   - Run `:LspInfo` to check server status
   - Verify LanguageServer.jl installation
   - Check :checkhealth output

3. REPL issues:
   - Confirm Julia in PATH: `which julia`
   - Check toggleterm.nvim installation
   - Verify terminal settings in init.lua

### Debug Mode

Add to init.lua for additional logging:
```lua
vim.lsp.set_log_level("debug")
require('toggleterm').setup({
    on_stderr = function(_, job, err)
        vim.api.nvim_err_writeln(err)
    end,
})
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a Pull Request

## Acknowledgments

- Inspired by RStudio's intuitive interface and workflow
- Built on the excellent Neovim ecosystem
- Thanks to the Julia community for LanguageServer.jl

## License

This project is licensed under the MIT License - see the LICENSE file for details.
