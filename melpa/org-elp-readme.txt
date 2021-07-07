
Preview latex equations in org mode in a separate buffer while
editing.  Possible configurations:

To set the fraction of the window taken up by the previewing buffer
(setq org-elp-split-fraction 0.2)

To adjust buffer name
(setq org-elp-buffer-name "*Equation Live*")

To adjust idle time to run latex preview
(setq org-elp-idle-time 0.5)

Launch or deactivate the previewing with
M-x org-elp-mode
