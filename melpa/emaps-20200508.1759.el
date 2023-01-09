;;; emaps.el --- Utilities for working with keymaps -*- lexical-binding: t; -*-

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Copyright (C) 2016-2018, 2020 Ben Moon
;; Author: Ben Moon <software@guiltydolphin.com>
;; URL: https://github.com/GuiltyDolphin/emaps
;; Package-Version: 20200508.1759
;; Package-Commit: 7c561f3ded2015ed3774e5784059d6601082743e
;; Git-Repository: git://github.com/GuiltyDolphin/emaps.git
;; Created: 2016-06-20
;; Version: 0.2.0
;; Keywords: convenience, keyboard, keymap, utility
;; Package-Requires: ((dash "2.17.0") (emacs "24"))

;;; Commentary:

;; Emaps provides utilities for working with keymaps and keybindings in Emacs.
;;
;; Emaps provides the `emaps-define-key' function that provides the same
;; functionality as `define-key', but allows multiple keys to be defined
;; at once, for example:
;;
;;    (emaps-define-key keymap
;;      "a" 'fun-a
;;      "b" 'fun-b
;;      "c" 'fun-c) ; etc.
;;
;; Emaps also provides the following functions for viewing keymaps:
;;
;;    * `emaps-describe-keymap-bindings' provides a *Help* buffer similar
;;       to `describe-bindings', but works for any keymap.
;;    * `emaps-describe-keymap' provides a *Help* buffer similar to
;;      `describe-variable', but attempts to normalize character display
;;      where possible.

;;; Code:

(require 'dash)

(defgroup emaps nil
  "Utilities for working with keymaps."
  :group 'convenience
  :group 'keyboard
  :prefix 'emaps-)

(defcustom emaps-key-face 'font-lock-constant-face
  "Face used by when displaying keys."
  :group 'emaps
  :type 'face)

(defmacro emaps--with-modify-help-buffer (body)
  "Execute BODY with the current help buffer active; allow modifications."
  `(with-current-buffer (get-buffer "*Help*")
     (let ((buffer-read-only nil))
       ,body
       (set-buffer-modified-p nil))))

(defun emaps--bound-symbol-p (x)
  "Return non-NIL if X is a symbol with a value."
  (and (symbolp x) (boundp x)))

(defun emaps--active-keymap-p (x)
  "Return non-NIL if X is a keymap that is currently active."
  (and (keymapp x) (memq x (current-active-maps))))

(defun emaps--completing-read-variable (prompt &optional pred def)
  "Prompt the user with PROMPT for a variable that satisfied PRED (if supplied).

If DEF is supplied and satisfies PRED, use that as the default value, otherwise use the value of `variable-at-point'."
  (let* ((enable-recursive-minibuffers t)
         (check
          (lambda (it)
            (and (emaps--bound-symbol-p it)
                 (if pred (funcall pred (symbol-value it)) t))))
         (v (or (and (funcall check def) def)
                (let ((var (variable-at-point)))
                  (and (funcall check var) var))))
         vars
         val)
    (mapatoms (lambda (atom) (when (funcall check atom) (push atom vars))))
    (setq val (completing-read
               (if (funcall check v)
                   (format
                    (concat prompt " (default %s): ") v)
                 (concat prompt ": "))
               vars
               check
               t nil nil
               (if (funcall check v) (symbol-name v))))
    (list (if (equal val "") v (intern val)))))

(defun emaps--keymap-symbol-p (x)
  "Return non-NIL if X is a symbol for a keymap."
  (and (emaps--bound-symbol-p x) (keymapp (symbol-value x))))

(defun emaps--keymap-symbol-at-point ()
  "The keymap symbol at point, if any."
  (let ((vap (variable-at-point)))
    (and (emaps--keymap-symbol-p vap) vap)))

(defun emaps--read-keymap (&optional active-only)
  "Read the name of a keymap from the minibuffer and return it as a symbol.

If ACTIVE-ONLY is non-NIL, allow selection only from active keymaps."
  (emaps--completing-read-variable
   "Enter keymap" (if active-only #'emaps--active-keymap-p 'keymapp)
   ;; if there is a keymap at point, use this as the default as the
   ;; user probably means to query this, otherwise default to the
   ;; keymap variable for the current major mode.
   (or (emaps--keymap-symbol-at-point) (emaps--keymap-symbol-for-mode major-mode))))

;;;###autoload
(defun emaps-describe-keymap (keymap)
  "Display the full documentation of KEYMAP (a symbol).

When interactively called with a prefix argument, prompt only for active keymaps.

Unlike `describe-variable', this will display characters as strings rather than integers."
  (interactive (emaps--read-keymap current-prefix-arg))
  (describe-variable keymap)
  (emaps--with-modify-help-buffer
   (save-excursion
     (while (search-forward-regexp "(\\([0-9]+\\) ." nil t)
       (let ((keychar (string-to-number (match-string 1))))
         (when (characterp keychar)
           (replace-match (propertize (char-to-string keychar) 'face emaps-key-face) nil t nil 1)))))))

(defun emaps--get-available-binding-as-string (prefix)
  "Repeat PREFIX until there is an available binding (and return it as a string)."
  (let ((repeated prefix))
    (while (key-binding (kbd repeated))
      (setq repeated (concat repeated " " repeated)))
    repeated))

;;;###autoload
(defun emaps-describe-keymap-bindings (keymap)
  "Like `describe-bindings', but only describe bindings in KEYMAP.

When interactively called with a prefix argument, prompt only for active keymaps."
  (interactive (progn (emaps--read-keymap current-prefix-arg)))
  (let* ((keymap-name (if (emaps--keymap-symbol-p keymap) (symbol-name keymap) "?"))
         (keymap (if (emaps--keymap-symbol-p keymap) (symbol-value keymap) keymap))
         (temp-map '(keymap))
         (prefix (emaps--get-available-binding-as-string "a")))
    (define-key temp-map (kbd prefix) keymap)
    (with-help-window (help-buffer)
      (with-current-buffer (help-buffer)
        (let ((overriding-terminal-local-map temp-map)
              (overriding-local-map temp-map)
              (overriding-local-map-menu-flag t)
              (check-buffer (current-buffer))
              (buffer-read-only nil))
          (describe-buffer-bindings check-buffer (kbd prefix))
          (goto-char (point-min))
          (save-excursion
            (search-forward-regexp "^key")
            (delete-region (point-min) (match-beginning 0))
            (search-forward-regexp "\C-l\nGlobal")
            (delete-region (match-beginning 0) (point-max)))
          (save-excursion
            (insert (format "Describing bindings for '%s\n" keymap-name))
            (while (search-forward-regexp (format "\\(^\\|..\\)\\(%s \\)" prefix) nil t)
              (replace-match "" nil nil nil 2)))
          (set-buffer-modified-p nil))))))

(defun emaps--keymap-symbol-for-mode (mode)
  "Return the keymap symbol for MODE (or NIL if none exists)."
  (let ((mode-map-symbol (intern (concat (symbol-name mode) "-map"))))
    (when (emaps--keymap-symbol-p mode-map-symbol) mode-map-symbol)))

;;;###autoload
(defun emaps-keymap-for-mode (mode)
  "Return the keymap for MODE (or NIL if none exists)."
  (let ((mode-map-symbol (emaps--keymap-symbol-for-mode mode)))
    (and (emaps--keymap-symbol-p mode-map-symbol) (symbol-value mode-map-symbol))))

;;;###autoload
(defun emaps-define-key (keymap key def &rest bindings)
  "Create a binding in KEYMAP from KEY to DEF and each key def pair in BINDINGS.

See `define-key' for the forms that KEY and DEF may take."
  (let ((defs (append (list key def) bindings)))
    (dotimes (n (/ (length defs) 2))
      (let ((key (nth (* n 2) defs))
            (def (nth (+ (* n 2) 1) defs)))
        (define-key keymap key def)))))
(put 'emaps-define-key 'lisp-indent-function 'defun)

(provide 'emaps)
;;; emaps.el ends here
