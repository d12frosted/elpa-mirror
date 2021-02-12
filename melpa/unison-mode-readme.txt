Install by putting this file in ~/.emacs.d/elisp/ and this code in your
emacs configuration (~/.emacs):

(add-to-list 'load-path "~/.emacs.d/elisp/")
(autoload 'unison-mode "unison-mode" "my unison mode" t)
(setq auto-mode-alist (append '(("\\.prf$" . unison-mode)) auto-mode-alist))

 Resources used when making this mode:
 http://www.emacswiki.org/emacs/ModeTutorial
 http://www.ergoemacs.org/emacs/elisp_syntax_coloring.html
 http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#tutorial
