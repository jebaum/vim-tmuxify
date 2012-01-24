"=============================================================================="
" URL:         https://github.com/mhinz/vim-tmuxify
" Author:      Marco Hinz <mhinz@spline.de>
" Maintainer:  Marco Hinz <mhinz@spline.de>
"=============================================================================="
"
" The following functions and variables can be used by other plugins.
"
" Functions:
"
"   tmuxify#complete_panes()
"   tmuxify#complete_sessions
"   tmuxify#complete_windows()
"   tmuxify#create_pane()
"   tmuxify#kill_pane()
"   tmuxify#perm_pane()
"   tmuxify#run_program_in_pane()
"   tmuxify#send_to_pane()
"
" Variables:
"
"   g:loaded_tmuxify
"   g:tmuxify_default_send_action
"   g:tmuxify_default_start_program
"   g:tmuxify_split_win_size
"   g:tmuxify_vert_split
"
"=============================================================================="

" loaded? {{{1
if exists('g:loaded_tmuxify') || &cp
  finish
endif
let g:loaded_tmuxify = 1

let b:run_mode = 0

" complete_sessions() {{{1
function! tmuxify#complete_sessions(A, L, P)
  return system('tmux list-sessions | cut -d: -f1')
endfunction

" complete_windows() {{{1
function! tmuxify#complete_windows(A, L, P)
  return system('tmux list-windows -t ' . b:sessions . ' | cut -d: -f1')
endfunction

" complete_panes() {{{1
function! tmuxify#complete_panes(A, L, P)
  return system('tmux list-panes -t ' . b:sessions . ':' . b:windows .
        \' | cut -d: -f1')
endfunction

" create_pane() {{{1
function! tmuxify#create_pane(...) abort
  if !exists('$TMUX')
    echo "tmuxify: This Vim is not running in a tmux session!"
    return
  endif

  if exists('b:target_pane') || b:run_mode == 1
    call tmuxify#kill_pane()
    let b:run_mode = 0
  endif

  call system("tmux split-window -d " . g:tmuxify_vert_split . " -l " .
        \ g:tmuxify_split_win_size)

  if exists('b:perm_target_pane')
    let b:target_pane = b:perm_target_pane
  else
    let b:target_pane = str2nr(system('tmux list-panes | tail -n1 | cut -d: -f1'))
  endif

  if !exists('a:1') && exists('g:tmuxify_default_start_program')
    call system("tmux send-keys -t " .
          \b:target_pane .
          \" 'clear; " .
          \ g:tmuxify_default_start_program .
          \ "' C-m")
  endif

  augroup tmuxify
    autocmd!
    autocmd VimLeave * call tmuxify#kill_pane()
  augroup END
endfunction

" kill_pane() {{{1
function! tmuxify#kill_pane() abort
  if !exists('$TMUX')
    echo "tmuxify: This Vim is not running in a tmux session!"
    return
  endif

  if !exists('b:target_pane')
    return
  endif

  call system('tmux kill-pane -t ' . b:target_pane)
  unlet b:target_pane

  autocmd! tmuxify VimLeave *
  augroup! tmuxify
endfunction

" run_program_in_pane() {{{1
function! tmuxify#run_program_in_pane(path)
  if !exists('$TMUX')
    echo "tmuxify: This Vim is not running in a tmux session!"
    return
  endif

  if exists('b:target_pane')
    call tmuxify#kill_pane()
  endif
  call tmuxify#create_pane('rocknroll')
  let b:run_mode = 1
  call system("tmux send-keys -t " .
        \ b:target_pane .
        \ " 'clear; " .
        \ g:tmuxify_default_start_program .
        \ " " .
        \ a:path .
        \ "' C-m")
endfunction

" send_to_pane() {{{1
function! tmuxify#send_to_pane(...) abort
  if !exists('$TMUX')
    echo "tmuxify: This Vim is not running in a tmux session!"
    return
  endif

  if !exists('b:target_pane') || b:run_mode == 1
    call tmuxify#create_pane()
  endif

  if exists('b:perm_target_pane')
    let b:target_pane = b:perm_target_pane
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

  call system("tmux send-keys -t " . b:target_pane . " '" . l:action . "' C-m")
endfunction

" perm_pane() {{{1
function! tmuxify#perm_pane(...)
  if !exists('$TMUX')
    echo "tmuxify: This Vim is not running in a tmux session!"
    return
  endif

  if exists('a:1')
    let b:perm_target_pane = a:1
  endif

  let b:sessions = input('Session: ', '', 'custom,tmuxify#complete_sessions')
  let b:windows  = input('Window: ', '', 'custom,tmuxify#complete_windows')
  let b:panes    = input('Pane: ', '', 'custom,tmuxify#complete_panes')

  let b:perm_target_pane = b:sessions . ':' .  b:windows . '.' . b:panes
endfunction

" vim: et sw=2 sts=2 tw=80
