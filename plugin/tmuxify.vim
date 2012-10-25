if exists('g:loaded_tmuxify') || &cp
  finish
endif
let g:loaded_tmuxify = 1

" variables {{{1
if !exists('g:tmuxify_start_program')
  let g:tmuxify_run_program = 'env -i'
endif

" '-h' for horizontal split window
" '-v' for vertical split window
if !exists('g:tmuxify_vert_split')
  let g:tmuxify_vert_split = '-v'
endif

if !exists('g:tmuxify_pane_height')
  let g:tmuxify_pane_height = '16'
endif

" commands {{{1
command! -nargs=0 -bar TxClear  call libtmuxify#pane_send('clear')
command! -nargs=0 -bar TxKill   call libtmuxify#pane_kill()
command! -nargs=0 -bar TxSet    call libtmuxify#pane_set()
command! -nargs=? -bar TxCreate call libtmuxify#pane_create(<args>)
command! -nargs=? -bar TxRun    call libtmuxify#pane_run(<args>)
command! -nargs=? -bar TxSend   call libtmuxify#pane_send(<args>)

" mappings {{{1
nnoremap <silent> <leader>mc :TxClear<cr>
nnoremap <silent> <leader>mn :TxCreate<cr>
nnoremap <silent> <leader>mp :TxSet<cr>
nnoremap <silent> <leader>mq :TxKill<cr>
nnoremap <silent> <leader>mr :TxRun(expand('%:r'))<cr>
nnoremap <silent> <leader>ms :TxSend<cr>

vnoremap <silent> <leader>ms "my :TxSend(@m)<cr>
