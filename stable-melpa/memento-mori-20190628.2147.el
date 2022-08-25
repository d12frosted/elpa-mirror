;;; memento-mori.el --- Reminder of mortality
;;
;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-memento-mori
;; Package-Version: 20190628.2147
;; Package-Commit: 52f95bd4cf6617b60dc204c9bccb8d8fa17d4f9e
;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))
;; Keywords: help
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Shows your age in the global mode line as a reminder to squander
;; less of your brief time on this earth.
;;
;; Your age is shown with two decimal places so you can witness it
;; increasing every 3-4 days. People commonly regard themselves as N
;; years old until the day they turn N+1 years old. The decimals
;; remind you that this is false comfort: many N-year-olds are already
;; closer to being N+1 years old.
;;
;; Set memento-mori-birth-date, enable memento-mori-mode and reflect.
;;
;;; Code:

;;;###autoload
(defgroup memento-mori
  '((memento-mori-birth-date custom-variable))
  "Reminder of mortality."
  :group 'help)

;;;###autoload
(defcustom memento-mori-birth-date ""
  "*Your birth date in YYYY-MM-DD format."
  :type 'string
  :group 'memento-mori)

(defvar memento-mori-age-string ""
  "Your age shown in the mode line when Memento-Mori mode is on.")

(defun memento-mori-birth-time ()
  "Return your birth time in `encode-time' format.

The birth time is parsed from `memento-mori-birth-date' using
`parse-time-string'. An error is signaled if it is not valid."
  (when (or (null memento-mori-birth-date)
            (equal "" memento-mori-birth-date))
    (error "Birth date not set"))
  (cl-destructuring-bind (_ _ _ day month year _ _ _)
      (parse-time-string (if (stringp memento-mori-birth-date)
                             memento-mori-birth-date ""))
    (unless (and day month year)
      (error "Cannot parse birth date %S" memento-mori-birth-date))
    (encode-time 0 0 0 day month year)))

(defun memento-mori-age ()
  "Return your age in years.

This is a floating point number based on `memento-mori-birth-date'."
  (/ (truncate (float-time
                (time-subtract (current-time) (memento-mori-birth-time))))
     (* 60 60 24 365.2425)))

(defun memento-mori-update ()
  "Update `memento-mori-age-string' based on the current time."
  (setq memento-mori-age-string
        (format " %.2f years old" (memento-mori-age))))

;;;###autoload
(define-minor-mode memento-mori-mode
  "Toggle display of your age in the mode line.

With a prefix argument ARG, enable Memento-Mori mode if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
it if ARG is omitted or nil."
  :global t
  :group 'memento-mori
  (cancel-function-timers #'memento-mori-update)
  (when memento-mori-mode
    (run-at-time "00:00" (* 60 60 24) #'memento-mori-update)
    (memento-mori-update))
  (setq global-mode-string
        (append (delete 'memento-mori-age-string
                        (or global-mode-string '("")))
                (when memento-mori-mode '(memento-mori-age-string)))))

(provide 'memento-mori)

;;; memento-mori.el ends here
