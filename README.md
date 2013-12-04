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

__NOTE__: This plugin needs tmux 1.6 with a certain patch level. You're safe
with versions 1.7+.

## Feedback, please!

If you use any of my plugins, star it on github. This is a great way of getting
feedback! Same for issues or feature requests.

Thank you for flying mhi airlines. Get the Vim on!

## Installation

If you have no preferred installation method, I suggest using tpope's pathogen:

1. git clone https://github.com/tpope/vim-pathogen ~/.vim/bundle/vim-pathogen
1. mkdir -p ~/.vim/autoload && cd ~/.vim/autoload
1. ln -s ../bundle/vim-pathogen/autoload/pathogen.vim

Afterwards, installing tmuxify is as easy as pie:

2. git clone https://github.com/mhinz/vim-tmuxify ~/.vim/bundle/vim-tmuxify
2. start Vim
2. :Helptags
2. :h tmuxify

## Options

Put these variables into your vimrc for great enjoyment. The shown examples
are also the default values.

```vim
let g:tmuxify_custom_command = 'tmux split-window -d'
```

Use this option if you want to overwrite that default command for creating a new
pane.

_(Examples are given in `:h tmuxify-options`)_

```vim
let g:tmuxify_map_prefix = '<leader>m'
```

What to start mappings with. Set it to `''` to disable mappings.

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

Executes TxClear. Sends ctrl+l to the associated pane.

```vim
<leader>mb
```

Executes TxSigInt. Sends ctrl+c to the associated pane.

## Documentation

`:h tmuxify`

## Author

Marco Hinz `<mh.codebro@gmail.com>`

## License

Copyright © Marco Hinz. Distributed under the same terms as Vim itself. See
`:help license`.
