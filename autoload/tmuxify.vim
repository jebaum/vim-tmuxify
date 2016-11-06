" Plugin:      https://github.com/mhinz/vim-tmuxify
" Description: Plugin for handling tmux panes like a boss.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.1

if exists('g:autoloaded_tmuxify') || &compatible || !executable('tmux') || !executable('awk')
  finish
endif
let g:autoloaded_tmuxify = 1

" Uncommon separator
let s:separator  = '__::__'
let s:list_panes = printf("tmux list-panes -a -F '#D%s#S%s#I%s#P'", s:separator, s:separator, s:separator)
let s:awk_cmd    = printf('awk -F "%s"', s:separator)

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

function! s:complete_descriptor(...) abort
  return system('tmux list-panes -aF "#S:#I.#P"')
endfunction

" s:get_pane_descriptor_from_id() {{{1
function! s:get_pane_descriptor_from_id(pane_id) abort
  let cmd = s:list_panes . " | " . s:awk_cmd . " 'substr($1, 2) == " . a:pane_id . " { print $2 FS $3 FS $4 }'"
  if exists('*systemlist')
    let descriptor_list = systemlist(cmd)
  else
    let descriptor_list = split(system(cmd), '\n')
  endif
  if empty(descriptor_list) || descriptor_list[0] == 'failed to connect to server: Connection refused'
    return ''
  else
    " there should only ever be one item in descriptor_list, since it was filtered for matching the unique pane_id
    let [session, window, pane] = split(descriptor_list[0], s:separator)
    return session . ':' . window . '.' . pane
  endif
endfunction

" s:parse_pane_descriptor() {{{1
function! s:parse_pane_descriptor(descriptor) abort
  let [session, window_and_pane] = split(a:descriptor, ':')
  let [window, pane] = split(window_and_pane, '\W')
  return [session, window, pane]
endfunction

" s:get_scope() {{{1
function! s:get_scope(bang) abort
  return empty(a:bang) ? 'b:' : 'g:'
endfunction

" s:print_upgrade_message_if_shell_error() {{{1
function! s:print_upgrade_message_if_shell_error() abort
  if v:shell_error
    echoerr 'tmuxify: A certain version of tmux 1.6 or higher is needed. Consider updating to 1.7+.'
  endif
endfunction

" tmuxify#pane_create() {{{1
function! tmuxify#pane_create(bang, ...) abort
  let scope = s:get_scope(a:bang)

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
  let tmuxify_command = get(g:, 'tmuxify_custom_command', 'tmux split-window -d') . printf(" -PF '#D%s#S%s#I%s#P'", s:separator, s:separator, s:separator)
  let cmd = tmuxify_command . " | " . s:awk_cmd . " '{id=$1; session=$2; window=$3; pane=$4} END { print substr(id, 2) FS session FS window FS pane }'"
  let [ pane_id, session, window, pane ] = map(split(system(cmd), s:separator), 'str2nr(v:val)')

  call s:print_upgrade_message_if_shell_error()

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
  let scope = s:get_scope(a:bang)

  if !exists(scope . 'pane_id')
    echomsg "tmuxify: I'm not associated with any pane! Run :TxCreate, or check whether you're using bang commands consistently."
    return
  endif

  execute 'let pane_id = ' scope . 'pane_id'
  let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
  if empty(pane_descriptor)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
  else
    call system('tmux kill-pane -t ' . shellescape(pane_descriptor))
  endif

  execute 'unlet ' . scope . 'pane_id'
endfunction

" tmuxify#pane_set() {{{1
function! tmuxify#pane_set(bang, ...) abort
  let scope = s:get_scope(a:bang)

  if a:0 == 1
    if a:1[0] == '%'
      let descriptor_string = s:get_pane_descriptor_from_id(strpart(a:1, 1))
      if empty(descriptor_string)
        echomsg 'tmuxify: Invalid Pane ID!'
        return
      endif
      let [session, window, pane] = s:parse_pane_descriptor(descriptor_string)
    else
      let [session, window, pane] = s:parse_pane_descriptor(a:1)
    endif
  else
    let descriptor = input('Session:Window.Pane> ', '', 'custom,<SNR>' . s:SID() . '_complete_descriptor')
    let [session, window, pane] = s:parse_pane_descriptor(descriptor)
  endif

  execute "let " . scope . "session = session"
  execute "let " . scope . "window = window"
  execute "let " . scope . "pane = pane"

  let pane_id = system(s:list_panes . " | " . s:awk_cmd . " '$2 == \"" . session . "\" && $3 == \"" . window . "\" && $4 == \"" . pane . "\" {print substr($1, 2)}'")
  if empty(pane_id)
    redraw | echomsg 'tmuxify: There is no pane '. pane .'!'
    return
  endif

  execute "let " . scope . "pane_id = str2nr(pane_id)"
endfunction

" tmuxify#pane_run() {{{1
function! tmuxify#pane_run(bang, ...) abort
  let scope = s:get_scope(a:bang)

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
  let scope = s:get_scope(a:bang)

  if !exists(scope . 'pane_id') && !tmuxify#pane_create(a:bang)
    return
  endif

  execute 'let pane_id = ' . scope . 'pane_id'
  let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
  if empty(pane_descriptor)
    echomsg 'tmuxify: The associated pane was already closed! Run :TxCreate.'
    return
  endif

  let pane_descriptor = shellescape(pane_descriptor)

  if exists('a:1')
    for line in split(a:1, '\n')
      call system('tmux send-keys -t '. pane_descriptor .' -l '. shellescape(s:fixstr(line)) .' && tmux send-keys -t '. pane_descriptor .' C-m')
      call s:print_upgrade_message_if_shell_error()
    endfor
  else
    call system('tmux send-keys -t '. pane_descriptor .' '. shellescape(s:fixstr(input('TxSend> '))) .' C-m')
  endif
endfunction

function! s:fixstr(line)
  let line = substitute(a:line, '\t', ' ', 'g')
  return line[-1:] == ';' ? line[:-2] . '\;' : line
endfunction

" tmuxify#pane_send_raw() {{{1
function! tmuxify#pane_send_raw(cmd, bang) abort
  let scope = s:get_scope(a:bang)

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

  call system('tmux send-keys -t ' . shellescape(pane_descriptor) . " '" . keys . "'")
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
  let scope = s:get_scope(a:bang)

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

  call system('tmux ' . a:1 . ' -t ' . shellescape(pane_descriptor))
endfunction

" vim: et sw=2 sts=2 tw=80
