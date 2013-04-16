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
nnoremap <silent> <leader>mb :TxSigInt<cr>
nnoremap <silent> <leader>mc :TxClear<cr>
nnoremap <silent> <leader>mn :TxCreate<cr>
nnoremap <silent> <leader>mp :TxSetPane<cr>
nnoremap <silent> <leader>mq :TxKill<cr>
nnoremap <silent> <leader>mr :TxRun<cr>
nnoremap <silent> <leader>ms :TxSend<cr>
nnoremap <silent> <leader>mt :TxSetRunCmd<cr>

xnoremap <silent> <leader>ms "my:TxSend(@m)<cr>
