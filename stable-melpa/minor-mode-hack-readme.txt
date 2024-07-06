
A hack of minor-modes.

`raise-minor-mode-map-alist' / `lower-minor-mode-map-alist' - resolve `minor-mode-map-alist' conflict

Example:
(raise-minor-mode-map-alist 'view-mode)
raises priority of `view-mode-map'.

; Commands

Below are complete command list:

 `show-minor-mode-map-priority'
   Show priority of `minor-mode-map-alist'.
