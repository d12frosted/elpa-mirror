The outline-indent.el Emacs package provides a minor mode that enables code
folding based on indentation levels.

The outline-indent.el package is a fast and reliable alternative to the
origami.el and yafolding.el packages. (origami.el and yafolding.el are no
longer maintained, slow, and known to have bugs that impact their reliability
and performance.)

In addition to code folding, outline-indent allows:
- Moving indented subtrees up and down,
- indent/unindent sections to adjust indentation levels,
- customizing the ellipsis,
- inserting a new line with the same indentation level as the current line,
- and other features.

The outline-indent.el package uses the built-in outline-minor-mode, which is
maintained by the Emacs developers and is less likely to be abandoned like
origami.el or yafolding.el. Since outline-indent.el is based on
outline-minor-mode, it's also much much faster than origami.el and
yafolding.el.

Installation:
-------------
(use-package outline-indent
  :ensure t
  :custom
  (outline-indent-ellipsis " ▼ "))

Activation:
-----------
Once installed, the minor mode can be activated using:
  (outline-indent-minor-mode)

Activation using a hook:
------------------------
The minor mode can also be automatically activated for a certain mode. For
example for Python and YAML:
  ;; Python
  (add-hook 'python-mode-hook #'outline-indent-minor-mode)
  (add-hook 'python-ts-mode-hook #'outline-indent-minor-mode)

  ;; YAML
  (add-hook 'yaml-mode-hook #'outline-indent-minor-mode)
  (add-hook 'yaml-ts-mode-hook #'outline-indent-minor-mode)

Adjusting the shift width and default offset
--------------------------------------------
You can adjust the outline-indent-shift-width and
outline-indent-default-offset according to your preferences. While the
default value of 1 is adequate for most modes, setting the appropriate value
ensures that the promote and demote functions correctly adjust the
indentation of blocks.

For example:
  ;; Python
  (dolist (hook '(python-mode python-ts-mode-hook))
    (add-hook hook #'(lambda()
                       (setq-local outline-indent-default-offset 4)
                       (setq-local outline-indent-shift-width 4))))

  ;; YAML
  (dolist (hook '(yaml-mode yaml-ts-mode-hook))
    (add-hook hook #'(lambda()
                       (setq-local outline-indent-default-offset 2)
                       (setq-local outline-indent-shift-width 2)))

Links:
------
- More information about outline-indent (Frequently asked questions, usage...):
https://github.com/jamescherti/outline-indent.el
