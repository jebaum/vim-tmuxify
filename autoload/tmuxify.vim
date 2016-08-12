" Plugin:      https://github.com/mhinz/vim-tmuxify
" Description: Plugin for handling tmux panes like a boss.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.1

if exists('g:autoloaded_tmuxify') || &compatible || !executable('tmux') || !executable('awk')
  finish
endif
let g:autoloaded_tmuxify = 1

" s:SID() {{{1
function! s:SID() abort
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

function! s:complete_descriptor(...) abort
  return system('tmux list-panes -aF "#S:#I.#P"')
endfunction

" s:get_pane_descriptor_from_id() {{{1
function! s:get_pane_descriptor_from_id(pane_id) abort
  if exists('*systemlist')
    let descriptor_list = systemlist("tmux list-panes -a -F '#D #S #I #P' | awk 'substr($1, 2) == ". a:pane_id ." { print $2, $3, $4 }'")
  else
    let descriptor_list = split(system("tmux list-panes -a -F '#D #S #I #P' | awk 'substr($1, 2) == ". a:pane_id ." { print $2, $3, $4 }'"), '\n')
  endif
  if empty(descriptor_list) || descriptor_list[0] == 'failed to connect to server: Connection refused'
    return ''
  else
    " there should only ever be one item in descriptor_list, since it was filtered for matching the unique pane_id
    let [session, window, pane] = split(descriptor_list[0],' ')
    return session . ':' . window . '.' . pane
  endif
endfunction

" tmuxify#pane_create() {{{1
function! tmuxify#pane_create(bang, ...) abort
  if empty(a:bang)
    let scope = "b:"
  else
    let scope = "g:"
  endif

  if !exists('$TMUX')
    echomsg 'tmuxify: This Vim is not running in a tmux session!'
    return
  elseif exists(scope . 'pane_id')
    execute 'let pane_id = ' . scope . 'pane_id'
    let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
    if !empty(pane_descriptor)
      echomsg "tmuxify: I'm already associated with pane ". pane_descriptor .'!'
      return
    endif
  endif

  " capture the pane_id, as well as session, window, and pane index information
  " pane_id is unique, pane_index will change if the pane is moved
  let [ pane_id, session, window, pane ] = map(split(system(get(g:, 'tmuxify_custom_command', 'tmux split-window -d') . " -PF '#D #S #I #P' | awk '{id=$1; session=$2; window=$3; pane=$4} END { print substr(id, 2), session, window, pane }'"), ' '), 'str2nr(v:val)')
  if v:shell_error
    echoerr 'tmuxify: A certain version of tmux 1.6 or higher is needed. Consider updating to 1.7+.'
  endif

  if exists('a:1')
    call tmuxify#pane_send(a:bang, a:1)
  endif

  execute 'let ' . scope . 'pane_id = pane_id'
  execute 'let ' . scope . 'session = session'
  execute 'let ' . scope . 'window = window'
  execute 'let ' . scope . 'pane = pane'
  return 1
endfunction

" tmuxify#pane_kill() {{{1
function! tmuxify#pane_kill(bang) abort
  if empty(a:bang)
    let scope = "b:"
  else
    let scope = "g:"
  endif

  if !exists(scope . 'pane_id')
    echomsg "tmuxify: I'm not associated with any pane! Run :TxCreate, or check whether you're using bang commands consistently."
    return
  endif

  execute 'let pane_id = ' scope . 'pane_id'
  let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
  if empty(pane_descriptor)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
  else
    call system('tmux kill-pane -t '. pane_descriptor)
  endif

  execute 'unlet ' . scope . 'pane_id'
endfunction

" tmuxify#pane_set() {{{1
function! tmuxify#pane_set(bang, ...) abort
  if empty(a:bang)
    let scope = "b:"
  else
    let scope = "g:"
  endif

  if a:0 == 1
    if a:1[0] == '%'
      let descriptor_string = s:get_pane_descriptor_from_id(strpart(a:1, 1))
      if descriptor_string == ''
        echo 'tmuxify: Invalid Pane ID!'
        return
      endif
      let [session, window, pane] = split(descriptor_string, '\W')
    else
      let [session, window, pane] = split(a:1, '\W')
    endif
  else
    let descriptor = input('Session:Window.Pane> ',    '', 'custom,<SNR>'. s:SID() .'_complete_descriptor')
    let [session, window, pane] = split(descriptor, '\W')
  endif

  execute "let " . scope . "session = session"
  execute "let " . scope . "window = window"
  execute "let " . scope . "pane = pane"

  let pane_id    = system("tmux list-panes -a -F '#D #S #I #P' | awk '$2 == \"". session ."\" && $3 == \"". window ."\" && $4 == \"". pane ."\" {print substr($1, 2)}'")
  if empty(pane_id)
    redraw | echomsg 'tmuxify: There is no pane '. pane .'!'
    return
  endif

  execute "let " . scope . "pane_id = str2nr(pane_id)"
endfunction

" tmuxify#pane_run() {{{1
function! tmuxify#pane_run(bang, ...) abort
  if empty(a:bang)
    let scope = "b:"
  else
    let scope = "g:"
  endif

  if !exists(scope . 'pane_id') && !tmuxify#pane_create(a:bang)
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

  call tmuxify#pane_send(a:bang, substitute(g:tmuxify_run[ft], '%', resolve(expand('%:p')), ''))
endfunction

" tmuxify#pane_send() {{{1
function! tmuxify#pane_send(bang, ...) abort
  if empty(a:bang)
    let scope = "b:"
  else
    let scope = "g:"
  endif

  if !exists(scope . 'pane_id') && !tmuxify#pane_create(a:bang)
    return
  endif

  execute 'let pane_id = ' . scope . 'pane_id'
  let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
  if empty(pane_descriptor)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
    return
  endif

  if exists('a:1')
    for line in split(a:1, '\n')
      call system('tmux send-keys -t '. pane_descriptor .' -l -- '. shellescape(s:fixstr(line)) .' && tmux send-keys -t '. pane_descriptor .' C-m')
      if v:shell_error
        echoerr 'tmuxify: A certain version of tmux 1.6 or higher is needed. Consider updating to 1.7+.'
      endif
    endfor
  else
    call system('tmux send-keys -t '. pane_descriptor .' -- '. shellescape(s:fixstr(input('TxSend> '))) .' C-m')
  endif
endfunction

function! s:fixstr(line)
  let line = substitute(a:line, '\t', ' ', 'g')
  return line[-1:] == ';' ? line[:-2] . '\;' : line
endfunction

" tmuxify#pane_send_raw() {{{1
function! tmuxify#pane_send_raw(cmd, bang) abort
  if empty(a:bang)
    let scope = "b:"
  else
    let scope = "g:"
  endif

  if !exists(scope . 'pane_id') && !tmuxify#pane_create(a:bang)
    return
  endif

  execute 'let pane_id = ' scope . 'pane_id'
  let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
  if empty(pane_descriptor)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
    return
  endif

  if empty(a:cmd)
    let keys = input('TxSendKey> ')
  else
    let keys = a:cmd
  endif

  call system('tmux send-keys -t '. pane_descriptor ." -- '". s:fixstr(keys) . "'")
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
function! tmuxify#get_associated_pane(...) abort
  if (a:0 == 0)
    let scope = "b:"
  else
    let scope = "g:"
  endif

  if !exists(scope . 'pane_id')
    return -1
  endif

  execute 'let pane_id = ' . scope . 'pane_id'
  let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
  return empty(pane_descriptor) ? -1 : pane_descriptor
endfunction

" tmuxify#pane_command() {{{1
function! tmuxify#pane_command(bang, ...) abort
  if empty(a:bang)
    let scope = "b:"
  else
    let scope = "g:"
  endif

  if !exists(scope . 'pane_id')
    echomsg "tmuxify: I'm not associated with any pane! Run :TxCreate, or check whether you're using bang commands consistently."
    return
  endif

  execute 'let pane_id = ' scope . 'pane_id'
  let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
  if empty(pane_descriptor)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
    return
  endif

  call system('tmux ' . a:1 . ' -t '. pane_descriptor)
endfunction

" vim: et sw=2 sts=2 tw=80
