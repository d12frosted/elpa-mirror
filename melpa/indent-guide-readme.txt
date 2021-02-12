Require this script

  (require 'indent-guide)

and call command "M-x indent-guide-mode".

If you want to enable indent-guide-mode automatically,
call "indent-guide-global-mode" function.

  (indent-guide-global-mode)

Column lines are propertized with "indent-guide-face". So you may
configure this face to make guides more pretty in your colorscheme.

  (set-face-background 'indent-guide-face "dimgray")

You may also change the character for guides.

  (setq indent-guide-char ":")
