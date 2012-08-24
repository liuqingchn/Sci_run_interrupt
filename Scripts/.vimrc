autocmd BufRead,BufNewFile *.py syntax on
autocmd BufRead,BufNewFile *.py set ai
autocmd BufRead *.py set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class,and,as,assert,break,continue,del,from,global,import,in,is,lambda,not,or,pass,print,raise,return,try,with,yield,cmp,repr,str,type
set modeline
set guifont=Andale\ Mono\ 14
set backspace=indent,eol,start
set tabstop=4 
set expandtab 
set shiftwidth=4 
set softtabstop=4 
set autoindent 
set smarttab
syntax on

set selectmode=mouse

if has('gui_running')
    if has("gui_gtk2")
        set guifont=courier\ 9
    elseif has(gui_win32")
        set guifont=courier:h9
    endif
endif

colorscheme peachpuff

