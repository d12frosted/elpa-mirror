;;; immutant-server.el --- Run your Immutant server in Emacs
;;
;; Copyright (c) 2013-2014 David Leatherman
;;
;; Author: David Leatherman <leathekd@gmail.com>
;; URL: http://www.github.com/leathekd/immutant-server.el
;; Package-Version: 20140311.2208
;; Package-Commit: 2a21e65588acb6a976f2998e30b21fdabdba4dbb
;; Version: 1.2.0

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This file contains the code for running Immutant and collecting the
;; console output.  It contains some utility functions to make it
;; easier to browse the output.

;; To use add the following to your init.el
;; (require 'immutant-server)
;; and then run
;; M-x immutant-server-start

;; History

;; 1.2.1
;;
;; - Marked the immutant-server-start arg as optional
;;
;; - Added immutant-server-default-directory to control where Immutant
;;   starts

;; 1.2.0
;;
;; - Added additional notice regexes to
;;   `immutant-server-notice-regexp-alist'. Thanks, tcrawley.
;;
;; - Added thingatpt require.  Thanks, syohex.
;;
;; - Added ability to modify server command in `immutant-server-start'
;;   with C-u prefix.  Thanks, tcrawley.
;;
;; - Added docs for the 'C-c C-s' binding for `immutant-server-start'
;;
;; - Tweaked one of the notice regexes so it wouldn't override the
;;   ERROR face when there is an error while starting Immutant.

;; 1.1.2
;;
;; - Require ansi-color

;; 1.1.1
;;
;; - Added highlighting for various specific log messages. Initially,
;;   these are all about when the server is up or services deployed.
;;   See `immutant-server-notice-regexp-alist' for details.
;;
;; - Fixed a bug with the Immutant Stopped message appearing
;;   off-screen.
;;
;; - Tweaked faces (removed bold on inherited faces), change info
;;   color
;;
;; - Fix bug in error navigation
;;
;; - Add C-c C-s keybinding to start Immutant

;; 1.0.1
;;
;; - Fixed some byte compile warnings
;;
;; - Added an autoload to immutant-server-start

;; 1.0.0
;;
;; - Initial release

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

 ;; Required libs

(require 'ansi-color)
(require 'thingatpt)

 ;; Internal vars

(defvar immutant-server-buffer "*immutant*"
  "The buffer in which the Immutant console output will be printed")

(defvar immutant-server-default-directory
  "~/.immutant/"
  "The default buffer from which to launch Immutant.  This is
useful to prevent Immutant from putting things like Infinispan
cache files into whatever default-directory happens to be active
when you run `immutant-server-start'.")

(defvar immutant-server-error-count 0
  "An ongoing count of errors encoutered.  Printed in the mode line.")

(defvar immutant-server-mode-name ""
  "Placeholder for the mode line.
Filled in by `immutant-server-update-mode-line'")

(defvar immutant-server-levels
  '(("TRACE" . immutant-server-trace-face)
    ("DEBUG" . immutant-server-debug-face)
    ("INFO" . immutant-server-info-face)
    ("WARN" . immutant-server-warn-face)
    ("ERROR" . immutant-server-error-face)
    ("FATAL" . immutant-server-fatal-face))
  "An alist of all of the log levels to their associated faces")

(defvar immutant-server-notice-regexp-alist
  '(("started in.*Started [[:digit:]]+ of [[:digit:]]+ servi"
     . immutant-server-notice-face)
    ("stopped in [[:digit:]]+ms" . immutant-server-notice-face)
    ("\\(Starting\\|Stopped\\) deployment.*runtime-name"
     . immutant-server-notice-face)
    ("Deployed.*runtime-name" . immutant-server-notice-face)
    ("nREPL bound to" . immutant-server-notice-face)
    ("\\[immutant.messaging.core].*\\(Starting\\|Stopping\\|already exists\\)"
     . immutant-server-notice-face)
    ("\\(Uns\\|S\\)cheduling job" . immutant-server-notice-face)
    ("Creating cache:" . immutant-server-notice-face)
    ("St\\(art\\|opp\\)ing daemon:" . immutant-server-notice-face)
    ("St\\(art\\|opp\\)ing nrepl for" . immutant-server-notice-face)
    ("Creating.*listener for" . immutant-server-notice-face))
  "An alist of various other lines worth highlighting.")

(defvar immutant-server-error-regexp " ERROR \\| FATAL "
  "Regexp used to count errors and to navigate between them.")

(defvar immutant-server-log-line-regexp
  (mapconcat 'car immutant-server-levels "\\|")
  "Regexp used to identify a line of log output.")

(defvar immutant-server-output-divider
  "\n=========================================================================\n"
  "Divider characters to print when Immutant starts or stops.")

(defgroup immutant-server nil
  "Immutant-server mode properties"
  :group 'external)

(defgroup immutant-server-faces nil
  "Immutant-server mode faces"
  :group 'immutant-server)

 ;; Faces

(defface immutant-server-fatal-face
  '((t :foreground "red"))
  "Face to use for FATAL messages"
  :group 'immutant-server-faces)

(defface immutant-server-error-face
  '((t :inherit 'error :weight normal))
  "Face to use for ERROR messages"
  :group 'immutant-server-faces)

(defface immutant-server-warn-face
  '((t :inherit 'warning :weight normal))
  "Face to use for WARN messages"
  :group 'immutant-server-faces)

(defface immutant-server-info-face
  '((((background light)) (:foreground "DimGray"))
    (((background dark)) (:foreground "gray")))
  "Face to use for INFO messages"
  :group 'immutant-server-faces)

(defface immutant-server-debug-face
  '((((background light)) (:foreground "DimGray"))
    (((background dark)) (:foreground "DimGray")))
  "Face to use for DEBUG messages"
  :group 'immutant-server-faces)

(defface immutant-server-trace-face
  '((((background light)) (:foreground "DimGray"))
    (((background dark)) (:foreground "DimGray")))
  "Face to use for TRACE messages"
  :group 'immutant-server-faces)

(defface immutant-server-notice-face
  '((((background light)) (:foreground "DeepSkyBlue"))
    (((background dark)) (:foreground "DeepSkyBlue")))
  "Face to use for lines matching the regexps in the default
`immutant-server-notice-regexp-alist'"
  :group 'immutant-server-faces)

 ;; User customizable settings

(defcustom immutant-server-bury-on-quit t
  "Bury the buffer when running `immutant-server-quit-buffer'
t to bury, nil to kill."
  :group 'immutant-server
  :type 'boolean)

(defcustom immutant-server-clear-output-on-start t
  "Erase the `immutant-server-buffer' when starting Immutant"
  :group 'immutant-server
  :type 'boolean)

(defcustom immutant-server-executable
  "~/.immutant/current/jboss/bin/standalone.sh"
  "Command to run to start Immutant.
Defaults to ~/.immutant/current/jboss/bin/standalone.sh"
  :group 'immutant-server
  :type 'string)

 ;; Internal functions

(defun immutant-server-running-p ()
  "Predicate that checks to see if the `immutant-server-buffer' has a
running process."
  (if (get-buffer-process immutant-server-buffer)
      t
    nil))

(defun immutant-server-update-mode-line ()
  "Updates the mode line with Immutant's process status and current
error count"
  (setq immutant-server-mode-name
        (format "immutant-server:%s%s"
                (if (immutant-server-running-p) "running" "stopped")
                (if (< 0 immutant-server-error-count)
                    (format " [%s]" (propertize
                                     (format "%s" immutant-server-error-count)
                                     'face 'immutant-server-error-face))
                  ""))))

(defun immutant-server-add-face-to-region (start end level)
  "Colorize the region based on the given level."
  (add-text-properties start
                       end
                       `(face ,(cdr (assoc level immutant-server-levels)))))

(defun immutant-server-add-faces (start end)
  "Colorize all of the lines in the region based on the levels for
each log message."
  (save-match-data
    (save-restriction
      (goto-char start)
      (immutant-server-previous-line)
      (immutant-server-previous-line)
      (narrow-to-region (point) (point-max))

      (let ((case-fold-search nil)
            level previous-point)
        (while (search-forward-regexp immutant-server-log-line-regexp
                                      nil t)
          (unless (null level)
            (immutant-server-add-face-to-region previous-point
                                                (line-beginning-position)
                                                level))
          (setq level (word-at-point))
          (setq previous-point (line-beginning-position)))
        (unless (null level)
          (immutant-server-add-face-to-region previous-point
                                              (point-max)
                                              level))
        ;; colorize special notice lines
        (dolist (pair immutant-server-notice-regexp-alist)
          (goto-char (point-min))
          (while (search-forward-regexp (car pair) (point-max) t)
            (add-text-properties (point-at-bol) (point-at-eol)
                                 `(face ,(cdr pair)))))))))

(defun immutant-server-count-errors-in-region (start end)
  "Count the instances of `immutant-server-error-regexp' in the
region"
  (let ((search-upper-case t))
    (count-matches immutant-server-error-regexp start end)))

(defun immutant-server-insert-text (text)
  (with-current-buffer immutant-server-buffer
    (let ((at-bottom (equal (point-max) (point)))
          (buffer immutant-server-buffer)
          (inhibit-read-only t))
      (save-excursion
        (goto-char (point-max))
        (let ((pt (point)))
          (insert text)
          ;; get to the beginning of the line
          (ansi-color-filter-region pt (point-max))
          (goto-char pt)
          (unless (equal pt (line-beginning-position))
            (goto-char (line-beginning-position)))
          ;; Do all the things to make the output and mode line
          ;; pretty
          (let ((start (point))
                (end (point-max)))
            (immutant-server-add-faces start end)
            (setq immutant-server-error-count
                  (immutant-server-count-errors-in-region start end)))
          (immutant-server-update-mode-line)))
      (when at-bottom
        (goto-char (point-max))
        (when (get-buffer-window immutant-server-buffer 'visible)
          (with-selected-window
              (get-buffer-window immutant-server-buffer 'visible)
            (recenter -1)))))))

(defun immutant-server-proc-filter (proc output)
  "Process filter that will print and colorize the output of the
Immutant process.  It is also responsible for keeping the error count
up to date as well as keeping the point at the bottom (if it was
already at the bottom)."
  (when (buffer-live-p (process-buffer proc))
    (immutant-server-insert-text output)))

(defun immutant-server-sentinel (proc string)
  "Process sentinel that watches for Immutant to stop and updates the
buffer and mode line appropriately."
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (when (string-match "^\\(finished\\|exited\\|interrupt\\)" string)
        (immutant-server-update-mode-line)
        (immutant-server-insert-text (concat "\nImmutant Stopped"
                                             immutant-server-output-divider))
        (message "Immutant stopped")))))

 ;; Interactive functions

(defun immutant-server-pop-to-server-buffer ()
  "Bring the server buffer to the front if it exists."
  (interactive)
  (if (get-buffer immutant-server-buffer)
      (pop-to-buffer immutant-server-buffer)
    (error "The immutant-server-buffer does not exist.")))

(defun immutant-server-set-default-directory ()
  (when immutant-server-default-directory
    (let ((dir (if (file-name-absolute-p immutant-server-default-directory)
                   immutant-server-default-directory
                 (expand-file-name immutant-server-default-directory))))
      (make-directory dir t)
      (setq default-directory dir))))

;;;###autoload
(defun immutant-server-start (&optional arg)
  "Start Immutant, pop to the `immutant-server-buffer' and print the
output there."
  (interactive "P")
  (if (immutant-server-running-p)
      (error "Immutant is already running.")
    (let ((cmd (if arg
                   (read-from-minibuffer
                    "Immutant server command: "
                    immutant-server-executable nil nil
                    'immutant-server-executable-history)
                 immutant-server-executable))
          (buffer (get-buffer-create immutant-server-buffer))
          (inhibit-read-only t))
      (with-current-buffer buffer
        (unless (eq 'immutant-server-mode major-mode)
          (immutant-server-mode))
        (immutant-server-set-default-directory)
        (setq immutant-server-error-count 0)
        (immutant-server-update-mode-line)
        (when immutant-server-clear-output-on-start
          (erase-buffer))
        (insert immutant-server-output-divider)
        (insert "Starting Immutant\n\n")
        (let ((proc (start-process-shell-command
                     "immutant" buffer (expand-file-name cmd))))
          (set-process-filter proc 'immutant-server-proc-filter)
          (set-process-sentinel proc 'immutant-server-sentinel))
        (message "Immutant started")
        (immutant-server-pop-to-server-buffer)
        (goto-char (point-max))))))

(defun immutant-server-stop ()
  "Stop Immutant if it is running."
  (interactive)
  (let ((proc (get-buffer-process immutant-server-buffer)))
    (if proc
        (progn
          (interrupt-process proc t)
          (save-excursion
            (with-current-buffer immutant-server-buffer
              (goto-char (point-max)))))
      (error "Immutant is not running."))))

(defun immutant-server-next-line ()
  "Move the point to the beginning of the next log line"
  (interactive)
  (end-of-line)
  (if (search-forward-regexp immutant-server-log-line-regexp nil t)
      (beginning-of-line)
    (forward-line)))

(defun immutant-server-previous-line ()
  "Move the point to the beginning of the previous log line"
  (interactive)
  (if (search-backward-regexp immutant-server-log-line-regexp nil t)
      (beginning-of-line)
    (forward-line -1)))

(defun immutant-server-next-error ()
  "Move the point to the beginning of the next line containing
`immutant-server-error-regexp'"
  (interactive)
  (let ((pt (point)))
    (end-of-line)
    (if (search-forward-regexp immutant-server-error-regexp nil t)
        (beginning-of-line)
      (progn
        (goto-char pt)
        (error "No more ERROR messages")))))

(defun immutant-server-previous-error ()
  "Move the point to the beginning of the previous line containing
`immutant-server-error-regexp'"
  (interactive)
  (if (search-backward-regexp immutant-server-error-regexp nil t)
      (beginning-of-line)
    (error "No previous ERROR messages")))

(defun immutant-server-quit-buffer ()
  "Kill or bury the `immutant-server-buffer' based on the value of
`immutant-server-bury-on-quit'"
  (interactive)
  (when (and (immutant-server-running-p)
             (yes-or-no-p "Stop Immutant?"))
    (immutant-server-stop))
  (if immutant-server-bury-on-quit
      (bury-buffer)
    (kill-buffer)))

 ;; Mode definition

(defvar immutant-server-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "n" 'immutant-server-next-line)
    (define-key map "p" 'immutant-server-previous-line)
    (define-key map (kbd "M-n") 'immutant-server-next-error)
    (define-key map (kbd "M-p") 'immutant-server-previous-error)
    (define-key map "t" 'toggle-truncate-lines)
    (define-key map "q" 'immutant-server-quit-buffer)
    (define-key map (kbd "C-c C-c") 'immutant-server-stop)
    (define-key map (kbd "C-c C-s") 'immutant-server-start)
    map)
  "Keymap for \"immutant-server\" buffers.")

(defun immutant-server-mode ()
  "Major mode for \"immutant-server\" buffers.

All currently available key bindings:

n        Move to the next log line
p        Move to the previous log line
M-n      Move to the next error
M-p      Move to the previous error
t        Toggle line truncation
q        Quit (kill or bury) the Immutant output buffer
C-c C-c  Stop the Immutant process
C-c C-s  Start the Immutant process
C-u C-c C-s Prompt for the server command before starting Immutant"
  (interactive)
  (kill-all-local-variables)
  (use-local-map immutant-server-mode-map)
  (set (make-local-variable 'window-point-insertion-type) t)
  (setq major-mode 'immutant-server-mode
        mode-name 'immutant-server-mode-name
        buffer-read-only t))

(provide 'immutant-server)
;;; immutant-server.el ends here
