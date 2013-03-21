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

I suggest using tpope's plain and awesome pathogen:

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

## Documentation

`:h tmuxify`

## Author

Marco Hinz `<mh.codebro@gmail.com>`

## License

Copyright © 2013 Marco Hinz. Revised BSD license.
