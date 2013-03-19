if exists('g:loaded_tmuxify') || &cp
  finish
endif
let g:loaded_tmuxify = 1

" '-h' for horizontal split window
" '-v' for vertical split window
let g:tmuxify_split         = exists('g:tmuxify_split')         ? g:tmuxify_split         : '-v'
let g:tmuxify_pane_height   = exists('g:tmuxify_pane_height')   ? g:tmuxify_pane_height   : '16'
let g:tmuxify_start_program = exists('g:tmuxify_start_program') ? g:tmuxify_start_program : 'env -i'

" commands {{{1
command! -nargs=0 -bar TxClear     call libtmuxify#pane_send('clear')
command! -nargs=0 -bar TxKill      call libtmuxify#pane_kill()
command! -nargs=0 -bar TxSetPane   call libtmuxify#pane_set()
command! -nargs=0 -bar TxSetRunCmd call libtmuxify#run_set_command_for_filetype()
command! -nargs=0 -bar TxSigint    call libtmuxify#pane_send_sigint()
command! -nargs=? -bar TxCreate    call libtmuxify#pane_create(<args>)
command! -nargs=? -bar TxRun       call libtmuxify#pane_run(<args>)
command! -nargs=? -bar TxSend      call libtmuxify#pane_send(<args>)

" mappings {{{1
nnoremap <silent> <leader>mb :TxSigint<cr>
nnoremap <silent> <leader>mc :TxClear<cr>
nnoremap <silent> <leader>mn :TxCreate<cr>
nnoremap <silent> <leader>mp :TxSetPane<cr>
nnoremap <silent> <leader>mq :TxKill<cr>
nnoremap <silent> <leader>mr :TxRun(resolve(expand('%:p')))<cr>
nnoremap <silent> <leader>ms :TxSend<cr>
nnoremap <silent> <leader>mt :TxSetRunCmd<cr>

vnoremap <silent> <leader>ms "my :TxSend(@m)<cr>
