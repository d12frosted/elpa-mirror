
popterm.el — a terminal toggler merging three established patterns:

 * Centered child-frame popup  (seagle0128/init-shell.el)
 * Multi-backend, named instances  (justinlime/toggle-term.el)
 * Smart auto-cd, TRAMP-awareness, scope  (jixiuf/vterm-toggle.el)

Display methods:
  posframe   — centered child frame (requires posframe.el)
  window     — bottom split window
  fullscreen — full-frame buffer switch

Backends (auto-detected at runtime, no hard dependency):
  vterm / ghostel / eat / shell / eshell

Quick start:
  (use-package popterm
    :bind (("C-`"  . popterm-toggle)
           ("C-~"  . popterm-toggle-cd)
           ([f9]   . popterm-window-toggle))
    :config
    (setq popterm-backend        'vterm
          popterm-display-method 'posframe
          popterm-scope          'project
          popterm-auto-cd        t))
