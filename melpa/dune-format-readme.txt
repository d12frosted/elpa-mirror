Call `dune-format', `dune-format-buffer' or `dune-format-region' as
convenient.

Enable `dune-format-on-save-mode' in `dune-mode' buffers like this:

    (add-hook 'dune-mode-hook 'dune-format-on-save-mode)

or locally to your project with a form in your .dir-locals.el like
this:

    ((dune-mode
      (mode . dune-format-on-save)))
