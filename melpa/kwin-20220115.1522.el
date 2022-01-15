;;; kwin.el --- communicatewith the KWin window manager
;;
;; Copyright (C) 2012 by Simon Hafner
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
;;
;; Substational copy/pasting from mozrepl (Massimiliano Mirra)

;; Author: Simon Hafner
;; URL: http://github.com/reactormonk/kwin-minor-mode
;; Package-Version: 20220115.1522
;; Package-Commit: ec1e794168692c71e5bf89e124981f790b2a726b
;; Version: 0.1


;;; Commentary:
;;
;; This file implements communcation with the KWin window manager from
;; KDE. This is not really a repl, as KWin does not keep the state
;; between scripts.
;;
;; This file contains
;;
;;   * a major mode for displaying output and errors.
;;   * a minor mode for sending code portions or whole files from
;;     other buffers to KWin, `kwin-minor-mode'.
;;
;;; TODO:
;; - faces
;; - a way to stop scripts

;;; Code:

(require 'dbus)

;; Maybe fix-me: C-c control-char are reserved for major modes. But
;; this minor mode is used in only one major mode (or one family of
;; major modes) so it complies I think ...
(defvar kwin-minor-mode-map
  (let ((map (make-sparse-keymap)))
    ;; (define-key map "\C-\M-x"  'kwin-send-defun)
    ;; (define-key map "\C-c\C-c" 'kwin-send-defun-and-go)
    (define-key map "\C-c\C-r" 'kwin-send-region)
    (define-key map "\C-c\C-l" 'kwin-save-buffer-and-send)
    (define-key map "\C-c\C-k" 'kwin-kill-script)
    map))

;;;###autoload
(define-minor-mode kwin-minor-mode
  "KWin minor mode for interaction with KWin.
With no argument, this command toggles the mode.
Non-null prefix argument turns on the mode.
Null prefix argument turns off the mode.

When this minor mode is enabled, some commands become available
to send current code area \(as understood by c-mark-function) or
region or buffer to the current KWin process.

The following keys are bound in this minor mode:

\\{kwin-minor-mode-map}"
  nil
  " KWin"
  :keymap kwin-minor-mode-map
  :group 'kwin)

(defun kwin-send-file (path)
  "Sends the path to KWin, tells it to load the file and connects the stdout and stderr to the inf-kwin buffer."
  (lexical-let* ((script-id (dbus-call-method :session "org.kde.KWin" "/Scripting" "org.kde.kwin.Scripting" "loadScript" path))
         (script-path (concat "/" (number-to-string script-id)))
         (dbus-handles nil)             ; TODO: unregister these
         (start-time (current-time)))
    ;; Register the signals for stdout/stderr
    (flet ((register-output (method handler) (dbus-register-signal :session "org.kde.KWin" script-path "org.kde.kwin.Scripting" method handler)))
      (setq dbus-handles (list (register-output "print" (lambda (stdout) (kwin-write-to-output :stdout stdout script-id)))
                               (register-output "printError" (lambda (stderr) (kwin-write-to-output :stderr stderr script-id))))))

    ;; This should clean up as soon as the call returns, which
    ;; indicates the script is done. Note that setting up signals via
    ;; connect isn't captured here, so we don't do cleanup... yet.
    ;; Apparently, the output isn't displayed twice even with the same
    ;; script id reused, so we should be fine.
    (dbus-call-method-asynchronously :session "org.kde.KWin" script-path "org.kde.kwin.Scripting" "run"
                                     (lambda (&rest args)
                                       
                                       ;; Only report if the script
                                       ;; took more than 5 secs.
                                       (when (> (time-to-seconds (time-since start-time)) 5)
                                         (kwin-script-exit script-id))))))

(defun kwin-send-region (start end)
  "Send the region to KWin via dbus."
  (interactive "r")
  (kwin-send-file (kwin-region-to-file start end))
  (display-buffer (inferior-kwin-buffer)))

(defun kwin-save-buffer-and-send ()
  "Save the current buffer and load the file into KWin."
  (interactive)
  (kwin-save-and-compile-file 'kwin-send-file)
  (display-buffer (inferior-kwin-buffer)))

(defun kwin-region-to-file (start end)
  "Saves the region to a tempfile and returns the path. If
necessary, the source is compiled."
  (let ((kwin-temporary-file (make-temp-file "emacs-kwin")))
    (case major-mode
        (js-mode
         (write-region start end kwin-temporary-file))
        (coffee-mode (coffee-compile-region start end)
                     (with-current-buffer coffee-compiled-buffer-name
                       (write-region (point-min) (point-max) kwin-temporary-file)))
        (nimrod-mode (nimrod-compile-region-to-js start end)
                     (with-current-buffer nimrod-compiled-buffer-name
                       (write-region (point-min) (point-max) kwin-temporary-file)))
        (t (error "mode not supported")))
    kwin-temporary-file))

(defun kwin-save-and-compile-file (callback)
  "Passes the path to the compiled file to the callback."
  (save-buffer)
  (case major-mode
    (js-mode
     (funcall callback (buffer-file-name)))
    (coffee-mode
     (coffee-compile-file) (funcall callback (coffee-compiled-file-name)))
    (nimrod-mode
     (nimrod-compile-file-to-js callback))
    (t (error "mode not supported"))))

(defun kwin-kill-script (script-id)
  "Kill script with supplied id or all, if called without prefix."
  (interactive "P")
  (mapc (lambda (path) (dbus-call-method :session "org.kde.kwin.Scripting" path "org.kde.kwin.Scripting" "stop"))
        (mapcar (apply-partially 'concat "/")
                (if script-id
                    (list script-id)
                  (remove-if-not
                   (apply-partially 'string-match "[[:digit:]]+")
                   (dbus-introspect-get-node-names :session "org.kde.kwin.Scripting" "/"))))))

;;; Inferior Mode

(defvar inferior-kwin-buffer nil
  "The buffer to which the messages are written.")

(defvar inferior-kwin-mode-map
  (let ((map (make-sparse-keymap)))
    ;; (define-key map "\C-cc" 'inferior-moz-insert-moz-repl)
    map))

(defun inferior-kwin-buffer ()
  "Return inferior Kwin buffer. Create a new one if neccesary."
  (when (not (buffer-live-p inferior-kwin-buffer))
    (with-current-buffer (setq inferior-kwin-buffer (get-buffer-create "Inf-KWin")) (inferior-kwin-mode)))
  inferior-kwin-buffer)

(defun kwin-write-to-output (type message script-id)
  (with-current-buffer (inferior-kwin-buffer)
    (let ((insert-point (point-max)))
      (goto-char (point-max))
      (insert (concat (format "[%d] " script-id) message "\n"))
      (goto-char insert-point)
      (next-line)
      (recenter 0))))

(defun kwin-script-exit (script-id)
  (kwin-write-to-output :info "The script finished executing."  script-id))

;;;###autoload
(define-derived-mode inferior-kwin-mode fundamental-mode "Inf-KWin"
  "Major mode for displaying KWin responses.")

(provide 'kwin)

;;; kwin.el ends here
