;;; i3bar.el --- Display status from an i3status command in the tab bar -*- lexical-binding: t -*-

;; Copyright 2022 Steven Allen <steven@stebalien.com>

;; Author: Steven Allen <steven@stebalien.com>
;; URL: https://github.com/Stebalien/i3bar.el
;; Package-Version: 20230514.8
;; Package-Commit: 6bbad0891d330b119c77c036643bfb5f9d4d25e3
;; Version: 0.0.1
;; Package-Requires: ((emacs "28.1"))
;; Keywords: unix

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Displays the output of an i3status command in the Emacs mode-line (or tab-line).

;;; Code:

(eval-when-compile (require 'cl-lib))

(defvar i3bar--last-update nil
  "The last i3bar update received.")

(defvar i3bar--process nil
  "The running i3bar process, if any.")

(defvar i3bar-string ""
  "The i3bar string displayed in the mode-line.")

(put 'i3bar-string 'risky-local-variable t)

(defgroup i3bar nil
  "\
i3bar status display for Emacs."
  :version "0.0.1"
  :group 'mode-line)

;;;###autoload
(define-minor-mode i3bar-mode
  "Display an i3bar in the mode-line."
  :global t :group 'i3bar
  (i3bar--stop)
  (when i3bar-mode
    (or global-mode-string (setq global-mode-string '("")))
    (unless (memq 'i3bar-string global-mode-string)
      (setq global-mode-string (append global-mode-string '(i3bar-string))))
    (i3bar--start)))

(defcustom i3bar-command
  (seq-find #'executable-find '("i3status" "i3status-rs" "i3blocks") "i3status")
  "The i3status command."
  :group 'i3bar
  :type '(choice
          (string :tag "Shell Command")
          (repeat (string)))
  :initialize #'custom-initialize-default
  :set (lambda (symbol value)
         (set-default-toplevel-value symbol value)
         (when i3bar-mode (i3bar-restart))))

(defcustom i3bar-separator "|"
  "The default block separator."
  :group 'i3bar
  :type '(choice
          (string :tag "Separator")
          (const :tag "None" nil))
  :initialize #'custom-initialize-default
  :set #'i3bar--custom-set)

(defcustom i3bar-face-function 'i3bar-face-passthrough
  "Function to define an i3bar block face.
This function is passed a foreground/background color pair and is
expected to return the desired face, list of faces, or nil (for no face)."
  :group 'i3bar
  :type '(choice function
                 (const :tag "No colors" nil))
  :initialize #'custom-initialize-default
  :set #'i3bar--custom-set)

(defun i3bar--custom-set (symbol value)
  "Set an i3bar custom SYMBOL to VALUE and redisplay."
  (set-default-toplevel-value symbol value)
  (i3bar--redisplay))

(defun i3bar-face-passthrough (foreground background)
  "The default i3bar face-function.
This function applies the FOREGROUND and BACKGROUND colors as specified by the
i3status program."
  (declare (pure t))
  (let (face)
    (when foreground (setq face (plist-put face :foreground foreground)))
    (when background (setq face (plist-put face :background background)))
    face))

(defun i3bar--json-parse ()
  "Parse a json object from the buffer, or signal an error.
This is a thin wrapper around `json-parse-buffer', which changes the defaults."
  (json-parse-buffer :object-type 'plist :false-object nil))

(defun i3bar--format-block (block)
  "Format an i3bar BLOCK for display."
  (cl-destructuring-bind
      (&key (full_text "") color background (separator t) &allow-other-keys)
      block
    (when color (setq color (substring color 0 -2)))
    (when background (setq background (substring background 0 -2)))
    (let (properties)
      (when-let (face (and i3bar-face-function
                           (funcall i3bar-face-function color background)))
        (setq properties (plist-put properties 'face face)))
      (set-text-properties 0 (length full_text) properties full_text))
    (when (and separator (length> i3bar-separator 0))
      (setq full_text (concat full_text i3bar-separator)))
    full_text))

(defun i3bar--redisplay ()
  "Redisplay the i3bar."
  (when i3bar-mode
    (setq i3bar-string (mapconcat #'i3bar--format-block i3bar--last-update ""))
    (force-mode-line-update t)))

(defun i3bar--update (update)
  "Apply an UPDATE to the i3status bar."
  (setq i3bar--last-update update)
  (i3bar--redisplay))

(defun i3bar--process-filter (proc string)
  "Process output from the i3status process.
This function writes the STRING to PROC's buffer, then attempts to parse as
much as it can, calling `i3bar--update' on all bar updates."
  (let ((buf (process-buffer proc)))
    (when (buffer-live-p buf)
      (with-current-buffer buf
        ;; Write the input to the buffer (might be partial).
        (save-excursion
          (goto-char (process-mark proc))
          (insert string)
          (set-marker (process-mark proc) (point)))
        (condition-case err
            (while (progn (skip-chars-forward "[:space:]") (not (eobp)))
              (process-put
               proc 'i3bar-state
               (pcase (process-get proc 'i3bar-state)
                 ;; Expect a protocol header
                 ('nil (unless (= (plist-get (i3bar--json-parse) :version) 1)
                         (error "Version not supported"))
                       'begin)
                 ;; Expect an opening [ of the infinite array.
                 ('begin (unless (= (following-char) ?\[)
                           (error "Expected array of updates"))
                         (forward-char)
                         'update)
                 ;; Expect an element in the infinite "update" array.
                 ('update (if (= (following-char) ?\])
                              (progn (forward-char) 'end)
                            (i3bar--update (i3bar--json-parse))
                            'sep))
                 ;; Expect a separator (comma).
                 ('sep (unless (= (following-char) ?,)
                         (error "Expected a trailing comma"))
                       (forward-char)
                       'update)
                 ;; We don't expect anything here, we should be done.
                 ('end (error "Unexpected output")))))
          ((json-parse-error json-end-of-file)) ; partial input, move on.
          ((error debug)     ; cleanup after a failure.
           (delete-process i3bar--process)
           (setq i3bar--last-update nil
                 i3bar-string (format "i3bar failed: %s" err))))
        (when (buffer-live-p buf) (delete-region (point-min) (point)))))))

(defun i3bar--process-sentinel (proc status)
  "Handle events from the i3status process (PROC).
If the process has exited, this function stores the exit STATUS in
`i3bar-string'."
  (unless (process-live-p proc)
    (setq i3bar--process nil)
    (let ((buf (process-buffer proc)))
      (when (and buf (buffer-live-p buf)) (kill-buffer buf)))
    (setq i3bar--last-update nil
          i3bar-string (format "i3bar: %s" status))))

(defun i3bar-restart ()
  "Restart the i3status program."
  (interactive)
  (unless i3bar-mode (user-error "The i3bar-mode is not enabled"))
  (i3bar--start))

(defun i3bar--start ()
  "Start the i3bar."
  (i3bar--stop)
  (condition-case err
      (let ((default-directory user-emacs-directory))
        (setq i3bar--process (make-process
                              :name "i3bar"
                              :buffer " *i3status process*"
                              :stderr " *i3status stderr*"
                              :command (ensure-list i3bar-command)
                              :connection-type 'pipe
                              :noquery t
                              :sentinel #'i3bar--process-sentinel
                              :filter #'i3bar--process-filter)))
    (error
     (setq i3bar-string (format "starting i3bar: %s" (error-message-string err))))))

(defun i3bar--stop ()
  "Stop the i3bar."
  ;; Kill the process, if any.
  (when (and i3bar--process (process-live-p i3bar--process))
    (delete-process i3bar--process))
  ;; And clear any error/exit messages.
  (setq i3bar-string ""
        i3bar--last-update nil))

(provide 'i3bar)
;;; i3bar.el ends here
