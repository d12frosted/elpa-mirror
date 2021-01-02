
evil-expat extends evil-mode by providing additional ex
commands, which a vim user is likely to be familiar with.

The provided ex commands typically have the same name as
ex commands available in core vim or vim plugins.

Usage:

(require 'evil-expat)

Then the following ex commands will be available:

:remove       remove current file and its buffer; like vim-eunuch's :Remove
:rename       rename or move current file and its buffer; lime vim-eunuch's :Rename
:reverse      reverse visually selected lines
:colorscheme  change Emacs color theme; like vim's ex command of the same name
:diff-orig    get a diff of unsaved changes; like vim's common `:DiffOrig` from the official example vimrc
:gdiff        git-diff current file, requires `magit` and `vdiff-magit`; like vim-fugitive's :Gblame
:gblame       git-blame current file, requires `magit`; like vim-fugitive's :Gblame
:gremove      git remove current file, requires `magit`; like vim-fugitive's :Gremove
:tyank        copy range into tmux paste buffer, requires running under `tmux`; like vim-tbone's :Tyank
:tput         paste from tmux paste buffer, requires running under `tmux`; like vim-tbone's :Tput
