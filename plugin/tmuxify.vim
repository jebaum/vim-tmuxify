" Plugin:      https://github.com/mhinz/vim-tmuxify
" Description: Plugin for handling tmux panes like a boss.
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.1

if exists('g:loaded_tmuxify') || &cp
  finish
endif
let g:loaded_tmuxify = 1

" '-h' for horizontal split window
" '-v' for vertical split window
let g:tmuxify_pane_split = get(g:, 'tmuxify_pane_split', '-v')
let g:tmuxify_pane_size  = get(g:, 'tmuxify_pane_size',  '10')

let g:tmuxify_map_prefix = get(g:, 'tmuxify_map_prefix', '<leader>m')

" commands {{{1
command! -nargs=0 -bar TxClear     call tmuxify#pane_send_raw('C-l')
command! -nargs=0 -bar TxKill      call tmuxify#pane_kill()
command! -nargs=0 -bar TxSetPane   call tmuxify#pane_set()
command! -nargs=0 -bar TxSigInt    call tmuxify#pane_send_raw('C-c')
command! -nargs=? -bar TxCreate    call tmuxify#pane_create(<args>)
command! -nargs=? -bar TxRun       call tmuxify#pane_run(<args>)
command! -nargs=? -bar TxSend      call tmuxify#pane_send(<args>)
command! -nargs=? -bar TxSetRunCmd call tmuxify#set_run_command_for_filetype(<args>)

" mappings {{{1
if g:tmuxify_map_prefix !=# ""
  execute 'nnoremap <silent>' g:tmuxify_map_prefix.'b' ':TxSigInt<cr>'
  execute 'nnoremap <silent>' g:tmuxify_map_prefix.'c' ':TxClear<cr>'
  execute 'nnoremap <silent>' g:tmuxify_map_prefix.'n' ':TxCreate<cr>'
  execute 'nnoremap <silent>' g:tmuxify_map_prefix.'p' ':TxSetPane<cr>'
  execute 'nnoremap <silent>' g:tmuxify_map_prefix.'q' ':TxKill<cr>'
  execute 'nnoremap <silent>' g:tmuxify_map_prefix.'r' ':TxRun<cr>'
  execute 'nnoremap <silent>' g:tmuxify_map_prefix.'s' ':TxSend<cr>'
  execute 'nnoremap <silent>' g:tmuxify_map_prefix.'t' ':TxSetRunCmd<cr>'

  execute 'xnoremap <silent>' g:tmuxify_map_prefix.'s' '"my:TxSend(@m)<cr>'
endif
