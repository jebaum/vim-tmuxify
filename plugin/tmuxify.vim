" Plugin:      https://github.com/mhinz/vim-tmuxify
" Description: Plugin for handling tmux panes like a boss.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.1

if exists('g:loaded_tmuxify') || &cp
  finish
endif
let g:loaded_tmuxify = 1

let global = get(g:, 'tmuxify_global_maps', 0) ? '!' : ''
let s:map_prefix = get(g:, 'tmuxify_map_prefix', '<leader>m')

" commands {{{1
command! -nargs=0 -bar -bang TxClear     call tmuxify#pane_send_raw('C-l', <q-bang>)
command! -nargs=0 -bar -bang TxKill      call tmuxify#pane_kill(<q-bang>)
command! -nargs=? -bar -bang TxSetPane   call tmuxify#pane_set(<q-bang>, <f-args>)
command! -nargs=0 -bar -bang TxSigInt    call tmuxify#pane_send_raw('C-c', <q-bang>)
command! -nargs=? -bar -bang TxCreate    call tmuxify#pane_create(<q-bang>, <args>)
command! -nargs=? -bar -bang TxRun       call tmuxify#pane_run(<q-bang>, <args>)
command! -nargs=? -bar -bang TxSend      call tmuxify#pane_send(<q-bang>, <args>)
command! -nargs=? -bar       TxSetRunCmd call tmuxify#set_run_command_for_filetype(<args>)

" mappings {{{1
if s:map_prefix !=# ""
  execute 'nnoremap <silent>' s:map_prefix .'b :TxSigInt' . global . '<cr>'
  execute 'nnoremap <silent>' s:map_prefix .'c :TxClear' . global . '<cr>'
  execute 'nnoremap <silent>' s:map_prefix .'n :TxCreate' . global . '<cr>'
  execute 'nnoremap <silent>' s:map_prefix .'p :TxSetPane' . global . '<cr>'
  execute 'nnoremap <silent>' s:map_prefix .'q :TxKill' . global . '<cr>'
  execute 'nnoremap <silent>' s:map_prefix .'r :TxRun' . global . '<cr>'
  execute 'nnoremap <silent>' s:map_prefix .'s :TxSend' . global . '<cr>'
  execute 'nnoremap <silent>' s:map_prefix .'t :TxSetRunCmd<cr>'

  execute 'xnoremap <silent>' s:map_prefix .'s "my:TxSend' . global . '(@m)<cr>'
endif
