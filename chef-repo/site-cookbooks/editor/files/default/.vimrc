set lazyredraw                    " マクロなどを実行中は描画を中断
set formatoptions+=m              " 整形オプション，マルチバイト系を追加
set shortmess+=I                  " 起動時のメッセージを表示しない
set fileformats=unix,dos,mac      " 改行コードの自動認識
set vb t_vb=                      " ビープ音を鳴らさない
set showcmd                       " 入力中のコマンドを表示

set wrap                                     " 行末の折り返し
set number                                   " 行番号表示
set list                                     " 行末に$を表示
set showmatch                                " 対応する括弧をハイライト
set listchars=tab:>-,extends:<,trail:-,eol:$ " 見えない文字を見えるように
set cursorline                               " 行カーソルを表示

set backspace=indent,eol,start    " バックスペースでなんでも消せるように
set whichwrap=b,s,h,l,<,>,[,]     " カーソルを行頭、行末で止まらないようにする

set termencoding=utf8
set encoding=japan
set fileencodings=utf-8,euc-jp,iso-2022-jp
set fenc=utf8
set enc=utf8

set expandtab                     " タブをスペースに展開
set softtabstop=4
set shiftwidth=4
set tabstop=4                     " タブをスペース4文字に変更
set autoindent                    " オートインデント
set ts=4 sw=4

set nobackup   " バックアップ取らない
set autoread   " 他で書き換えられたら自動で読み直す
set noswapfile " スワップファイル作らない
set hidden     " 編集中でも他のファイルを開けるようにする

set ignorecase " 大文字小文字無視
set smartcase  " 大文字ではじめたら大文字小文字無視しない
set incsearch  " インクリメンタルサーチ
set hlsearch   " 検索文字をハイライト