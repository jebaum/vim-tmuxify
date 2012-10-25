"=============================================================================="
" URL:         https://github.com/mhinz/vim-tmuxify
" Author:      Marco Hinz <mhi@codebro.de>
" Maintainer:  Marco Hinz <mhi@codebro.de>
"=============================================================================="

if exists('g:loaded_libtmuxify') || &cp
  finish
endif
let g:loaded_libtmuxify = 1

let b:tmuxified = 0

" SID() {{{1
function s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

" complete_sessions() {{{1
function! s:complete_sessions(a, l, p) abort
  return system('tmux list-sessions | cut -d: -f1')
endfunction

" complete_windows() {{{1
function! s:complete_windows(a, l, p) abort
  return system('tmux list-windows -t ' . b:sessions . ' | cut -d: -f1')
endfunction

" complete_panes() {{{1
function! s:complete_panes(a, l, p) abort
  return system('tmux list-panes -t ' . b:sessions . ':' . b:windows .
        \' | cut -d: -f1')
endfunction

" setup_exit_handler() {{{1
function! s:setup_exit_handler()
  augroup tmuxify
    autocmd!
    autocmd VimLeave * call libtmuxify#pane_kill()
  augroup END
endfunction

" pane_create() {{{1
function! libtmuxify#pane_create(...) abort
  if b:tmuxified == 1
    if !exists('$TMUX')
      echo 'tmuxify: This Vim is not running in a tmux session!'
    endif
    return
  endif

  call system('tmux split-window -d ' . g:tmuxify_vert_split . ' -l ' .
        \ g:tmuxify_pane_height)

  let b:target_pane = str2nr(system('tmux list-panes | tail -n1 | cut -d: -f1'))
  let b:tmuxified   = 1

  if exists('a:1')
    call libtmuxify#pane_send(a:1)
  endif

  call <SID>setup_exit_handler()
endfunction

" pane_kill() {{{1
function! libtmuxify#pane_kill() abort
  if b:tmuxified == 0
    return
  endif

  call system('tmux kill-pane -t ' . b:target_pane)
  unlet b:target_pane
  let b:tmuxified = 0

  autocmd! tmuxify VimLeave *
  augroup! tmuxify
endfunction

" pane_run() {{{1
function! libtmuxify#pane_run(path, ...)
  if b:tmuxified == 1
    call libtmuxify#pane_kill()
  endif

  call libtmuxify#pane_create()
  let b:tmuxified = 1

  let l:action = 'clear; ' . g:tmuxify_run_program . ' ' . a:path

  if exists('a:1')
    let l:action = l:action . '; ' . a:1
  endif

  call libtmuxify#pane_send(l:action)
endfunction

" pane_send() {{{1
function! libtmuxify#pane_send(...) abort
  if b:tmuxified == 0
    return
  endif

  if exists('a:1')
    let l:action = a:1
  else
    let l:action = input('tmuxify> ')
  endif

  call system('tmux send-keys -t ' . b:target_pane . ' ' . shellescape(l:action) . ' C-m')
endfunction

" pane_set() {{{1
function! libtmuxify#pane_set()
  if !exists('$TMUX')
    echo 'tmuxify: This Vim is not running in a tmux session!'
    return
  endif

  let b:sessions = input('Session: ', '', 'custom,<SNR>' . s:SID() .
        \ '_complete_sessions')
  let b:windows = input('Window: ', '', 'custom,<SNR>' . s:SID() .
        \ '_complete_windows')
  let b:panes = input('Pane: ', '', 'custom,<SNR>' . s:SID() .
        \'_complete_panes')

  let b:target_pane = b:sessions . ':' .  b:windows . '.' . b:panes
  let b:tmuxified   = 1

  call <SID>setup_exit_handler()
endfunction

" vim: et sw=2 sts=2 tw=80
