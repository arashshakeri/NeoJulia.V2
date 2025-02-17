" ~/.config/nvim/init.vim

" Install vim-plug if not present
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
" Essential
Plug 'folke/tokyonight.nvim'                " Theme
Plug 'nvim-lualine/lualine.nvim'           " Status line
Plug 'nvim-tree/nvim-web-devicons'         " Icons
Plug 'akinsho/toggleterm.nvim'             " Terminal handling
Plug 'neovim/nvim-lspconfig'               " LSP
Plug 'JuliaEditorSupport/julia-vim'        " Julia support
" File explorer
Plug 'nvim-tree/nvim-tree.lua'
Plug 'onsails/lspkind-nvim'
Plug 'windwp/nvim-autopairs'
Plug 'rafamadriz/friendly-snippets'
" Variables/Environment viewer
Plug 'stevearc/dressing.nvim'              " UI improvements
Plug 'rcarriga/nvim-notify'                " Notifications

Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'

" LSP and completion
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
call plug#end()

" Basic Settings
set number
set relativenumber
set autoindent
set expandtab
set tabstop=4
set shiftwidth=4
set clipboard=unnamed
set termguicolors
set splitright
set splitbelow

" Theme
colorscheme tokyonight-night

" Key Mappings
let mapleader = " "

" Window Navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" File Explorer
nnoremap <C-n> :NvimTreeToggle<CR>

" Cell Navigation
nnoremap [c :call search('^#%%', 'bW')<CR>
nnoremap ]c :call search('^#%%', 'W')<CR>

" Workspace toggle
nnoremap <leader>w :lua toggle_workspace()<CR>

" Load Lua Config
lua require('init')

" Auto-open REPL and workspace on Julia files
augroup JuliaSetup
    autocmd!
    autocmd FileType julia lua setup_julia_environment()
augroup END
