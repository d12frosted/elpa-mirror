;;; zimports.el --- Reformat python imports with zimports -*- lexical-binding: t -*-

;; URL: https://github.com/schmir/zimports.el
;; Package-Version: 20211011.2059
;; Package-Commit: 76cf76bdc871cb0454a6fc555aeb1aa94f1b6e57
;; Version: 0
;; Package-Requires: ((emacs "26.1") (projectile "2.1.0"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your
;; option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This can be used to run zimports on python code

(require 'cl-lib)
(require 'projectile)

;;; Code:

(defgroup zimports nil
  "Reformat Python code with \"zimports\"."
  :group 'python)

(defcustom zimports-executable "zimports"
  "Name of the executable to run."
  :type 'string)

(defcustom zimports-args
  nil
  "Additional command line arguments to pass to zimports."
  :type '(repeat string))

(defun zimports--call-bin (input-buffer output-buffer error-buffer)
  "Call process zimports-executable.

Send INPUT-BUFFER content to the process stdin.  Saving the
output to OUTPUT-BUFFER.  Saving process stderr to ERROR-BUFFER.
Return zimports process the exit code."
  (with-current-buffer input-buffer
    (let ((default-directory (or (projectile-project-root)
                                 default-directory)))
      (let ((process (make-process :name "zimports"
                                   :command `(,zimports-executable ,@(zimports-call-args))
                                   :buffer output-buffer
                                   :stderr error-buffer
                                   :noquery t
                                   :sentinel (lambda (_process _event)))))
        (set-process-query-on-exit-flag (get-buffer-process error-buffer) nil)
        (set-process-sentinel (get-buffer-process error-buffer) (lambda (_process _event)))
        (save-restriction
          (widen)
          (process-send-region process (point-min) (point-max)))
        (process-send-eof process)
        (accept-process-output process nil nil t)
        (while (process-live-p process)
          (accept-process-output process nil nil t))
        (process-exit-status process)))))

(defun zimports-call-args ()
  "Build zimports process call arguments."
  (append zimports-args '("-")))

;;;###autoload
(defun zimports-buffer (&optional display)
  "Try to zimports the current buffer.

Show zimports output, if zimports exit abnormally and DISPLAY is t."
  (interactive (list t))
  (let* ((original-buffer (current-buffer))
         (tmpbuf (get-buffer-create "*zimports*"))
         (errbuf (get-buffer-create "*zimports-error*")))
    ;; This buffer can be left after previous zimports invocation.  It
    ;; can contain error message of the previous run.
    (dolist (buf (list tmpbuf errbuf))
      (with-current-buffer buf
        (erase-buffer)))
    (condition-case err
        (if (not (zerop (zimports--call-bin original-buffer tmpbuf errbuf)))
            (error "Process zimports failed, see %s buffer for details" (buffer-name errbuf))
          (unless (or (eq (buffer-size tmpbuf) 0)
                      (eq (compare-buffer-substrings tmpbuf nil nil original-buffer nil nil) 0))
            (with-current-buffer original-buffer (replace-buffer-contents tmpbuf)))
          (mapc #'kill-buffer (list tmpbuf errbuf)))
      (error (message "%s" (error-message-string err))
             (when display
               (pop-to-buffer errbuf))))))

;;;###autoload
(define-minor-mode zimports-mode
  "Automatically run zimports before saving."
  :lighter " zimports"
  (if zimports-mode
      (add-hook 'before-save-hook #'zimports-buffer nil t)
    (remove-hook 'before-save-hook #'zimports-buffer t)))

(provide 'zimports)

;;; zimports.el ends here
