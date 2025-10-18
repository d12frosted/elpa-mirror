(eval-after-load "howm-menu" '(progn
  (require 'calfw-howm)
  (calfw-howm-install-schedules)
  (define-key howm-mode-map (kbd "M-C") 'calfw-howm-open-calendar)
))

If you are using Elscreen, here is useful.
(define-key howm-mode-map (kbd "M-C") 'calfw-howm-elscreen-open-calendar)

One can open a standalone calendar buffer by
M-x calfw-howm-open-calendar

You can display a calendar in your howm menu.
%here%(calfw-howm-schedule-inline)
