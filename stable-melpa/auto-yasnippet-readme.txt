Setup:

1. Download yasnippet from https://github.com/capitaomorte/yasnippet
   and set it up.

2. Put this file into your elisp folder.

3. In your .emacs file:
    (require 'auto-yasnippet)
    (global-set-key (kbd "H-w") #'aya-create)
    (global-set-key (kbd "H-y") #'aya-expand)
