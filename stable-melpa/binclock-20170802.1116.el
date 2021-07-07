;;; binclock.el --- Display the current time using a binary clock.
;; Copyright 1999-2017 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.11
;; Package-Version: 20170802.1116
;; Package-Commit: 87042230d7f3fe3e9a77fae0dbab7d8f7e7794ad
;; Keywords: games, time, display
;; URL: https://github.com/davep/binclock.el
;; Package-Requires: ((cl-lib "0.5"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; binclock displays the current time using a binary display.

;;; Code:

;; Bits that we need.

(require 'cl-lib)
(require 'easymenu)

;; Customize options.

(defgroup binclock nil
  "binclock - Display the time in binary."
  :group 'games
  :prefix "binclock-")

(defcustom binclock-mode-hook nil
  "Hooks to run when starting `binclock-mode'."
  :type  'hook
  :group 'binclock)

(defcustom binclock-display 'binclock-display-zero-and-one
  "The format for display the binary values."
  :type  '(choice (const :tag "Display using 0's and 1's"
                         binclock-display-zero-and-one)
                  (const :tag "Display as a lisp list"
                         binclock-display-lisp-list)
                  (const :tag "Display as #'s and dots"
                         binclock-display-hash-string))
  :group 'binclock)

(defcustom binclock-clock-type 'binclock-time-bcd
  "Type of clock to display."
  :type  '(choice (const :tag "Binary coded decimal"
                         binclock-time-bcd)
                  (const :tag "HH-MM-SS"
                         binclock-time-hh-mm-ss))
  :group 'binclock)

(defcustom binclock-24hour t
  "Should the time be displayed using 12hour or 24hour clock?"
  :type '(choice (const :tag "Display using 12 hour clock" nil)
                 (const :tag "Display using 24 hour clock" t))
  :group 'binclock)

;; Non-customize variables.

(defvar binclock-buffer-name "*Binary Clock*"
  "Name of the binary clock buffer.")

(defvar binclock-mode-map nil
  "Local keymap for the binary clock.")

(defvar binclock-buffer nil
  "Pointer to the binary clock buffer.")

(defvar binclock-window nil
  "Pointer to the binary clock window.")

(defvar binclock-timer-handle nil
  "Handle for the update timer.")

;; Default keymap.

(unless binclock-mode-map
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map t)
    (define-key map "b" #'binclock-set-bcd)
    (define-key map "h" #'binclock-set-hh-mm-ss)
    (define-key map "l" #'binclock-set-lisp-list)
    (define-key map "q" #'binclock-quit)
    (define-key map "s" #'binclock-set-hash-string)
    (define-key map "t" #'binclock-toggle-24hour)
    (define-key map "z" #'binclock-set-zero-and-one)
    (define-key map "?" #'describe-mode)
    (setq binclock-mode-map map)))

;; Mode definition.

(put 'binclock-mode 'mode-class 'special)

(defun binclock-mode ()
  "A mode for interacting with the binary clock.

The key bindings for `binclock-mode' are:

\\{binclock-mode-map}"
  (kill-all-local-variables)
  (use-local-map binclock-mode-map)
  (setq major-mode       'binclock-mode
        mode-name        "Binary Clock"
        buffer-read-only t
        truncate-lines   t)
  (buffer-disable-undo (current-buffer))
  (run-hooks 'binclock-mode-hook))

;; Main code.

;;;###autoload
(defun binclock ()
  "Display the binary clock."
  (interactive)
  (let ((window-min-height 2)
        (old-window (selected-window)))
    (unless (window-live-p binclock-window)
      (setq binclock-window (split-window-vertically (- (window-height) 2))))
    (setf (selected-window) binclock-window)
    (setq binclock-buffer (switch-to-buffer binclock-buffer-name))
    (unless binclock-timer-handle
      (setq binclock-timer-handle (run-at-time nil 1 #'binclock-timer)))
    (binclock-mode)
    (setf (selected-window) old-window)))

(defun binclock-timer ()
  "Update the binary clock display."
  (with-current-buffer binclock-buffer
    (let ((buffer-read-only nil))
      (setf (buffer-string) "")
      (funcall binclock-display (funcall binclock-clock-type)))))

;; Keyboard response functions.

(defun binclock-quit ()
  "Close the binary clock."
  (interactive)
  (when binclock-timer-handle
    (cancel-timer binclock-timer-handle)
    (setq binclock-timer-handle nil))
  (kill-buffer binclock-buffer)
  (delete-window binclock-window))

(defun binclock-toggle-24hour ()
  "Toggle the value of `binclock-24hour' between 12hour and 24hour."
  (interactive)
  (setq binclock-24hour (not binclock-24hour)))

(defun binclock-set-bcd ()
  "Set the value of `binclock-clock-type' to `binclock-time-bcd'."
  (interactive)
  (setq binclock-clock-type 'binclock-time-bcd))

(defun binclock-set-hh-mm-ss ()
  "Set the value of `binclock-clock-type' to `binclock-time-hh-mm-ss'."
  (interactive)
  (setq binclock-clock-type 'binclock-time-hh-mm-ss))

(defun binclock-set-lisp-list ()
  "Set the value of `binclock-display' to `binclock-display-lisp-list'."
  (interactive)
  (setq binclock-display 'binclock-display-lisp-list))

(defun binclock-set-zero-and-one ()
  "Set the value of `binclock-display' to `binclock-display-zero-and-one'."
  (interactive)
  (setq binclock-display 'binclock-display-zero-and-one))

(defun binclock-set-hash-string ()
  "Set the value of `binclock-display' to `binclock-display-hash-string'."
  (interactive)
  (setq binclock-display 'binclock-display-hash-string))

;; Clock types.

(defun binclock-time-hh-mm-ss ()
  "Get the time, in HH:MM:SS format, as a list of binary lists."
  (let ((now (decode-time)))
    (mapcar #'binclock-to-binary
            (list (binclock-hour-fixup (cl-third now)) (cl-second now) (cl-first now)))))

(defun binclock-time-bcd ()
  "Get the time, in BCD format, as a list of binary values."
  (let* ((now (decode-time))
         (hr  (cl-multiple-value-list (cl-floor (binclock-hour-fixup (cl-third now)) 10)))
         (mn  (cl-multiple-value-list (cl-floor (cl-second now) 10)))
         (sc  (cl-multiple-value-list (cl-floor (cl-first now) 10))))
    (mapcar #'(lambda (n) (binclock-to-binary n 4))
            (list (cl-first hr) (cl-second hr)
                  (cl-first mn) (cl-second mn)
                  (cl-first sc) (cl-second sc)))))

;; Clock displays

(defun binclock-display-zero-and-one (time-list)
  "Display TIME-LIST using 0s and 1s."
  (cl-loop for value in time-list
     do (insert (binclock-boollist-as-string value ?1 ?0))
       (insert "  ")))

(defun binclock-display-lisp-list (time-list)
  "Display TIME-LIST as Lisp lists."
  (cl-loop for value in time-list
     do (insert (prin1-to-string value))
       (insert "  ")))

(defun binclock-display-hash-string (time-list)
  "Display TIME-LIST using '#' and '.'."
  (cl-loop for value in time-list
     do (insert (binclock-boollist-as-string value ?# ?.))
       (insert "  ")))

;; Support functions.

(cl-defun binclock-to-binary (num &optional (bits 8))
  "Convert a positive integer NUM into a binary list. Pad the list out to
BITS bits. BITS is optional and if not supplied defaults to 8."
  (cl-loop for bit downfrom (1- bits) to 0
     collect (not (zerop (logand num (expt 2 bit))))))

(defun binclock-boollist-as-string (list on off)
  "Convert LIST (a list of logical values) to a string.
Use ON for true values and OFF for false values."
  (cl-coerce (cl-loop for bit in list collect (if bit on off)) 'string))

(defun binclock-hour-fixup (hour)
  "Fixup HOUR depending on the setting of `binclock-24hour'."
  (if binclock-24hour
      hour
    (- hour (if (> hour 12) 12 0))))

;; Menu definition.

(easy-menu-define
 binclock-mode-menu binclock-mode-map "Binary clock menu."
 '("Clock"
   ["Toggle 12/24 hour display"       binclock-toggle-24hour    t]
   "---"
   ["Display time in HH:MM:SS format" binclock-set-hh-mm-ss     t]
   ["Display time in BCD format"      binclock-set-bcd          t]
   "---"
   ["Format as lisp lists"            binclock-set-lisp-list    t]
   ["Format output using 0/1"         binclock-set-zero-and-one t]
   ["Format output using #/."         binclock-set-hash-string  t]
   "---"
   ["Close the clock display"         binclock-quit             t]))

(provide 'binclock)

;;; binclock.el ends here
