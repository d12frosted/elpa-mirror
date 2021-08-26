;;; help-find.el --- Additional help functions for working with keymaps  -*- lexical-binding: t -*-

;; Copyright (C) 2021 Duncan Burke

;; Author: Duncan Burke <duncankburke@gmail.com>
;; Version: 0.0.1
;; Package-Version: 20210826.928
;; Package-Commit: 576d6505b9e42f50f121b1a6a675f17f03a04406
;; Package-Requires: ((emacs "25.2") (dash "2.12."))
;; Keywords: help
;; Homepage: https://github.com/duncanburke/help-find

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; help-find.el provides two functions, `help-find-keybinding` and
;; `help-find-function` which search the global `obarray` for all keymaps
;; which have that key sequence and function bound, respectively.

;;; Code:

(require 'dash)
(require 'help-mode)

(define-button-type 'help-find-keymap
  :supertype 'help-xref
  'help-function (progn (require 'help-fns+ nil t)
                        (if (symbol-function 'describe-keymap)
                            'describe-keymap
                          'describe-symbol))
  'help-echo (purecopy "mouse-2, RET: describe this keymap"))

(defun help-find--insert-text-keybinding (keys)
  "Insert text representing the keybinding KEYS. Whether it is
propertized depends on the version of Emacs."
  (if (symbol-plist 'help-key-binding)
      (insert (propertize keys
                          'face 'help-key-binding
                          'font-lock-face 'help-key-binding))
    (insert keys)))

;;;###autoload
(defun help-find-keybinding (keys)
  "Display all keymaps containing a binding for the key sequence KEYS.
KEYS is in `kbd' format. This searches all keymaps in the global
`obarray'.  Note that this will also find prefix keymaps, as
there is no way for it to know which keymaps will result in
top-level bindings."
  (interactive "MFind keybinding (kbd format): ")
  (let ((key-seq (kbd keys))
        (keymaps))
    (mapatoms (lambda (ob) (when (and (boundp ob)
                                      (keymapp (symbol-value ob))
                                      (let ((lookup (lookup-key (symbol-value ob) key-seq)))
                                        (when (and lookup
                                                   (not (numberp lookup)))
                                          (push ob keymaps)))))))
    (if (< (length keymaps) 1)
        (message "%s not found in any keymap." keys)
      (help-setup-xref (list #'help-find-keybinding keys)
                       (called-interactively-p 'interactive))
      (with-help-window (help-buffer)
        (with-current-buffer standard-output
          (help-find--insert-text-keybinding keys)
          (princ " found in the following keymaps:\n\n")
          (princ "keymap")
          (indent-to 40)
          (princ "binding\n")
          (princ "------")
          (indent-to 40)
          (princ "-------\n")
          (--map
           (progn
             (insert-text-button (symbol-name it)
                                 'type 'help-find-keymap
                                 'help-args (list it))
             (indent-to 40 1)
             (let ((lookup (lookup-key (symbol-value it) key-seq)))
               (cond
                ((symbolp lookup)
                 (cond
                  ((keymapp lookup)
                   (insert-text-button (symbol-name lookup)
                                       'type 'help-find-keymap
                                       'help-args (list lookup)))
                  ((functionp lookup)
                   (insert-text-button (symbol-name lookup)
                                       'type 'help-function
                                       'help-args (list lookup)))
                  (t
                   (insert-text-button (symbol-name lookup)
                                       'type 'help-symbol
                                       'help-args (list lookup)))))
                (t
                 (cond
                  ((keymapp lookup)
                   (princ "Prefix Command"))
                  (t
                   (princ "??"))))))
             (princ "\n"))
           keymaps))))))

;;;###autoload
(defun help-find-function (fn)
  "Display all keymaps containing a binding to the function FN.
This searches all keymaps in the global `obarray'."
  (interactive "aFind function: ")
  (let ((bindings (help-find--keymaps-lookup-function fn)))
    (if (< (length bindings) 1)
        (message "%s not found in any keymap." fn)
      (help-setup-xref (list #'help-find-function fn)
                       (called-interactively-p 'interactive))
      (with-help-window (help-buffer)
        (with-current-buffer standard-output
          (insert-text-button (symbol-name fn)
                              'type 'help-function
                              'help-args (list fn))
          (princ " is found in the following keymaps:\n\n")
          (princ "keymap")
          (indent-to 40)
          (princ "binding\n")
          (princ "------")
          (indent-to 40)
          (princ "-------\n")
          (--map
           (-map
            (lambda (keys)
              (insert-text-button (symbol-name (car it))
                                  'type 'help-find-keymap
                                  'help-args (list (car it)))
              (indent-to 40 1)
              (help-find--insert-text-keybinding (key-description keys))
              (princ "\n"))
            (cdr it))
           bindings))))))

(defun help-find--keymaps-lookup-function (fn)
  "Search for FN in all known keymaps."
  (let ((bindings))
    (mapatoms (lambda (ob)
                (when (and (boundp ob)
                           (keymapp (symbol-value ob))
                           (eq (intern (symbol-name ob)) ob))
                  (let ((keymap-bindings (help-find--keymap-lookup-function
                                          (symbol-value ob) fn)))
                    (when keymap-bindings
                      (push (cons ob keymap-bindings)
                            bindings)))))
              obarray)
    bindings))

(defun help-find--keymap-lookup-function (keymap fn)
  "Search KEYMAP for FN, recursively.  FN should be a symbol."
  (let ((bindings))
    (map-keymap
     (lambda (ev binding)
       (cond
        ((symbolp binding)
         (cond
          ((eq binding fn)
           (push (list (list ev)) bindings))
          ((and (boundp binding)
            (keymapp (symbol-value binding)))
           (push (--map (cons ev it)
                        (help-find--keymap-lookup-function
                         (symbol-value binding) fn))
                 bindings))))
        ((keymapp binding)
         (push (--map (cons ev it)
                      (help-find--keymap-lookup-function binding fn))
               bindings))))
     keymap)
    (apply #'-concat bindings)))

(provide 'help-find)
;;; help-find.el ends here
