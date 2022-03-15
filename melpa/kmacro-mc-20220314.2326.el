;;; kmacro-mc.el --- Multiple cursors emulation with keyboard macros  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Wojciech Siewierski

;; Author: Wojciech Siewierski
;; URL: https://github.com/vifon/kmacro-mc.el
;; Package-Version: 20220314.2326
;; Package-Commit: 3dbb208b25381f84dffc0859a6a744058038686d
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

;; A set of commands to facilitate the usual multiple-cursors
;; workflows with the use of regular keyboard macros (kmacros).
;; This way all the pitfalls of rolling a custom implementation are
;; avoided, while all the kmacro facilities, such as counters, queries
;; and kmacro editing, are gained virtually for free.

;; It is assumed the user didn't rebind the basic isearch commands,
;; otherwise the behavior may be unpredictable.

;; A typical workflow with `kmacro-mc-region':
;;
;; 1. Select the text whose occurences are to be manipulated (in
;;    a trivial case: a symbol to be renamed).
;; 2. M-x kmacro-mc-region RET
;; 3. Do the necessary edits, either within the region or in its
;;    vicinity outside of it (this is the part that cannot be achieved
;;    with other mc alternatives such as iedit or query-replace).
;;    They will get recorded as a kmacro.
;; 4. Press any key that would end the kmacro recording:
;;    F4, C-x ) or C-x C-k C-k
;; 5. Repeat the kmacro with F4, C-x e or C-x C-k C-k.

;;; Code:

(require 'kmacro)


(defgroup kmacro-mc nil
  "Multiple cursors emulation with keyboard macros."
  :group 'kmacro)

(defface kmacro-mc-highlight-face
  '((t (:inherit hi-yellow)))  ;`highlight-regexp' hardcodes `hi-yellow'
  "The face used by `kmacro-mc-region'.")

(defcustom kmacro-mc-region-sequence-fmt "C-s %s C-r RET 2*C-s RET"
  "The sequence of keys used by `kmacro-mc-region'.

This sequence should search for the next occurrence of the query
and leave the region in a predictable state for the user to use.

The search query will be spliced into it using `format', and so
it should contain exactly one `%s' placeholder."
  :type 'string)


;;;###autoload
(defun kmacro-mc-region (start end &optional highlight)
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
  (let ((query (buffer-substring-no-properties start end)))
    (when (< (point) (mark))
      (exchange-point-and-mark))
    (deactivate-mark)
    (kmacro-push-ring)
    (setq last-kbd-macro
          (read-kbd-macro (format kmacro-mc-region-sequence-fmt
                                  (format-kbd-macro query))))
    (when highlight
      (highlight-regexp (regexp-quote query)
                        'kmacro-mc-highlight-face))
    (start-kbd-macro 'append 'no-exec)))


;;;###autoload
(define-minor-mode kmacro-mc-atomic-undo-mode
  "Undo the kmacro executions atomically."
  :global t
  :require 'kmacro-mc
  :lighter " atomic-kmacro"
  (if kmacro-mc-atomic-undo-mode
      (progn
        ;; Seemingly advising `execute-kbd-macro' should suffice, but
        ;; that's not true.  It might get called either from Elisp or
        ;; from `call-last-kbd-macro' which is a C function and so the
        ;; advice wouldn't apply for this call.  So we advice both to
        ;; cover hopefully all the possible entry points.
        (advice-add #'execute-kbd-macro :around
                    #'kmacro-mc-undo-amalgamate-advice)
        (advice-add #'call-last-kbd-macro :around
                    #'kmacro-mc-undo-amalgamate-advice))
    (advice-remove #'execute-kbd-macro
                   #'kmacro-mc-undo-amalgamate-advice)
    (advice-remove #'call-last-kbd-macro
                   #'kmacro-mc-undo-amalgamate-advice)))

(defun kmacro-mc-undo-amalgamate-advice (orig &rest args)
  "Advice the ORIG function to amalgamate all the actions into one undo.

ARGS are passed verbatim to ORIG.

An undo boundary is being placed to ensure the consecutive calls
won't get auto-amalgamated."
  (undo-boundary)
  (let ((cg (prepare-change-group)))
    (unwind-protect
        (progn
          (activate-change-group cg)
          (apply orig args))
      (undo-amalgamate-change-group cg)
      (accept-change-group cg))))


(provide 'kmacro-mc)
;;; kmacro-mc.el ends here
