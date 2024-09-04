Casual Agenda is an opinionated Transient user interface for Org Agenda.

INSTALLATION
(require 'casual-agenda) ; optional
(keymap-set org-agenda-mode-map "C-o" #'casual-agenda-tmenu)
(keymap-set org-agenda-mode-map "M-j" #'org-agenda-clock-goto) ; optional
(keymap-set org-agenda-mode-map "J" #'bookmark-jump) ; optional

Alternately install using `use-package':
(use-package casual-agenda
  :ensure nil
  :bind (:map
         org-agenda-mode-map
         ("C-o" . casual-agenda-tmenu)
         ("M-j" . org-agenda-clock-goto) ; optional
         ("J" . bookmark-jump)) ; optional
  :after (org-agenda))

This package requires that the built-in packages `org' and `transient' be
upgraded. By default, `package.el' will not upgrade a built-in package
without customization. Set the customizable variable
`package-install-upgrade-built-in' to `t' to allow upgrading of built-in
packages. For more details, please refer to the "Install" section on this
project's repository web page.
