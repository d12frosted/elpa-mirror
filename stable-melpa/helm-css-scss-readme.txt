Example config

----------------------------------------------------
;; helm from https://github.com/emacs-helm/helm
(require 'helm)

(add-to-list 'load-path "~/.emacs.d/elisp/helm-css-scss")
(require 'helm-css-scss)

;; Allow comment inserting depth at each end of a brace
(setq helm-css-scss-insert-close-comment-depth 2)
;; If this value is t, split window appears inside the current window
(setq helm-css-scss-split-with-multiple-windows nil)
;; Split direction.  'split-window-vertically or 'split-window-horizontally
(setq helm-css-scss-split-direction 'split-window-vertically)

;; Set local keybind map for css-mode / scss-mode
(dolist ($hook '(css-mode-hook scss-mode-hook less-css-mode-hook))
  (add-hook
   $hook (lambda ()
           (local-set-key (kbd "s-i") 'helm-css-scss)
           (local-set-key (kbd "s-I") 'helm-css-scss-back-to-last-point))))

(define-key isearch-mode-map (kbd "s-i") 'helm-css-scss-from-isearch)
(define-key helm-css-scss-map (kbd "s-i") 'helm-css-scss-multi-from-helm-css-scss)
----------------------------------------------------

This program has two main functions

(helm-css-scss)
  Easily jumping between CSS/SCSS selectors powerd by helm.el

(helm-css-scss-insert-close-comment &optional $depth)
  Insert inline comment like " //__ comment" at the next of
  a close brace "}".  If it's aleardy there, update it.
  You can also specify a nest $depth of selector.
