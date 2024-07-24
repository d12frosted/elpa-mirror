Provides commands and a minor mode for easily reformatting Nix code
using the external "nixfmt" program.

Call `nixfmt-buffer' or `nixfmt-region' as convenient.

Enable `nixfmt-on-save-mode' in Nix buffers like this:

    (add-hook 'nix-mode-hook 'nixfmt-on-save-mode)

or locally to your project with a form in your .dir-locals.el like
this:

    ((nix-mode
      (mode . nixfmt-on-save)))

You might like to bind `nixfmt-region' or `nixfmt-buffer' to a key,
e.g. with:

    (define-key 'nix-mode-map (kbd "C-c C-f") 'nixfmt)
