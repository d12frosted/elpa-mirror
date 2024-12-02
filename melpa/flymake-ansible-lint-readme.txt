The flymake-ansible-lint package provides a Flymake backend for ansible-lint,
enabling real-time syntax and style checking for Ansible playbooks and roles
within Emacs.

(This package can also work with Flycheck: simply use the `flymake-flycheck`
package, which allows any Emacs Flymake backend to function as a Flycheck
checker.)

Installation from MELPA:
------------------------
(use-package flymake-ansible-lint
  :ensure t
  :commands flymake-ansible-lint-setup
  :hook (((yaml-ts-mode yaml-mode) . flymake-ansible-lint-setup)
         ((yaml-ts-mode yaml-mode) . flymake-mode)))

Customizations:
---------------
You can configure ansible-lint parameters using the flymake-ansible-lint-args
variable:
  (setq flymake-ansible-lint-args '("--offline"
                                    "-x" "run-once[play],no-free-form"))

Links:
------
- ansible-lint.el @GitHub:
  https://github.com/jamescherti/flymake-ansible-lint.el
