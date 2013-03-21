# vim-tmuxify

This is a shiny Vim plugin for handling tmux panes from within Vim!

Features:

- create/kill associated panes
- associate tmuxify to already existing panes
- send visually highlighted lines to the associated pane
- send to pane by prompting for input
- send to pane by setting a run command for the current filetype
- once set, run commands are remembered, but can easily be reset
- all the plugin configuration happens in one dictionary that holds filetypes as
  keys and run commands as values

## Feedback, please!

If you use any of my plugins, star it on github. This is a great way of getting
feedback! Same for issues or feature requests.

Thank you for flying mhi airlines. Get the Vim on!

## Installation

I suggest using tpope's pathogen:

- https://github.com/tpope/vim-pathogen

Afterwards, just clone vim-signify into ~/.vim/bundle/.

## Options

Put these variables into your vimrc for great enjoyment. The shown examples
are also the default values.

```vim
let g:tmuxify_pane_split = '-v'
```

Split either vertically or horizontally. The two possible values are therefore
'-v' and '-h'.

```vim
let g:tmuxify_pane_size = '10'
```

The size of the associated pane.

```vim
let g:tmuxify_run = {}
```

Set run commands for specific filetypes. '%' will be replaced by the full path
to the current buffer.

Example:

```vim
let g:tmuxify_run = {
    \ 'sh': 'bash %',
    \ 'go': 'go build %',
    \}
```

## Mappings

```vim
<leader>mn
```

Executes TxCreate. Creates a new pane and associates with it.

```vim
<leader>mq
```

Executes TxKill. Closes the associated pane.

```vim
<leader>ms
```

Executes TxSend. Prompts for input and sends it to the associated pane. This
mapping also works on visual selections.

```vim
<leader>mr
```

Executes TxRun. Prompts for input if there is no entry in g:tmuxify_run for
the current filetype. '%' will be replaced by the full path to the current
buffer.

```vim
<leader>mt
```

Executes TxSetRunCmd. Change the run command for the current filetype.

```vim
<leader>mp
```

Executes TxSetPane. Associate an already existing pane with tmuxify. Note: You
can use tab completion here.

```vim
<leader>mc
```

Executes TxClear. This is a shortcut for TxSend('clear').

```vim
<leader>mb
```

Executes TxSigInt. Sends an interrupt signal to the associated pane.

## Documentation

`:h tmuxify`

## Author

Marco Hinz `<mh.codebro@gmail.com>`

## License

Copyright © 2013 Marco Hinz. Revised BSD license.
