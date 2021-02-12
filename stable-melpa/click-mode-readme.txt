`click-mode' is an Emacs major mode for editting Click Modular Router
configuration files. It provides basic syntax highlighting and
indentation, making click files nearly comprehensible!

Install

`click-mode' is available on melpa. You can install it with:

    M-x package-install RET click-mode RET

Then simply open a `.click` file and enjoy!

You may also want to add this to your `.emacs`:

    (add-to-list 'auto-mode-alist '("\\.template\\'" . click-mode))
    (add-to-list 'auto-mode-alist '("\\.inc\\'" . click-mode))
