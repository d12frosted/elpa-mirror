Use the command `phpcbf' to reformat the current buffer using
the "phpcbf" program.  To do this automatically on save, add
the following to your Emacs startup file:

(add-hook 'php-mode-hook 'phpcbf-enable-on-save)

Please check the GitHub
(https://github.com/nishimaki10/emacs-phpcbf)
for more information.
