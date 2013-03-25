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

" s:SID() {{{1
function s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

" s:complete_sessions() {{{1
function! s:complete_sessions(...) abort
  return system('tmux list-sessions | cut -d: -f1')
endfunction

" s:complete_windows() {{{1
function! s:complete_windows(...) abort
  return system('tmux list-windows -t '. b:session .' | cut -d: -f1')
endfunction

" s:complete_panes() {{{1
function! s:complete_panes(...) abort
  return system('tmux list-panes -t '. b:session .':'. b:window .' | cut -d: -f1')
endfunction

" s:setup_exit_handler() {{{1
function! s:setup_exit_handler()
  augroup tmuxify
    autocmd!
    autocmd VimLeave * call libtmuxify#pane_kill()
  augroup END
endfunction

" s:get_pane_num_from_id() {{{1
function! s:get_pane_num_from_id(pane_id) abort
  let pane_num = system("tmux list-panes -F '#D #P' | cut -b2- | awk '$1 == ". a:pane_id ." { print $2 }'")
  return empty(pane_num) ? '' : str2nr(pane_num)
  "echomsg 'tmuxify: Pane with ID '. b:pane_id .' does not exist! Run :TxCreate.'
endfunction

" libtmuxify#pane_create() {{{1
function! libtmuxify#pane_create(...) abort
  if !exists('$TMUX')
    echomsg 'tmuxify: This Vim is not running in a tmux session!'
    return
  elseif exists('b:pane_id')
    let pane_num = s:get_pane_num_from_id(b:pane_id)
    if !empty(pane_num)
      echomsg "tmuxify: I'm already associated with pane ". pane_num .'!'
      return
    endif
  endif

  call system('tmux split-window -d '. g:tmuxify_pane_split .' -l '. g:tmuxify_pane_size)
  let [ b:pane_id, b:pane_num ] = map(split(system("tmux list-panes -F '#D #P' | awk '$1 > id { id=$1; num=$2 } END { print substr(id, 2), num }'"), ' '), 'str2nr(v:val)')

  if exists('a:1')
    call libtmuxify#pane_send(a:1)
  endif

  call <SID>setup_exit_handler()

  return 1
endfunction

" libtmuxify#pane_kill() {{{1
function! libtmuxify#pane_kill() abort
  if !exists('b:pane_id')
    echomsg "tmuxify: I'm not associated with any pane! Run :TxCreate."
    return
  endif

  let pane_num = s:get_pane_num_from_id(b:pane_id)
  if empty(pane_num)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
  else
    call system('tmux kill-pane -t '. pane_num)
  endif

  unlet b:pane_id b:pane_num

  autocmd! tmuxify VimLeave *
  augroup! tmuxify
endfunction

" libtmuxify#pane_set() {{{1
function! libtmuxify#pane_set() abort
  if !exists('$TMUX')
    echomsg 'tmuxify: This Vim is not running in a tmux session!'
    return
  endif

  let b:session = input('Session: ', '', 'custom,<SNR>'. s:SID() .'_complete_sessions')
  let b:window  = input('Window: ',  '', 'custom,<SNR>'. s:SID() .'_complete_windows')
  let b:pane    = input('Pane: ',    '', 'custom,<SNR>'. s:SID() .'_complete_panes')

  " TODO: support other windows/sessions
  "let b:pane = b:session .':'.  b:window .'.'. b:pane

  let b:pane_num = b:pane
  let b:pane_id  = system("tmux list-panes -F '#D #P' | awk '$2 == ". b:pane_num ." { print substr($1, 2) }'")
  if empty(b:pane_id)
    redraw | echomsg 'tmuxify: There is no pane '. str2nr(b:pane_num) .'!'
    return
  endif

  call <SID>setup_exit_handler()
endfunction

" vim: et sw=2 sts=2 tw=80
" libtmuxify#pane_run() {{{1
function! libtmuxify#pane_run(...) abort
  if !exists('b:pane_id') && !libtmuxify#pane_create()
    return
  endif

  let ft = !empty(&ft) ? &ft : ' '

  if exists('a:1')
    let action = a:1
  elseif exists('g:tmuxify_run') && has_key(g:tmuxify_run, ft) && !empty(g:tmuxify_run[ft])
    let action = g:tmuxify_run[ft]
  else
    let action = input('TxRun> ')
  endif

  if !exists('g:tmuxify_run')
    let g:tmuxify_run = {}
  endif
  let g:tmuxify_run[ft] = substitute(action, '%', resolve(expand('%:p')), '')

  call libtmuxify#pane_send(g:tmuxify_run[ft])
endfunction

" libtmuxify#pane_send() {{{1
function! libtmuxify#pane_send(...) abort
  if (exists('a:1') && (a:1 == 'clear')) || (!exists('b:pane_id') && !libtmuxify#pane_create())
    return
  endif

  let pane_num = s:get_pane_num_from_id(b:pane_id)
  if empty(pane_num)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
    return
  endif

  call system('tmux send-keys -t '. pane_num .' '. shellescape(exists('a:1') ? a:1 : input('TxSend> ')) .' C-m')
endfunction

" libtmuxify#pane_send_sigint() {{{1
function! libtmuxify#pane_send_sigint() abort
  if !exists('b:pane_id')
    echomsg "tmuxify: I'm not associated with any pane! Run :TxCreate."
    return
  endif

  let pane_num = s:get_pane_num_from_id(b:pane_id)
  if empty(pane_num)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
    return
  endif

  call system('tmux send-keys -t '. pane_num .' C-c')
endfunction

" libtmuxify#set_run_command_for_filetype() {{{1
function! libtmuxify#set_run_command_for_filetype(...) abort
  if !exists('g:tmuxify_run')
    let g:tmuxify_run = {}
  endif

  let ft = !empty(&ft) ? &ft : ' '
  let g:tmuxify_run[ft] = exists('a:1') ? a:1 : input('TxSet('. ft .')> ')
endfunction
