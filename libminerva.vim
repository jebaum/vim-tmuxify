"=============================================================================="
" URL:         https://github.com/mhinz/vim-javascript-minerva
" Author:      Marco Hinz <mhinz@spline.de>
" Maintainer:  Marco Hinz <mhinz@spline.de>
"=============================================================================="

" init {{{1

if exists('g:loaded_libminerva') || &cp
  finish
endif
let g:loaded_libminerva = 1

" functions {{{1

function! libminerva#create_pane() abort
  if !exists('$TMUX')
    echo "minerva: This Vim is not running in a tmux session!"
    return
  endif

  call system("tmux split-window -d " . g:minerva_vert_split . " -l " .
        \ g:minerva_split_win_size)

  let s:last_pane = str2nr(system('tmux list-panes | tail -n1 | cut -d: -f1'))

  if exists('g:minerva_interpreter')
    call system("tmux send-keys -t " . s:last_pane . " '" .
          \ g:minerva_interpreter . "' C-m")
  endif

  augroup tmuxify
    autocmd!
    autocmd VimLeave * call libminerva#kill_pane()
  augroup END
endfunction


function! libminerva#kill_pane() abort
  call system('tmux kill-pane -t ' . s:last_pane)
  autocmd! tmuxify VimLeave *
  augroup! tmuxify
endfunction


function! libminerva#send_to_pane(...) abort
  if !exists('s:last_pane')
    call libminerva#create_pane()
  endif

  if exists('a:1')
    let l:action = a:1
  else
    if exists('g:minerva_default_send_action')
      let l:action = g:minerva_default_send_action
    else
      let l:action = input('Minerva> ')
    endif
  endif

  call system("tmux send-keys -t " . s:last_pane . " '" . l:action . "' C-m")
endfunction

" vim: et sw=2 sts=2 tw=80
