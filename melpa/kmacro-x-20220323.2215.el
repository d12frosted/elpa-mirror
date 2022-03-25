;;; kmacro-x.el --- Keyboard macro helpers and extensions  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Wojciech Siewierski

;; Author: Wojciech Siewierski
;; URL: https://github.com/vifon/kmacro-x.el
;; Package-Version: 20220323.2215
;; Package-Commit: 429abd82c97031948b7681197551bb77708bd174
;; Keywords: convenience
;; Version: 0.9
;; Package-Requires: ((emacs "27.2"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A collection of commands, modes and functions building on top of
;; the keyboard macros (kmacros) system.

;;; Code:

(require 'kmacro)


(defgroup kmacro-x nil
  "Keyboard macro helpers and extensions."
  :group 'kmacro)

(defface kmacro-x-highlight-face
  '((t (:inherit hi-yellow)))  ;`highlight-regexp' hardcodes `hi-yellow'
  "The face used by `kmacro-x-mc-region'.")

(defcustom kmacro-x-mc-region-sequence-fmt "C-s %s C-r RET 2*C-s RET"
  "The sequence of keys used by `kmacro-x-mc-region'.

This sequence should search for the next occurrence of the query
and leave the region in a predictable state for the user to use.

The search query will be spliced into it using `format', and so
it should contain exactly one `%s' placeholder."
  :type 'string)


;;;###autoload
(defun kmacro-x-mc-region (start end &optional highlight)
  "Record a keyboard macro emulating multiple cursors.

The kmacro will first search for current region and then execute
the rest of the recorded kmacro.  During the kmacro execution,
mark is always at the beginning of the match and point is at
the end.

START and END mark the region.

If HIGHLIGHT is non-nil (or with the prefix argument when using
interactively) highlight the query using `highlight-regexp'.
Use `\\[unhighlight-regexp]' to remove the highlight later."
  (interactive "r\nP")
  (unless (and (= start (region-beginning))
               (= end (region-end)))
    ;; Ensure a consistent behavior when called interactively and when
    ;; called from Elisp with arguments not being the current region.
    ;; Considering the interactive nature of the kmacros, tampering
    ;; with the user's region seems very much justified.
    (push-mark start)
    (goto-char end))
  (let ((query (buffer-substring-no-properties start end)))
    (when (< (point) (mark))
      (exchange-point-and-mark))
    (deactivate-mark)
    (kmacro-push-ring)
    (setq last-kbd-macro
          (read-kbd-macro (format kmacro-x-mc-region-sequence-fmt
                                  (format-kbd-macro query))))
    (when highlight
      (highlight-regexp (regexp-quote query)
                        'kmacro-x-mc-highlight-face))
    (start-kbd-macro 'append 'no-exec)))

;;;###autoload
(defun kmacro-x-mc (&optional highlight)
  "A more user friendly version of `kmacro-x-mc-region'.

If selection is active, it does the same thing as
`kmacro-x-mc-region'.  If there is no active selection, it uses
the symbol at point instead.

See `kmacro-x-mc-region' for the HIGHLIGHT argument."
  (interactive "P")
  (let ((bounds (if (use-region-p)
                    (cons (region-beginning) (region-end))
                  (bounds-of-thing-at-point 'symbol))))
    (unless bounds
      (error "%s" "No region or symbol to act on"))
    (let ((start (car bounds))
          (end (cdr bounds)))
      (kmacro-x-mc-region start end highlight))))


;;;###autoload
(define-minor-mode kmacro-x-atomic-undo-mode
  "Undo the kmacro executions atomically."
  :global t
  :require 'kmacro-x
  :lighter " atomic-kmacro"
  (if kmacro-x-atomic-undo-mode
      (progn
        ;; Seemingly advising `execute-kbd-macro' should suffice, but
        ;; that's not true.  It might get called either from Elisp or
        ;; from `call-last-kbd-macro' which is a C function and so the
        ;; advice wouldn't apply for this call.  So we advice both to
        ;; cover hopefully all the possible entry points.
        (advice-add #'execute-kbd-macro :around
                    #'kmacro-x-undo-amalgamate-advice)
        (advice-add #'call-last-kbd-macro :around
                    #'kmacro-x-undo-amalgamate-advice))
    (advice-remove #'execute-kbd-macro
                   #'kmacro-x-undo-amalgamate-advice)
    (advice-remove #'call-last-kbd-macro
                   #'kmacro-x-undo-amalgamate-advice)))

(defun kmacro-x-undo-amalgamate-advice (orig &rest args)
  "Advice the ORIG function to amalgamate all the changes into one undo.

ARGS are passed verbatim to ORIG.

An undo boundary is placed beforehand to ensure the consecutive
calls won't get auto-amalgamated."
  (undo-boundary)
  (let ((cg (prepare-change-group)))
    (unwind-protect
        (progn
          (activate-change-group cg)
          (apply orig args))
      (undo-amalgamate-change-group cg)
      (accept-change-group cg))))


(provide 'kmacro-x)
;;; kmacro-x.el ends here
