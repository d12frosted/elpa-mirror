
This package adds the ability to sync org-mode tasks with
Toodledo, a powerful web-based todo list manager that welcomes 3rd
party integrations.  (See http://www.toodledo.com/)

This version of `org-toodledo' utilizes version 2.0 of the Toodledo API.

See https://github.com/christopherjwhite/org-toodledo


; Installation:

1. Required Emacs package:
      * `request'

2. Put this file in your load path, byte compile the file for best
   performance, see `byte-compile-file'.

3. Put the following in your .emacs:

   (push "<path-to-this-file>" load-path)
   (require 'org-toodledo)
   (setq org-toodledo-userid "<toodledo-userid>")      << *NOT* your email!
   (setq org-toodledo-password "<toodled-password>")
   (setq org-toodledo-file "<org file name>")
   ;; Useful key bindings for org-mode
   (add-hook 'org-mode-hook
          (lambda ()
            (local-unset-key "\C-o")
            (local-set-key "\C-od" 'org-toodledo-mark-task-deleted)
            (local-set-key "\C-os" 'org-toodledo-sync)）
   (add-hook 'org-agenda-mode-hook
          (lambda ()
            (local-unset-key "\C-o")
            (local-set-key "\C-od" 'org-toodledo-agenda-mark-task-deleted)）
