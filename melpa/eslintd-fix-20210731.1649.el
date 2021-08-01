;;; eslintd-fix.el --- use eslint_d to automatically fix js files -*- lexical-binding: t -*-

;; Copyright (C) 2016 by Aaron Jensen

;; Author: Aaron Jensen <aaronjensen@gmail.com>
;; URL: https://github.com/aaronjensen/eslintd-fix
;; Package-Version: 20210731.1649
;; Package-Commit: 3897d8a679a6e98e3f5054aaefe07f6b55f8f128
;; Version: 1.2.0
;; Package-Requires: ((dash "2.12.0") (emacs "26.3"))

;;; Commentary:

;; This package provides the eslintd-fix minor mode, which will use eslint_d
;; (https://github.com/mantoni/eslint_d.js) to automatically fix javascript code
;; before it is saved.

;; To use it, require it, make sure `eslint_d' is in your path and add it to
;; your favorite javascript mode:

;;    (add-hook 'js2-mode-hook #'eslintd-fix-mode)

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'dash)
(require 'xdg)

(defgroup eslintd-fix nil
  "Fix javascript code with eslint_d"
  :group 'tools)

(defcustom eslintd-fix-executable "eslint_d"
  "The eslint_d executable used by `eslintd-fix'."
  :group 'eslintd-fix
  :type 'string)

(defcustom eslintd-fix-host "127.0.0.1"
  "The host to connect to for eslint_d. Typically either \"127.0.0.1\" or \"localhost\"."
  :group 'eslintd-fix
  :type 'string)

(defcustom eslintd-fix-portfile
  (let ((directory (or (xdg-runtime-dir) "~/")))
    (expand-file-name ".eslint_d" directory))
  "The file written by eslint_d containing the port and token."
  :group 'eslintd-fix
  :type 'string)

(defcustom eslintd-fix-preprocess-command nil
  "The shell command to pipe the buffer into before piping to eslintd.
This is useful for integrating `prettier', for example. It is ignored if nil."
  :group 'eslintd-fix
  :type 'string)

(defcustom eslintd-fix-timeout-seconds 2
  "The time to wait for eslint_d to respond to a request."
  :group 'eslintd-fix
  :type 'integer)

(defvar-local eslintd-fix--verified nil
  "Set to t if eslintd has been verified as working for this buffer.")

(defvar eslintd-fix-connection nil
  "An open, not-yet-used connection to eslint_d.")

(defun eslintd-fix--goto-line (line)
  "Move point to LINE."
  (goto-char (point-min))
  (forward-line (1- line)))

(defun eslintd-fix--delete-whole-line (&optional arg)
    "Delete the current line without putting it in the `kill-ring'.
Derived from function `kill-whole-line'.  ARG is defined as for that
function."
    (setq arg (or arg 1))
    (if (and (> arg 0)
             (eobp)
             (save-excursion (forward-visible-line 0) (eobp)))
        (signal 'end-of-buffer nil))
    (if (and (< arg 0)
             (bobp)
             (save-excursion (end-of-visible-line) (bobp)))
        (signal 'beginning-of-buffer nil))
    (cond ((zerop arg)
           (delete-region (progn (forward-visible-line 0) (point))
                          (progn (end-of-visible-line) (point))))
          ((< arg 0)
           (delete-region (progn (end-of-visible-line) (point))
                          (progn (forward-visible-line (1+ arg))
                                 (unless (bobp)
                                   (backward-char))
                                 (point))))
          (t
           (delete-region (progn (forward-visible-line 0) (point))
                                                  (progn (forward-visible-line arg) (point))))))

(defun eslintd-fix--apply-rcs-patch (patch-buffer)
  "Apply an RCS-formatted diff from PATCH-BUFFER to the current buffer."
  (let ((target-buffer (current-buffer))
        ;; Relative offset between buffer line numbers and line numbers
        ;; in patch.
        ;;
        ;; Line numbers in the patch are based on the source file, so
        ;; we have to keep an offset when making changes to the
        ;; buffer.
        ;;
        ;; Appending lines decrements the offset (possibly making it
        ;; negative), deleting lines increments it. This order
        ;; simplifies the forward-line invocations.
        (line-offset 0))
    (save-excursion
      (with-current-buffer patch-buffer
        (goto-char (point-min))
        (while (not (eobp))
          (unless (looking-at "^\\([ad]\\)\\([0-9]+\\) \\([0-9]+\\)")
            (error "Invalid rcs patch or internal error in eslintd-fix--apply-rcs-patch"))
          (forward-line)
          (let ((action (match-string 1))
                (from (string-to-number (match-string 2)))
                (len  (string-to-number (match-string 3))))
            (cond
             ((equal action "a")
              (let ((start (point)))
                (forward-line len)
                (let ((text (buffer-substring start (point))))
                  (with-current-buffer target-buffer
                    (setq line-offset (- line-offset len))
                    (goto-char (point-min))
                    (forward-line (- from len line-offset))
                    (insert text)))))
             ((equal action "d")
              (with-current-buffer target-buffer
                (eslintd-fix--goto-line (- from line-offset))
                (setq line-offset (+ line-offset len))
                (eslintd-fix--delete-whole-line len)))
             (t
              (error "Invalid rcs patch or internal error in eslintd-fix--apply-rcs-patch")))))))))

(defun eslintd-fix--replace-buffer-contents-via-patch (buffer file)
  "Replace BUFFER contents with contents of FILE.

Maintain point position as best as possible and minimize undo
size by applying the changes as a diff patch."
  (with-temp-buffer
    (let ((patch-buffer (current-buffer)))
      (with-current-buffer buffer
        (when (not (zerop
                    (call-process-region
                     (point-min) (point-max) "diff"
                     nil patch-buffer nil "-n" "-" file)))
          (eslintd-fix--apply-rcs-patch patch-buffer))))))

(defun eslintd-fix--compatible-versionp (executable)
  "Return t if EXECUTABLE supports the features we need."
  (and (file-executable-p executable)
       (string-match-p
        "--fix-to-stdout"
        (condition-case nil
            (with-output-to-string (call-process executable nil standard-output nil "--help"))
          (error "")))))

(defun eslintd-fix--eslint-config-foundp (executable)
  "Return t if there is an eslint config for the current file.

EXECUTABLE is the full path to an eslint_d executable."
  (let ((filename (buffer-file-name)))
    (and filename
         (zerop (call-process-shell-command
                 (concat
                  executable
                  " --print-config "
                  (shell-quote-argument filename)))))))

(defun eslintd-fix--deactivate (message)
  "Deactivate ‘eslintd-fix-mode’ and show MESSAGE explaining why."
  (eslintd-fix-mode -1)
  (message (concat "eslintd-fix: " message))
  nil)

(defun eslintd-fix--verify (&optional force)
  "Verify that eslint_d is running and the right version.

Pass non-nil FORCE to bypass the memoized verification result.
Return t eslint_d is working and nil otherwise."
  (-if-let* ((executable (executable-find eslintd-fix-executable)))
      (cond ((and eslintd-fix--verified
                  (not force))
             t)
            ((not (eslintd-fix--compatible-versionp executable))
             (eslintd-fix--deactivate "Could not find eslint_d or it does not have the `--fix-to-stdout' feature."))
            ;; This will start eslint_d if it has not already been started.
            ((not (eslintd-fix--eslint-config-foundp executable))
             (eslintd-fix--deactivate "Could not find an eslint config file."))
            ((not (file-exists-p eslintd-fix-portfile))
             (eslintd-fix--deactivate
              (concat  "Could not find `eslintd-fix-portfile' after starting eslint_d. "
                       "This may be a bug in eslint_d, eslintd-fix or you may have overridden the portfile location somehow.")))
            (t (setq eslintd-fix--verified t)))
    (eslintd-fix--deactivate "Could not find eslint_d. Customize `eslintd-fix-executable' and ensure it is in your `exec-path'.")))

(defun eslintd-fix--read-portfile ()
  "Read and return contents of ~/.eslint_d as a list."
  (when (file-exists-p eslintd-fix-portfile)
    (with-temp-buffer
      (insert-file-contents eslintd-fix-portfile)
      (split-string (buffer-string) " " t))))

(defun eslintd-fix--start ()
  "Start eslint_d.

Return t if it successfully starts."
  (eslintd-fix--verify t))

(defun eslintd-fix--buffer-contains-exit-codep ()
  "Return t if buffer ends with an eslint_d exit code."
  (goto-char (point-max))
  (beginning-of-line)
  (looking-at "# exit [[:digit:]]+"))

(defun eslintd-fix--connection-sentinel (connection status)
  "Automatically attempt to start eslint_d if CONNECTION fails.

STATUS contains the failure status message."
  (pcase (process-status connection)
    ('failed
     (message "eslintd-fix: Failed to connect: %s" status)
     (eslintd-fix--start))))

(defun eslintd-fix--connection-filter (connection output)
  "Copy OUTPUT from CONNECTION to output buffer."
  (-when-let* ((output-buffer (process-get connection 'eslintd-fix-output-buffer)))
    (with-current-buffer output-buffer
      (insert output))))

(defun eslintd-fix--open-connection ()
  "Open a connection to eslint_d.

Return nil if eslint_d is not running. Also close the existing,
cached connection if it is already open."
  (and eslintd-fix-connection
       (delete-process eslintd-fix-connection))
  (-when-let* ((portfile (or (eslintd-fix--read-portfile)
                             (and (eslintd-fix--start)
                                  (eslintd-fix--read-portfile))))
               (port (car portfile))
               (token (cadr portfile))
               (connection
                (open-network-stream "eslintd-fix" nil eslintd-fix-host port :nowait t)))
    (process-put connection 'eslintd-fix-token token)
    (set-process-query-on-exit-flag connection nil)
    (set-process-sentinel connection 'eslintd-fix--connection-sentinel)
    (setq eslintd-fix-connection connection)))

(defun eslintd-fix--wait-for-connection (connection)
  "Wait for CONNECTION to connect.

Return the CONNECTION if, after waiting it is open, otherwise nil."
  (when connection
    (while (eq (process-status connection) 'connect)
      (sleep-for 0.01))
    (when (eq (process-status connection) 'open)
      connection)))

(defun eslintd-fix--wait-for-connection-to-close (connection)
  "Wait for CONNECTION to close.

Return t if the connection closes successfully."
  (catch 'done
    (dotimes (_ (truncate (/ eslintd-fix-timeout-seconds 0.01)))
      (if (eq (process-status connection) 'open)
          (accept-process-output connection 0.01 nil t)
        (throw 'done (eq (process-status connection) 'closed))))
    (message
     (concat "eslintd-fix: Timed out waiting for output, "
             "try increasing eslintd-fix-timeout-seconds."))
    nil))

(defun eslintd-fix--get-connection ()
  "Return an open connection to eslint_d.

Will open a connection if there is not one."
  (or (eslintd-fix--wait-for-connection eslintd-fix-connection)
      (eslintd-fix--wait-for-connection (eslintd-fix--open-connection))))

(defun eslintd-fix ()
  "Use eslint_d to \"fix\ the current buffer."
  (interactive)
  (-when-let* ((_ (eslintd-fix--verify))
               (connection (eslintd-fix--get-connection))
               (token (process-get connection 'eslintd-fix-token))
               (buffer (current-buffer)))
    (unwind-protect
        (save-restriction
          (widen)
          (with-temp-buffer
            (process-put connection 'eslintd-fix-output-buffer (current-buffer))
            (set-process-filter connection 'eslintd-fix--connection-filter)
            (with-current-buffer buffer
              (process-send-string connection
                                   (concat
                                    (combine-and-quote-strings
                                     (list token
                                           default-directory
                                           "--fix-to-stdout"
                                           "--stdin-filename" buffer-file-name
                                           "--stdin"))
                                    "\n"))
              (process-send-region connection (point-min) (point-max))
              (process-send-eof connection))

            ;; Wait for connection to close
            (when (eslintd-fix--wait-for-connection-to-close connection)
              ;; Do not replace contents if there was an error or buffer is empty
              (unless (or (zerop (buffer-size))
                          (eslintd-fix--buffer-contains-exit-codep))
                (if (fboundp 'replace-buffer-contents)
                    (let ((temp-buffer (current-buffer)))
                      (with-current-buffer buffer
                        (replace-buffer-contents temp-buffer)))
                  (let ((inhibit-message t)
                        (output-file (make-temp-file "eslintd-fix-")))
                    (unwind-protect
                        (progn
                          ;; Use write-region instead of write-file to avoid saving to
                          ;; recentf and any other hooks.
                          (write-region (point-min) (point-max) output-file)
                          (eslintd-fix--replace-buffer-contents-via-patch buffer output-file))
                      (delete-file output-file)))))))))

    ;; Open a new connection to save us time next time
    (eslintd-fix--open-connection)))

;;;###autoload
(define-minor-mode eslintd-fix-mode
  "Use eslint_d to automatically fix javascript before saving."
  :lighter " fix"
  (if eslintd-fix-mode
      (add-hook 'before-save-hook #'eslintd-fix nil t)
    (setq eslintd-fix--verified nil)
    (remove-hook 'before-save-hook #'eslintd-fix t)))

(provide 'eslintd-fix)
;;; eslintd-fix.el ends here
