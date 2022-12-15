;;; revert-buffer-all.el --- Revert all open buffers -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Copyright (C) 2021  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-buffer-revert-all
;; Version: 0.1
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; Utility to revert all buffers, useful to run after external
;; changes to a project have been made such as applying a patch
;; or switching branches.
;;

;;; Usage:

;; ;; Bind the keys
;; (global-set-key (kbd "C-S-M-r") 'revert-buffer-all)

;;; Code:

(eval-when-compile
  ;; For `pcase-dolist'.
  (require 'pcase))

;;;###autoload
(defun revert-buffer-all ()
  "Refresh all open buffers from their respective files.

Buffers which no longer exist are closed.

This can be useful when updating or checking out branches outside of Emacs."
  (interactive)
  (let*
    ( ;; Pairs of '(filename . buf)'.
      (filename-and-buffer-list
        (let ((temp-list nil))
          (dolist (buf (buffer-list))
            (let ((filename (buffer-file-name buf)))
              (when filename
                (push (cons filename buf) temp-list))))
          temp-list))

      (message-prefix "Buffer Revert All:")
      (count (length filename-and-buffer-list))
      (count-final 0)
      (count-close 0)
      (count-error 0)
      ;; Keep text at a fixed width when redrawing.
      (format-count (format "%%%dd" (length (number-to-string count))))
      (format-text
        (concat message-prefix " reverting [" format-count " of " format-count "] %3d%%: %s"))
      (index 1))

    (message "%s beginning with %d buffers..." message-prefix count)

    (pcase-dolist (`(,filename . ,buf) filename-and-buffer-list)
      ;; Revert only buffers containing files, which are not modified;
      ;; do not try to revert non-file buffers such as '*Messages*'.
      (message format-text index count (round (* 100 (/ (float index) count))) filename)

      (cond
        ((file-exists-p filename)
          ;; If the file exists, revert the buffer.
          (cond
            (
              (with-demoted-errors "Error: %S"
                (with-current-buffer buf
                  (let ((no-undo (eq buffer-undo-list t)))

                    ;; Disable during revert.
                    (unless no-undo
                      (setq buffer-undo-list t)
                      (setq pending-undo-list nil))

                    (unwind-protect (revert-buffer :ignore-auto :noconfirm)

                      ;; Enable again (always run).
                      (unless no-undo
                        ;; It's possible a plugin loads undo data from disk,
                        ;; check if this is still unset.
                        (when (and (eq buffer-undo-list t) (null pending-undo-list))
                          (setq buffer-undo-list nil))))))
                t)
              (setq count-final (1+ count-final)))
            (t
              (setq count-error (1+ count-error)))))

        (t
          ;; If the file doesn't exist, kill the buffer.
          ;; No query done when killing buffer.
          (let ((kill-buffer-query-functions nil))
            (message "%s closing non-existing file buffer: %s" message-prefix buf)
            (kill-buffer buf)
            (setq count-close (1+ count-close)))))

      (setq index (1+ index)))
    (message
      (concat
        message-prefix (format " finished with %d buffer(s)" count-final)
        (cond
          ((zerop count-close)
            "")
          (t
            (format ", %d closed" count-close)))
        (cond
          ((zerop count-error)
            "")
          (t
            (format ", %d error (see message buffer)" count-error)))))))

(provide 'revert-buffer-all)
;;; revert-buffer-all.el ends here
