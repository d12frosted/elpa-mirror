
Automatically show hidden emphasis markers at point in org mode.

This is useful for editing org file when `org-hide-emphasis-markers' is on.

In org mode, hide emphasis markers can make reading nice, but not good for editing.
Here provide a mode to let hidden markers auto expose when the cursor on, and auto
hide when cursor leave.

Install this packge, then use it by turning on the mode:

  (add-hook 'org-mode-hook (lambda () (org-expose-emphasis-markers 'paragraph)))
