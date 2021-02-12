Provides font-locking, indentation support, and navigation for Crystal code.

If you're installing manually, you should add this to your .emacs
file after putting it on your load path:

   (autoload 'crystal-mode "crystal-mode" "Major mode for crystal files" t)
   (add-to-list 'auto-mode-alist '("\\.cr$" . crystal-mode))
   (add-to-list 'interpreter-mode-alist '("crystal" . crystal-mode))

Still needs more docstrings; search below for TODO.
