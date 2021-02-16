Simple delayed text evaluation for the mode-line.

; Usage

(defvar my-word '(:eval (count-words (point-min) (point-max))))
(setq-default mode-line-format
  (list "Word Count " '(:eval (mode-line-idle 1.0 my-word "?" :interrupt t))))
