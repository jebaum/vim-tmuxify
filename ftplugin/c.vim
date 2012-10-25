if exists('g:loaded_tmuxify_c') || &cp
  finish
endif
let g:loaded_tmuxify_c = 1

let g:tmuxify_run_program = 'env -i'
