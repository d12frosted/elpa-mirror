Provides commands and a minor mode for easily reformatting Nix code
using the external "nixpkgs-fmt" program.

Call `nixpkgs-fmt-buffer' or `nixpkgs-fmt-region' as convenient.

Enable `nixpkgs-fmt-on-save-mode' in Nix buffers like this:

    (add-hook 'nix-mode-hook 'nixpkgs-fmt-on-save-mode)

or locally to your project with a form in your .dir-locals.el like
this:

    ((nix-mode
      (mode . nixpkgs-fmt-on-save)))

You might like to bind `nixpkgs-fmt-region' or `nixpkgs-fmt-buffer' to a key,
e.g. with:

    (define-key 'nix-mode-map (kbd "C-c C-f") 'nixpkgs-fmt)
