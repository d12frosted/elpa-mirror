This library configures Magit and Evil to play well with each
other. For some background see https://github.com/magit/evil-magit/issues/1.

Installation and Use
====================

Everything is contained in evil-magit.el, so you may download and load that file
directly. The recommended method is to use MELPA via package.el (`M-x
package-install RET evil-magit RET`).

Evil and Magit are both required. After requiring those packages, the following
will setup the new key bindings for you.

;; optional: this is the evil state that evil-magit will use
;; (setq evil-magit-state 'motion)
(require 'evil-magit)

Use `evil-magit-revert` to revert changes made by evil-magit to the default
evil+magit behavior.

See the README at https://github.com/justbur/evil-magit for a table
describing the key binding changes.
