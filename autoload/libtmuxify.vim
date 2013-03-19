" Copyright (c) 2013 Marco Hinz
" All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" - Redistributions of source code must retain the above copyright notice, this
"   list of conditions and the following disclaimer.
" - Redistributions in binary form must reproduce the above copyright notice,
"   this list of conditions and the following disclaimer in the documentation
"   and/or other materials provided with the distribution.
" - Neither the name of the author nor the names of its contributors may be
"   used to endorse or promote products derived from this software without
"   specific prior written permission.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
" IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
" ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
" LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
" CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
" SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
" INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
" CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
" ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
" POSSIBILITY OF SUCH DAMAGE.

if exists('g:loaded_libtmuxify') || &cp || !executable('awk')
  finish
endif
let g:loaded_libtmuxify = 1

" '-h' for horizontal split window
" '-v' for vertical split window
let s:split       = exists('g:tmuxify_split')       ? g:tmuxify_split       : '-v'
let s:pane_height = exists('g:tmuxify_pane_height') ? g:tmuxify_pane_height : '16'

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
  return system('tmux list-windows -t '. b:sessions .' | cut -d: -f1')
endfunction

" complete_panes() {{{1
function! s:complete_panes(a, l, p) abort
  return system('tmux list-panes -t '. b:sessions .':'. b:windows .' | cut -d: -f1')
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

  call system('tmux split-window -d '. g:tmuxify_split .' -l '. g:tmuxify_pane_height)

  let b:target_pane = str2nr(system("tmux list-panes | awk '$7 > max { max=$7; ret=$1 } END { print ret + 0 }'"))
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

  call system('tmux kill-pane -t '. b:target_pane)
  unlet b:target_pane
  let b:tmuxified = 0

  autocmd! tmuxify VimLeave *
  augroup! tmuxify
endfunction

" pane_run() {{{1
function! libtmuxify#pane_run(path, ...) abort
  if !b:tmuxified
    call libtmuxify#pane_create()
    let b:tmuxified = 1
  endif

  if exists('g:tmuxify_run') && has_key(g:tmuxify_run, &ft) && !empty(g:tmuxify_run[&ft])
    let action = g:tmuxify_run[&ft]
  else
    let action = input('TxRun> ')
    if !exists('g:tmuxify_run')
      let g:tmuxify_run = {}
    endif
    let g:tmuxify_run[&ft] = action
  endif

  let action = substitute(action, '%', a:path, '')

  call libtmuxify#pane_send(action)
endfunction

" pane_send() {{{1
function! libtmuxify#pane_send(...) abort
  if !b:tmuxified
    call libtmuxify#pane_create()
    let b:tmuxified = 1
  endif

  let action = exists('a:1') ? a:1 : input('TxSend> ')

  call system('tmux send-keys -t '. b:target_pane .' '. shellescape(action) .' C-m')
endfunction

" run_set_command_for_filetype() {{{1
function! libtmuxify#run_set_command_for_filetype() abort
  if !exists('g:tmuxify_run')
    let g:tmuxify_run = {}
  endif

  let g:tmuxify_run[&ft] = input('TxSet('. &ft .')> ')
endfunction

function! libtmuxify#pane_send_sigint() abort
  if exists('b:target_pane')
    call system('tmux send-keys -t '. b:target_pane .' C-c')
  endif
endfunction

" pane_set() {{{1
function! libtmuxify#pane_set() abort
  if !exists('$TMUX')
    echo 'tmuxify: This Vim is not running in a tmux session!'
    return
  endif

  let b:sessions = input('Session: ', '', 'custom,<SNR>'. s:SID() .'_complete_sessions')
  let b:windows  = input('Window: ',  '', 'custom,<SNR>'. s:SID() .'_complete_windows')
  let b:panes    = input('Pane: ',    '', 'custom,<SNR>'. s:SID() .'_complete_panes')

  let b:target_pane = b:sessions .':'.  b:windows .'.'. b:panes
  let b:tmuxified   = 1

  call <SID>setup_exit_handler()
endfunction

" vim: et sw=2 sts=2 tw=80
