"=============================================================================="
" URL:         https://github.com/mhinz/vim-tmuxify
" Author:      Marco Hinz <mhinz@spline.de>
" Maintainer:  Marco Hinz <mhinz@spline.de>
"=============================================================================="
"
" The following functions and variables can be used by other plugins.
"
" External functions:
"
"   tmuxify#create_pane()
"   tmuxify#kill_pane()
"   tmuxify#send_to_pane()
"
" External variables:
"
"   g:loaded_tmuxify
"   g:tmuxify_default_send_action
"   g:tmuxify_default_start_program
"   g:tmuxify_vert_split
"
"=============================================================================="

" loaded? {{{1
if exists('g:loaded_tmuxify') || &cp
  finish
endif
let g:loaded_tmuxify = 1

" create_pane() {{{1
function! tmuxify#create_pane() abort
  if !exists('$TMUX')
    echo "tmuxify: This Vim is not running in a tmux session!"
    return
  endif

  call system("tmux split-window -d " . g:tmuxify_vert_split . " -l " .
        \ g:tmuxify_split_win_size)

  let s:last_pane = str2nr(system('tmux list-panes | tail -n1 | cut -d: -f1'))

  if exists('g:tmuxify_default_start_program')
    call system("tmux send-keys -t " . s:last_pane . " '" .
          \ g:tmuxify_default_start_program . "' C-m")
  endif

  augroup tmuxify
    autocmd!
    autocmd VimLeave * call tmuxify#kill_pane()
  augroup END
endfunction

" kill_pane() {{{1
function! tmuxify#kill_pane() abort
  if !exists('s:last_pane')
    return
  endif

  call system('tmux kill-pane -t ' . s:last_pane)
  unlet s:last_pane

  autocmd! tmuxify VimLeave *
  augroup! tmuxify
endfunction

" send_to_pane() {{{1
function! tmuxify#send_to_pane(...) abort
  if !exists('s:last_pane')
    call tmuxify#create_pane()
  endif

  if exists('a:1')
    let l:action = a:1
  else
    if exists('g:tmuxify_default_send_action')
      let l:action = g:tmuxify_default_send_action
    else
      let l:action = input('tmuxify> ')
    endif
  endif

  call system("tmux send-keys -t " . s:last_pane . " '" . l:action . "' C-m")
endfunction

" vim: et sw=2 sts=2 tw=80
