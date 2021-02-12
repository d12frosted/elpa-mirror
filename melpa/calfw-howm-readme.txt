(eval-after-load "howm-menu" '(progn
  (require 'calfw-howm)
  (cfw:install-howm-schedules)
  (define-key howm-mode-map (kbd "M-C") 'cfw:open-howm-calendar)
))

If you are using Elscreen, here is useful.
(define-key howm-mode-map (kbd "M-C") 'cfw:elscreen-open-howm-calendar)

One can open a standalone calendar buffer by
M-x cfw:open-howm-calendar

You can display a calendar in your howm menu.
%here%(cfw:howm-schedule-inline)
