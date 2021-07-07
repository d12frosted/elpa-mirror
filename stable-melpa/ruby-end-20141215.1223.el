;;; ruby-end.el --- Automatic insertion of end blocks for Ruby

;; Copyright (C) 2010-2012 Johan Andersson

;; Author: Johan Andersson <johan.rejeep@gmail.com>
;; Maintainer: Johan Andersson <johan.rejeep@gmail.com>
;; Version: 0.4.1
;; Package-Version: 20141215.1223
;; Package-Commit: a136f75abb6d5577ce40d61dfeb778c2e9bb09c0
;; Keywords: speed, convenience, ruby
;; URL: http://github.com/rejeep/ruby-end

;; This file is NOT part of GNU Emacs.


;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Commentary:

;; ruby-end is a minor mode for Emacs that can be used with ruby-mode
;; to automatically close blocks by inserting "end" when typing a
;; block-keyword, followed by a space.
;;
;; To use ruby-end-mode, make sure that this file is in Emacs load-path:
;;   (add-to-list 'load-path "/path/to/directory/or/file")
;;
;; Then require ruby-end:
;;   (require 'ruby-end)
;;
;; ruby-end-mode is automatically started in ruby-mode.


;;; Code:

(require 'ruby-mode)

(defvar ruby-end-expand-spc-key "SPC"
  "Space key name.")

(defvar ruby-end-expand-ret-key "RET"
  "Return key name.")

(defvar ruby-end-expand-on-ret t
  "Should return expand or not.")

(defvar ruby-end-mode-map
  (let ((map (make-sparse-keymap))
        (spc (read-kbd-macro ruby-end-expand-spc-key))
        (ret (read-kbd-macro ruby-end-expand-ret-key)))
    (define-key map spc 'ruby-end-space)
    (define-key map ret 'ruby-end-return)
    map)
  "Keymap for `ruby-end-mode'.")

(defcustom ruby-end-check-statement-modifiers t
  "*Disable or enable expansion (insertion of end) for statement modifiers"
  :type 'boolean
  :group 'ruby)

(defcustom ruby-end-insert-newline t
  "*Disable or enable additional newline in between statement and end"
  :type 'boolean
  :group 'ruby)

(defcustom ruby-end-expand-only-for-last-commands '(self-insert-command)
  "List of `last-command' values to restrict expansion to, or nil.

When nil, any `last-command' will do."
  :type '(repeat function)
  :group 'ruby)

(defconst ruby-end-expand-postfix-modifiers-before-re
  "\\(?:if\\|unless\\|while\\)"
  "Regular expression matching statements before point.")

(defconst ruby-end-expand-prefix-check-modifiers-re
  "^\\s-*"
  "Prefix for regular expression to prevent expansion with statement modifiers")

(defconst ruby-end-expand-prefix-re
  "\\(?:^\\|\\s-+\\)"
  "Prefix for regular expression")

(defconst ruby-end-expand-keywords-before-re
  "\\(?:^\\|\\s-+\\)\\(?:do\\|def\\|class\\|module\\|case\\|for\\|begin\\)"
  "Regular expression matching blocks before point.")


(defconst ruby-end-expand-after-re
  "\\s-*$"
  "Regular expression matching after point.")

(defun ruby-end-space ()
  "Called when SPC-key is pressed."
  (interactive)
  (cond
   ((ruby-end-expand-p)
    (ruby-end-insert-end)
    (insert " "))
   (t
    (ruby-end-fallback ruby-end-expand-spc-key))))

(defun ruby-end-return ()
  "Called when RET-key is pressed."
  (interactive)
  (cond
   ((and ruby-end-expand-on-ret (ruby-end-expand-p))
    (let ((ruby-end-insert-newline t))
      (ruby-end-insert-end))
    (forward-line 1)
    (indent-according-to-mode))
   (t
    (ruby-end-fallback ruby-end-expand-ret-key))))

(defun ruby-end-fallback (key)
  "Execute function that KEY was bound to before `ruby-end-mode'."
  (let ((ruby-end-mode nil))
    (call-interactively
     (key-binding (edmacro-parse-keys key) t))))

(defun ruby-end-insert-end ()
  "Closes block by inserting end."
  (let ((whites
         (save-excursion
           (back-to-indentation)
           (current-column))))
    (save-excursion
      (newline)
      (when ruby-end-insert-newline
        (indent-line-to (+ whites ruby-indent-level))
        (newline))
      (indent-line-to whites)
      (insert "end"))))

(defun ruby-end-expand-p ()
  "Check if expansion (insertion of end) should be done."
  (let ((ruby-end-expand-statement-modifiers-before-re
         (concat
          (if ruby-end-check-statement-modifiers
              ruby-end-expand-prefix-check-modifiers-re
            ruby-end-expand-prefix-re)
          ruby-end-expand-postfix-modifiers-before-re)))
    (and
     (or (not ruby-end-expand-only-for-last-commands)
         (memq last-command ruby-end-expand-only-for-last-commands))
     (ruby-end-code-at-point-p)
     (or
      (looking-back ruby-end-expand-statement-modifiers-before-re)
      (looking-back ruby-end-expand-keywords-before-re))
     (looking-at ruby-end-expand-after-re))))

(defun ruby-end-code-at-point-p ()
  "Check if point is code, or comment or string."
  (let ((properties (text-properties-at (point))))
    (and
     (null (memq 'font-lock-string-face properties))
     (null (memq 'font-lock-comment-face properties)))))

;;;###autoload
(define-minor-mode ruby-end-mode
  "Automatic insertion of end blocks for Ruby."
  :init-value nil
  :lighter " end"
  :keymap ruby-end-mode-map)

;;;###autoload
(add-hook 'ruby-mode-hook 'ruby-end-mode)
;;;###autoload
(add-hook 'enh-ruby-mode-hook 'ruby-end-mode)

(provide 'ruby-end)

;;; ruby-end.el ends here
