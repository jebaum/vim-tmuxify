" Plugin:      https://github.com/mhinz/vim-tmuxify
" Description: Plugin for handling tmux panes like a boss.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.1

if exists('g:autoloaded_tmuxify') || &compatible || !executable('tmux') || !executable('awk')
  finish
endif
let g:autoloaded_tmuxify = 1

" s:SID() {{{1
function s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

" s:complete_sessions() {{{1
function! s:complete_sessions(...) abort
  return system('tmux list-sessions -F "#S"')
endfunction

" s:complete_windows() {{{1
function! s:complete_windows(...) abort
  return system('tmux list-windows -F "#I" -t '. b:session)
endfunction

" s:complete_panes() {{{1
function! s:complete_panes(...) abort
  return system('tmux list-panes -F "#P" -t '. b:session .':'. b:window)
endfunction

" s:get_pane_num_from_id() {{{1
function! s:get_pane_num_from_id(pane_id) abort
  let pane_num = system("tmux list-panes -F '#D #P' | awk 'substr($1, 2) == ". a:pane_id ." { print $2 }'")
  return empty(pane_num) ? '' : str2nr(pane_num)
endfunction

" tmuxify#pane_create() {{{1
function! tmuxify#pane_create(...) abort
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

  call system(get(g:, 'tmuxify_custom_command', 'tmux split-window -d'))
  if v:shell_error
    echoerr 'tmuxify: A certain version of tmux 1.6 or higher is needed. Consider updating to 1.7+.'
  endif
  let [ b:pane_id, b:pane_num ] = map(split(system("tmux list-panes -F '#D #P' | awk '$1 > id { id=$1; num=$2 } END { print substr(id, 2), num }'"), ' '), 'str2nr(v:val)')

  if exists('a:1')
    call tmuxify#pane_send(a:1)
  endif

  return 1
endfunction

" tmuxify#pane_kill() {{{1
function! tmuxify#pane_kill() abort
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
endfunction

" tmuxify#pane_set() {{{1
function! tmuxify#pane_set() abort
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
  let pane_id    = system("tmux list-panes -F '#D #P' | awk '$2 == ". b:pane ." { print substr($1, 2) }'")
  if empty(pane_id)
    redraw | echomsg 'tmuxify: There is no pane '. b:pane_num .'!'
    return
  endif
  let b:pane_id = str2nr(pane_id)
endfunction

" tmuxify#pane_run() {{{1
function! tmuxify#pane_run(...) abort
  if !exists('b:pane_id') && !tmuxify#pane_create()
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
  let g:tmuxify_run[ft] = action

  call tmuxify#pane_send(substitute(g:tmuxify_run[ft], '%', resolve(expand('%:p')), ''))
endfunction

" tmuxify#pane_send() {{{1
function! tmuxify#pane_send(...) abort
  if !exists('b:pane_id') && !tmuxify#pane_create()
    return
  endif

  let pane_num = s:get_pane_num_from_id(b:pane_id)
  if empty(pane_num)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
    return
  endif

  if exists('a:1')
    for line in split(a:1, '\n')
      call system('tmux send-keys -t '. pane_num .' -l '. shellescape(s:fixstr(line)) .' && tmux send-keys -t '. pane_num .' C-m')
      if v:shell_error
        echoerr 'tmuxify: A certain version of tmux 1.6 or higher is needed. Consider updating to 1.7+.'
      endif
    endfor
  else
    call system('tmux send-keys -t '. pane_num .' '. shellescape(s:fixstr(input('TxSend> '))) .' C-m')
  endif
endfunction

function! s:fixstr(line)
  return a:line[-1:] == ';' ? a:line[:-2] . '\;' : a:line
endfunction

" tmuxify#pane_send_raw() {{{1
function! tmuxify#pane_send_raw(cmd) abort
  if !exists('b:pane_id')
    echomsg "tmuxify: I'm not associated with any pane! Run :TxCreate."
    return
  endif

  let pane_num = s:get_pane_num_from_id(b:pane_id)
  if empty(pane_num)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
    return
  endif

  call system('tmux send-keys -t '. pane_num .' '. a:cmd)
endfunction

" tmuxify#set_run_command_for_filetype() {{{1
function! tmuxify#set_run_command_for_filetype(...) abort
  if !exists('g:tmuxify_run')
    let g:tmuxify_run = {}
  endif

  let ft = !empty(&ft) ? &ft : ' '
  let g:tmuxify_run[ft] = exists('a:1') ? a:1 : input('TxSet('. ft .')> ')
endfunction

" tmuxify#get_associated_pane() {{{1
function! tmuxify#get_associated_pane() abort
  if !exists('b:pane_id')
    return -1
  endif

  let pane_num = s:get_pane_num_from_id(b:pane_id)
  return empty(pane_num) ? -1 : pane_num
endfunction

" vim: et sw=2 sts=2 tw=80
