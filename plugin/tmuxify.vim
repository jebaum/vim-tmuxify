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
command! -nargs=0 -bar TxKill      call libtmuxify#pane_kill()
command! -nargs=0 -bar TxSetTarget call libtmuxify#pane_set()
command! -nargs=? -bar TxCreate    call libtmuxify#pane_create(<args>)
command! -nargs=? -bar TxSend      call libtmuxify#pane_send(<args>)

" mappings {{{1
nnoremap <silent> <leader>mc :call libtmuxify#pane_send('clear')<cr>
nnoremap <silent> <leader>mn :call libtmuxify#pane_create()<cr>
nnoremap <silent> <leader>mp :call libtmuxify#pane_set()<cr>
nnoremap <silent> <leader>mq :call libtmuxify#pane_kill()<cr>
nnoremap <silent> <leader>mr :call libtmuxify#pane_run(expand('%:r'))<cr>
nnoremap <silent> <leader>ms :call libtmuxify#pane_send()<cr>

vnoremap <silent> <leader>ms "my :call libtmuxify#pane_send(@m)<cr>
