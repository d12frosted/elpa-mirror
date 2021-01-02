
Gitflow plugin for Magit.

(require 'magit-gitflow)
(add-hook 'magit-mode-hook 'turn-on-magit-gitflow)

C-f in magit status buffer will invoke the gitflow popup.
