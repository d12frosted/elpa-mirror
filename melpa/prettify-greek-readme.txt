
 Provides a table of Greek letters and their UTF-8 symbols for
 use by `prettify-symbols-mode'.

 Replaces https://www.emacswiki.org/emacs/PrettyGreek

 `prettify-symbols-alist' is a local variable so either
 setq-default or add in a major mode hook.

 (add-hook 'emacs-lisp-mode-hook
           (lambda ()
             (setq prettify-symbols-alist prettify-greek-lower)
             (prettify-symbols-mode t)))

 recall that alists can be combined with `append'.
