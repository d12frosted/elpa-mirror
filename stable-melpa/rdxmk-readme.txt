rdxmk provides a few tools to make redox development easier in Emacs.
rdxmk provides a few convenience functions for building redox:
You can run make with no arguments (M-x rdxmk-make-narg RET), make with arguments
(M-x rdxmk-make-warg RET arg RET), run the built in rdxmk-make-qemu and rdxmk-make-all, and use cookbook
(M-x Rdxmk-Cookbook RET package RET option RET.)
Finally, you can stop Emacs from inserting files all over your redox/ directory by
going to rdxmk's customization group with `M-x customize-group RET rdxmk RET`
and setting `lockfile-no-pollute` to t. For more information, go to the
documentation with `C-h i`

; Installation

For a manual installation, clone the repo in your ~/.emacs.d/, add
(add-to-list 'load-path "~/.emacs.d/rdxmk")
(load "rdxmk")
to your startup file, and install rdxmk.info to your root
dir file using the shell tool, `install-info`.
For faster load time, run `C-u M-x byte-recompile-directory`
and run it on tne ~/.emacs.d/rdxmk/ directory.
If this becomes available on MELPA, simply add http://melpa.org/packages
to your Package Archives under `M-x customize-group RET package RET` and
install rdxmk using `M-x package-install RET`
