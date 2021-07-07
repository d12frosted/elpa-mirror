;;; unkillable-scratch.el --- Disallow the \*scratch\* buffer from being killed
;;
;;; Copyright (C) 2018  Free Software Foundation, Inc.
;;
;; Author: Eric Crosson <eric.s.crosson@utexas.com>
;; Version: 1.0.0
;; Package-Version: 20190309.17
;; Package-Commit: b24c2a760529833f230c14cb02ff6e7ec92288ab
;; Keywords: convenience
;; URL: https://github.com/EricCrosson/unkillable-scratch
;; Package-Requires: ((emacs "24"))
;;
;; This file is not a part of GNU Emacs.
;;
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.
;;
;;
;;; Commentary:
;;
;; This package provides a minor mode that will disallow buffers from
;; being killed.  Any buffer matching a regexp in the list
;; `unkillable-buffers' will not be killed.

;; Only one bufer is in `unkillable-buffers' by default: the *scratch*
;; buffer.

;; The *scratch* buffer is considered specially; in the event of a call to
;; `kill-buffer' the buffer will be replaced with
;; `initial-scratch-message'.  Removing the regexp matching *scratch* from
;; `unkillable-buffers' disables this behavior.

;; Usage:

;; ; (optional): add regexp matching buffers to disallow killing to
;; ; list 'unkillable-scratch
;; (add-to-list 'unkillable-scratch "\\*.*\\*")

;; ; and activate the mode with
;; (unkillable-scratch 1)
;;   - or -
;; M-x unkillable-scratch

;;; TODO:

;; - unkillable-scratch-really-kill
;;     actually kill the selected buffer at point.  If this buffer was
;;     the last matching buffer to the regexp(s) keeping him from being
;;     killed, remove said regexp(s) from `unkillable-buffers'.
;;


;;; Code:

(defgroup scratch nil
  "*Scratch* buffer."
  :group 'scratch)

(defcustom unkillable-buffers '("^\\*scratch\\*$")
  "List of regexp's matching buffers that may not be killed."
  :type '(repeat string)
  :group 'scratch)

(defcustom unkillable-scratch-behavior 'bury
  "Desired action for `unkillable-scratch-buffer' to apply to
buffers matching regexps in `unkillable-buffers'.

The following values are recognized:

- 'bury       :: bury the buffer instead of killing it (default)
- 'do-nothing :: disallow the buffer from being killed
- 'kill       :: actually kill the buffer -- this is the same as disabling `unkillable-scratch'."
  :type 'symbol
  :group 'scratch)

(defcustom unkillable-scratch-do-not-reset-scratch-buffer nil
  "Whether or not to reopulate the scratch buffer with `initial-scratch-message'"
  :type 'boolean
  :group 'scratch)

(defun unkillable-scratch-matches (buffer-name)
  "True when BUFFER-NAME matches any regexp contained in `unkillable-buffers'."
  (let ((match t))
    (catch 'match
      (mapc (lambda (regexp) (when (string-match regexp buffer-name) (throw 'match nil)))
	    unkillable-buffers)
      (setq match nil))
    match))

(defun unkillable-scratch-reset-scratch-buffer ()
  "Reset the contents of the *scratch* buffer to `initial-scratch-message'."
  (with-current-buffer "*scratch*"
    (delete-region (point-min) (point-max))
    (insert (or initial-scratch-message ""))))

(defun unkillable-scratch-buffer ()
  "Apply the `unkillable-scratch-behavior' to the buffer passed to
`kill-buffer-query-functions'."
  (let ((buf (buffer-name (current-buffer))))
    (if (unkillable-scratch-matches buf)
      (cond ((eq unkillable-scratch-behavior 'kill) t)
            ((eq unkillable-scratch-behavior 'bury) (progn
                                                      (when (and (equal buf "*scratch*")
                                                                 (not unkillable-scratch-do-not-reset-scratch-buffer))
                                                        (unkillable-scratch-reset-scratch-buffer))
                                                      (bury-buffer)
                                                      nil))
            (t  (progn
                  (when (and (equal buf "*scratch*")
                             (not unkillable-scratch-do-not-reset-scratch-buffer))
                    (unkillable-scratch-reset-scratch-buffer))
                  nil)))
      t)))

;;;###autoload
(define-minor-mode unkillable-scratch
  "A minor mode to disallow the *scratch* buffer from being killed."
  :init-value nil
  :global t
  :group 'scratch
  (if unkillable-scratch
      (add-hook 'kill-buffer-query-functions 'unkillable-scratch-buffer)
    (remove-hook 'kill-buffer-query-functions 'unkillable-scratch-buffer)))


(provide 'unkillable-scratch)

;;; unkillable-scratch.el ends here

; LocalWords:  unkillable
