'zlc.el' provides zsh like completion system to Emacs. That is, zlc
allows you to select candidates one-by-one by pressing `TAB'
repeatedly in minibuffer, shell-mode, and so forth. In addition,
with arrow keys, you can move around the candidates.

To enable zlc, just put the following lines in your Emacs config.

(require 'zlc)
(zlc-mode t)

; Customization:

To simulate zsh's `menu select', which allows you to move around
candidates, zlc arranges movement commands for 4 directions. If you
want to use these commands, bind them to certain keys in your Emacs
config.

(let ((map minibuffer-local-map))
  ;;; like menu select
  (define-key map (kbd "<down>")  'zlc-select-next-vertical)
  (define-key map (kbd "<up>")    'zlc-select-previous-vertical)
  (define-key map (kbd "<right>") 'zlc-select-next)
  (define-key map (kbd "<left>")  'zlc-select-previous)

  ;;; reset selection
  (define-key map (kbd "C-c") 'zlc-reset)
  )
