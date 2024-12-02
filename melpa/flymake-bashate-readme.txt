The flymake-bashate Emacs package provides a Flymake backend for bashate,
enabling real-time style checking for Bash shell scripts within Emacs.

(Bashate is a Bash script syntax checker, enforcing a set of style and syntax
rules to ensure that your scripts are consistent, clean, and easy to read.)

(This package can also work with Flycheck: simply use the `flymake-flycheck`
package, which allows any Emacs Flymake backend to function as a Flycheck
checker.)*

Installation from MELPA:
------------------------
(use-package flymake-bashate
  :ensure t
  :commands flymake-bashate-setup
  :hook (((bash-ts-mode sh-mode) . flymake-bashate-setup)
         ((bash-ts-mode sh-mode) . flymake-mode))
  :custom
  (flymake-bashate-max-line-length 80))

Customizations:
---------------
To make bashate ignore specific Bashate rules, such as E003 (ensure all
indents are a multiple of 4 spaces) and E006 (check for lines longer than 79
columns), set the following variable:
  (setq flymake-bashate-ignore "E003,E006")

To define the maximum line length for Bashate to check:
  (setq flymake-bashate-max-line-length 80)

To change the path or filename of the Bashate executable:
  (setq flymake-bashate-executable "/opt/different-directory/bin/bashate")

Links:
------
- flymake-bashate.el @GitHub:
  https://github.com/jamescherti/flymake-bashate.el
