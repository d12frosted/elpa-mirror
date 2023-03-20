;;; transient-extras-lp.el --- A transient interface to lp  -*- lexical-binding:t -*-
;;
;; Author: Al Haji-Ali <abdo.haji.ali@gmail.com>
;; URL: https://github.com/haji-ali/transient-extras.git
;; Package-Version: 20230317.1118
;; Package-Commit: a9edac72cc0e29a8cae4340bcb63a5eae3eac130
;; Version: 1.0.1
;; Package-Requires: ((emacs "28.1") (transient-extras "1.0.0"))
;; Keywords: convenience
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;; This package provides a simple transient menu with common options for `lp'.
;;
;; Typical usage:
;;
;; (require 'transient-extras-lp)
;;
;; (with-eval-after-load 'dired
;;   (define-key
;;     dired-mode-map
;;     (kbd "C-c C-p") #'transient-extras-lp-menu))
;; (with-eval-after-load 'pdf-tools
;;   (define-key
;;     pdf-misc-minor-mode-map
;;     (kbd "C-c C-p") #'transient-extras-lp-menu))
;;
;; Or simply call `transient-extras-lp-menu' to print the current buffer or the
;; selected files is selected in `dired'.

;;; Code:


(require 'transient)
(require 'transient-extras)

(transient-define-argument transient-extras-lp--orientation ()
  :description "Print Orientation"
  :class 'transient-extras-exclusive-switch
  :key "o"
  :argument-format "-oorientation-requested=%s"
  :argument-regexp "\\(-oorientation-requested=\\(4\\|5\\|6\\)\\)"
  :choices '(("4" . "90°(landscape)")
             ("5" . "-90°")
             ("6" . "180°")))

(transient-define-argument transient-extras-lp--quality ()
  :description "Print Quality"
  :class 'transient-extras-exclusive-switch
  :key "l"
  :argument-format "-oprint-quality=%s"
  :argument-regexp "\\(-oprint-quality=\\(3\\|4\\|5\\)\\)"
  :choices '(("3" . "draft")
             ("4" . "normal")
             ("5" . "best")))

(transient-define-argument transient-extras-lp--per-page ()
  :description "Per page"
  :class 'transient-extras-exclusive-switch
  :key "C"
  :argument-format "-onumber-up=%s"
  :argument-regexp "\\(-onumber-up=\\(2\\|4\\|6\\|9\\|16\\)\\)"
  :choices '("2" "4" "6" "9" "16"))

(transient-define-argument transient-extras-lp--media ()
  :description "Page size"
  :class 'transient-extras-exclusive-switch
  :key "m"
  :argument-format "-omedia=%s"
  :argument-regexp "\\(-omedia=\\(a4\\|letter\\|legal\\)\\)"
  :choices '("a4" "letter" "legal"))

(transient-define-argument transient-extras-lp--sides ()
  :description "Sides"
  :class 'transient-extras-exclusive-switch
  :key "s"
  :argument-format "-osides=%s"
  :argument-regexp "\\(-osides=\\(one-sided\\|two-sided-long-edge\\|two-sided-\
short-edge\\)\\)"
  :choices '("one-sided" "two-sided-long-edge" "two-sided-short-edge"))

(defvar transient-extras-lp-executable
  (list (executable-find "lp"))
  "\"lp\" executable (with additional fixed args).")

(defvar transient-extras-lp-get-printers-cmd
  (list (executable-find "lpstat") "-a")
  "Command (with args) to get list of printers.")

(defvar transient-extras-lp-saved-options nil
  "List of options that will be passed by default to `lp'.")

(defvar transient-extras-lp-dry-run nil
  "If non-nil, lp commands are not actually issued.")

(defun transient-extras-lp--read-printer (prompt initial-input history)
  "PROMPT for printer name, with INITIAL-INPUT.  HISTORY, if present, is respected."
  (let ((preprocess-lines-fun
         (lambda (x)
           ;; Accept only the first word in each line
           (mapcar
            (lambda (y)
              (let ((ind (string-match "[[:space:]]" y)))
                (if ind
                    (substring y nil ind)
                  y)))
            x))))
    (completing-read
     prompt
     (funcall preprocess-lines-fun
              (split-string
               (with-temp-buffer
                 (apply #'call-process
                        (car transient-extras-lp-get-printers-cmd)
                        nil t nil
                        (cdr transient-extras-lp-get-printers-cmd))
                 (buffer-string))
               "\n" 'omit-nulls))
     nil nil initial-input history)))

(defun transient-extras-lp--read-pages (prompt initial-input history)
  "PROMPT for pages that will be printed, using INITIAL-INPUT and HISTORY.

Get pages count from `pdf-info-number-of-pages' when defined and
in `pdf-mode' and display the maximum in the prompt."
  (read-string
   (if (and (fboundp 'pdf-info-number-of-pages)
            (derived-mode-p 'pdf-view-mode))
       (format "%s[max %d]: " prompt (pdf-info-number-of-pages))
     prompt)
   initial-input history))

(defun transient-extras-lp (buf-or-files &optional args)
  "Call `lp' with list of files or a buffer.

BUF-OR-FILES is a buffer or a list of files.  ARGS are the
arguments that should be passed to `lp'"
  (interactive (list (transient-extras--get-default-file-list-or-buffer)))
  (unless (or (bufferp buf-or-files)
              (listp buf-or-files))
    (user-error "Wrong first argument to `transient-extras-lp'"))
  (unless  transient-extras-lp-executable
    (error "No print program available"))
  (let* ((cmd (append transient-extras-lp-executable
                      args
                      (and (listp buf-or-files)
                           buf-or-files)))
         (process (unless transient-extras-lp-dry-run
                    (make-process
                     :name "printing"
                     :buffer nil
                     :connection-type 'pipe
                     :command cmd))))
    (when (and (not transient-extras-lp-dry-run)
               (bufferp buf-or-files))
      ;; Send the buffer content to the process
      (process-send-string process
                           (with-current-buffer buf-or-files
                             (buffer-string)))
      (process-send-eof process))
    (message "Print job started: %s"
             (mapconcat #'identity cmd " "))))

(defun transient-extras-lp--save-options (args)
  "Save printer ARGS as default.

The options, taken from `transient' by default, are saved so
that the next time the `transient' menu is displayed these
options are automatically selected."
  (interactive (list (cdr (transient-args 'transient-extras-lp-menu))))
  (setq transient-extras-lp-saved-options args)
  (message "Saved"))

(defun transient-extras-lp--do-print (args)
  "Call `transient-extras-lp' with `transient' ARGS."
  (interactive (list (transient-args 'transient-extras-lp-menu)))
  ;; NOTE: This is relying on the order. This works with latest `transient'
  ;; but future updates might break this
  (transient-extras-lp (car args) (cdr args)))

(transient-define-prefix transient-extras-lp-menu (filename)
  "Call `lp' with various options."
  :init-value (lambda (obj)
                (oset obj value transient-extras-lp-saved-options))
  :man-page "lp"

  [(transient-extras-file-list-or-buffer)]

  [["Argument"
    ("n" "copies" "-n" :always-read t
     :class transient-option
     :prompt "Number of copies? ")
    ("p" "Pages" "-P" :always-read t
     :class transient-option
     :prompt "Pages? "
     :reader transient-extras-lp--read-pages)
    ("d" "Printer" "-d"
     :prompt "Printer? "
     :class transient-option
     :always-read t :reader transient-extras-lp--read-printer)]

   ["Options"
    (transient-extras-lp--sides)
    (transient-extras-lp--media)
    (transient-extras-lp--per-page)
    (transient-extras-lp--orientation)
    (transient-extras-lp--quality)
    ("f" "Fit to page" "-ofit-to-page")
    ("x" "Extra options" "-o"
     :class transient-option
     :always-read t)]]

  [["Commands"
    ("C-c C-c" "Print"
     transient-extras-lp--do-print
     :transient nil)]

   ["" ("C-c C-s" "Save options"
        transient-extras-lp--save-options
        :transient t)]])

(provide 'transient-extras-lp)

;;; transient-extras-lp.el ends here
