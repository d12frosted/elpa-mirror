Provides commands and a minor mode for easily reformatting shell scripts
using the external "shfmt" program.

Call `shfmt-buffer' or `shfmt-region' as convenient.

Enable `shfmt-on-save-mode' in shell script buffers like this:

    (add-hook 'sh-mode-hook 'shfmt-on-save-mode)

or locally to your project with a form in your .dir-locals.el like
this:

    ((sh-mode
      (mode . shfmt-on-save)))

You might like to bind `shfmt-region' or `shfmt-buffer' to a key,
e.g. with:

    (define-key 'sh-mode-map (kbd "C-c C-f") 'shfmt)
