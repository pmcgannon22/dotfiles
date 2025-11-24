set nocompatible
syntax on     
filetype plugin indent on
set encoding=utf-8  

set number                     " Show line numbers
set relativenumber            " Show relative line numbers
set ruler                     " Show cursor position
set showcmd                   " Show incomplete commands
set cursorline                " Highlight current line

set tabstop=4                 " Tab width
set shiftwidth=4              " Indent width
set expandtab                 " Use spaces instead of tabs
set autoindent                " Copy indent from current line
set smartindent               " Smart autoindenting

set incsearch                 " Incremental search
set hlsearch                  " Highlight search results
set ignorecase                " Case-insensitive search
set smartcase                 " Case-sensitive if uppercase present

set mouse=a                   " Enable mouse support
set clipboard=unnamed,unnamedplus " Use system clipboard (cross-platform)
set backspace=indent,eol,start " Make backspace work normally
set wildmenu                  " Visual autocomplete for command menu
set laststatus=2              " Always show status line

set noswapfile               " Disable swap files
set nobackup                 " Disable backup files
set undofile                 " Enable persistent undo
set undodir=~/.vim/undodir   " Set undo directory
set lazyredraw               " Redraw only when needed

" --------------
" Key Remappings
" --------------
let mapleader = " "  " <leader> = <space>

" Quick save = <space>w
nnoremap <leader>w :w<CR>

" Quick save and quit = <space>q
nnoremap <leader>q :wq<CR>

" Quit without saving = <space>x
nnoremap <leader>x :q!<CR>

" Move to beginning/end of line more easily
nnoremap H ^ " shift-H = start of line
nnoremap L $ " shift-L = end of line
onoremap H ^ " Works with operators (d, y, c, etc.)
onoremap L $

" Cycle through buffers
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>

" Yank to end of line (consistent with C and D)
nnoremap Y y$

" Search and replace word under cursor
nnoremap <leader>r :%s/\<<C-r><C-w>\>//g<Left><Left>

" Clear search highlighting
nnoremap <leader><leader> :nohl<CR>

" Search for visually selected text
" // for search selected text
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR> 

" jj = ESC to go to normal mode
inoremap jj <Esc>

" ------------
" Split Window
" ------------

" Split window vertically
nnoremap <leader>v :vsplit<CR>

" Split window horizontally  
nnoremap <leader>h :split<CR>

" Resize splits more easily
nnoremap <leader>+ :vertical resize +5<CR>
nnoremap <leader>- :vertical resize -5<CR>

" Move to matching bracket
nnoremap <leader>m %

" Center screen on search results
nnoremap n nzzzv
nnoremap N Nzzzv

" ------------------
" Other productivity
" ------------------

" Open file explorer
nnoremap <leader>e :Explore<CR>

" Format entire file
nnoremap <leader>f ggVG=

" Sort selection
vnoremap <leader>s :sort<CR>

