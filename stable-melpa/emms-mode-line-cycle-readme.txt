 This is a minor mode for updating `emms-mode-line-string' cyclically within specified width
 with `emms-playing-time-display'.

 It is useful for long track titles.

Further information is available from:
https://github.com/momomo5717/emms-mode-line-cycle  (README.org)


Setup:

(add-to-list 'load-path "/path/to/emms-mode-line-cycle")
(require 'emms-mode-line-cycle)

(emms-mode-line 1)
(emms-playing-time 1)

;; `emms-mode-line-cycle' can be used with emms-mode-line-icon.
(require 'emms-mode-line-icon)
(custom-set-variables '(emms-mode-line-cycle-use-icon-p t))

(emms-mode-line-cycle 1)

User Option:

 + `emms-mode-line-cycle-max-width'
 + `emms-mode-line-cycle-any-width-p'
 + `emms-mode-line-cycle-additional-space-num'
 + `emms-mode-line-cycle-use-icon-p'
 + `emms-mode-line-cycle-current-title-function'
 + `emms-mode-line-cycle-velocity'
