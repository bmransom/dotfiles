"""""""""""""""""""""""""
" General
"""""""""""""""""""""""""

" Sets how many lines of history VIM remembers
set history=500

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread

" Fast saving
nmap <leader>w :w!<cr>

" No annoying sounds on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500
set belloff=all

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" Enable mouse
set mouse=a

"""""""""""""""""""""""""
" Buffers and Windows
"""""""""""""""""""""""""

" Navigate between splits easily
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Open new split planes to the right and below
set splitbelow
set splitright

"""""""""""""""""""""""""
" VIM User Interface
"""""""""""""""""""""""""

" Always show current position
set ruler

" Show relative line numbers
set relativenumber

" Show line number that we're on
set number

" Make it so there are always ten lines below my cursor
set scrolloff=10

" Height of the command bar
set cmdheight=2

" Configure backspace so it acts as expected
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" Try to be smart about cases when searching
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance)
set lazyredraw

" For regular expressions, turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch

" Enable syntax highlighting
syntax enable

" Transparent background... for some reason, this has to be after syntax enable
highlight Normal ctermbg=NONE

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Remove built-in vim status ( -- INSERT -- etc )
set noshowmode

"""""""""""""""""""""""""""""""""""""""""""""
" Files, backups, and undo
"""""""""""""""""""""""""""""""""""""""""""""

" Turn backup files off
set nobackup
set nowb
set noswapfile

"""""""""""""""""""""""""""""""""""""""""""""
" Text, tab, and indent related
"""""""""""""""""""""""""""""""""""""""""""""

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs
set smarttab

" 1 tab == 2 spaces
set shiftwidth=2
set tabstop=2
set softtabstop=2

" Linebreak on 500 characters
set lbr
set tw=500

set autoindent
set copyindent " copy indent from the previous line
set si " Smart indent
set wrap " Wrap lines

" Prevent vim from inserting new lines into text automatically
set textwidth=0
set wrapmargin=0

" Move selected line up or down, moving adjacent lines appropriately
vnoremap <C-j> :m '>+1<CR>gv=gv
vnoremap <C-k> :m '<-2<CR>gv=gv

"""""""""""""""""""""""""""""""""""""""""""""
" Editing mappings
"""""""""""""""""""""""""""""""""""""""""""""

" greatest remaps ever // ThePrimeagen
vnoremap <leader>p "_dP
nnoremap <leader>y "+y
vnoremap <leader>y "+y
nnoremap <leader>Y gg"+yG

" Delete trailing white-space on save
fun! CleanExtraSpaces()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    silent! %s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfun

if has("autocmd")
    autocmd BufWritePre *.js,*.sh,*.md :call CleanExtraSpaces()
endif

"""""""""""""""""""""""""""""""""""""""""""""
" Spell checking
"""""""""""""""""""""""""""""""""""""""""""""

" Pressing ,ss will toggle spell checking
map <leader>ss :setlocal spell!<cr>

