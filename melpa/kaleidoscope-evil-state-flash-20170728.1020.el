;;; kaleidoscope-evil-state-flash.el --- Flash keyboard LEDs when changing Evil state
;;
;; Copyright (c) 2017 Gergely Nagy
;;
;; Author: Gergely Nagy
;; URL: https://github.com/algernon/kaleidoscope.el
;; Package-Version: 20170728.1020
;; Package-Commit: af4034dcace867c4ede0bce744d5cb888c318f23
;; Version: 0.1.0
;; Package-Requires: ((evil "1.2.12") (kaleidoscope "0.1.0") (s "1.11.0"))
;;
;; This file is NOT part of GNU Emacs.
;;
;;; Commentary:
;;
;; Flash the keyboard LEDs when changing Evil states.
;;
;;; License: GPLv3+

;;; Code:

(require 'kaleidoscope)

;;;; Settings

(defgroup kaleidoscope-evil-state-flash nil
  "Customization group for 'kaleidoscope-evil-state-flash'."
  :group 'kaleidoscope)

(defcustom kaleidoscope-evil-state-flash-insert-state-color "#66CE00"
  "Color to flash when entering the 'insert' state."
  :group 'kaleidoscope-evil-state-flash
  :type 'color)

(defcustom kaleidoscope-evil-state-flash-visual-state-color "#BFBFBF"
  "Color to flash when entering the 'visual' state."
  :group 'kaleidoscope-evil-state-flash
  :type 'color)

(defcustom kaleidoscope-evil-state-flash-normal-state-color "#EFAE0E"
  "Color to flash when entering the 'normal' state."
  :group 'kaleidoscope-evil-state-flash
  :type 'color)

(defcustom kaleidoscope-evil-state-flash-replace-state-color "#D3691E"
  "Color to flash when entering the 'replace' state."
  :group 'kaleidoscope-evil-state-flash
  :type 'color)

(defcustom kaleidoscope-evil-state-flash-duration "1 sec"
  "Duration of the flash."
  :group 'kaleidoscope-evil-state-flash
  :type 'string)

;;;; Helpers

(defun kaleidoscope-evil-state-flash ()
  "Flash the keyboard with colors depending on 'evil-next-state'."
  (when (and (not (equal evil-previous-state evil-next-state))
             (member evil-previous-state '(normal insert visual replace)))
    (let ((color (symbol-value (intern (concat "kaleidoscope-evil-state-flash-"
                                              (symbol-name evil-next-state)
                                              "-state-color")))))
     (kaleidoscope-send-command :led/setAll (kaleidoscope-color-to-rgb color))
     (unless (s-blank? kaleidoscope-evil-state-flash-duration)
       (run-at-time kaleidoscope-evil-state-flash-duration nil
                   (lambda () (kaleidoscope-send-command :led/setAll "0 0 0")))))))

;;;; Main entry point

;;;###autoload
(defun kaleidoscope-evil-state-flash-setup ()
  "Set up hooks to flash the keyboard when changing Evil states."
  (interactive)

  (mapc (lambda (state)
          (add-hook state #'kaleidoscope-evil-state-flash))
        '(evil-insert-state-entry-hook
          evil-visual-state-entry-hook
          evil-replace-state-entry-hook
          evil-normal-state-entry-hook)))

;;;###autoload
(defun kaleidoscope-evil-state-flash-teardown ()
  "Remove the hooks set up by 'kaleidoscope-evil-state-flash-setup'."
  (interactive)

  (mapc (lambda (state)
          (remove-hook state #'kaleidoscope-evil-state-flash))
        '(evil-insert-state-entry-hook
          evil-visual-state-entry-hook
          evil-replace-state-entry-hook
          evil-normal-state-entry-hook)))

(provide 'kaleidoscope-evil-state-flash)

;;; kaleidoscope-evil-state-flash.el ends here
