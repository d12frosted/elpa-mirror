ts-comint.el is a comint mode for Emacs which allows you to run a
compatible typescript repl like Tsun inside Emacs.
It also defines a few functions for sending typescript input to it
quickly.

Usage:
 Put ts-comint.el in your load path
 Add (require 'ts-comint) to your .emacs or ~/.emacs.d/init.el

 Do: `M-x run-ts'
 Away you go.

 You can add  the following couple of lines to your .emacs to take advantage of
 cool keybindings for sending things to the typescript interpreter inside
 of typescript-mode:

  (add-hook 'typescript-mode-hook
            (lambda ()
              (local-set-key (kbd "C-x C-e") 'ts-send-last-sexp)
              (local-set-key (kbd "C-M-x") 'ts-send-last-sexp-and-go)
              (local-set-key (kbd "C-c b") 'ts-send-buffer)
              (local-set-key (kbd "C-c C-b") 'ts-send-buffer-and-go)
              (local-set-key (kbd "C-c l") 'ts-load-file-and-go)))
