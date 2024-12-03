This package teaches `outline-minor-mode' to highlight section
headings, *without* also highlighting top-level s-expressions.

To highlight only section headings forgo setting the built-in
`outline-minor-mode-highlight' to `append', or another non-nil
value.  Instead enable the equivalent feature provided by this
package:

  (use-package outline-minor-faces
    :after outline
    :config (add-hook 'outline-minor-mode-hook
                      #'outline-minor-faces-mode))

For non-lisp major modes the highlighting provided by this package
and by the built-in support is essentially the same, i.e., the first
lines of top-level expressions *are* highlighted.

This package also defines separate faces for use in the minor mode.
These faces are what gave this package its name, but nowadays they
inherit from the built-in faces by default, and are preserved mostly
for historic reasons, i.e., to avoid having to rename this package.

To further improve the appearance of collapsed sections, check out
the `backline' package.
