`flymake-margin` is a minor mode that aims to get flymake out of
the fringe and into the margin, hence making it visible on Terminal
Emacs.

IMPORTANT: Emacs 30 will have this feature built-in, so only use it
           if stuck with Emacs < 30.

To enable it, install the package and add it to your load path:

    (require 'flymake-margin)
    (flymake-margin-mode t)

There are several customizable options you can find:

    M-x customize-group flymake-margin
