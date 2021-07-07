;;; hookify.el --- Interactive commands to create temporary hooks

;; Author: Philippe Vaucher <philippe.vaucher@gmail.com>
;; URL: https://github.com/Silex/hookify
;; Package-Version: 20141216.2209
;; Package-Commit: 21baae7393b07257de5796402fde0ca72fb00d77
;; Keywords: hook, convenience
;; Version: 0.2.1
;; Package-Requires: ((s "1.9.0") (dash "1.5.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This library provides interactive commands to create temporary hooks
;;
;;; Code:

(require 's)
(require 'dash)

(defun hookify-is-hook-p (symbol)
  "Returns t if SYMBOL is a hook."
  (and (boundp symbol)
       (s-ends-with? "-hook" (symbol-name symbol))))

;;;###autoload
(defun hookify (hook form &optional global remove)
  "Append or remove a lambda containing FORM to HOOK.

If GLOBAL is true, make a global hook, otherwise a local one.
If REMOVE is true, removes the form from the hook, otherwise append it."
  (interactive
   (list (intern (completing-read "Hook: " obarray 'hookify-is-hook-p t))
         (let ((minibuffer-completing-symbol t))
           (read-from-minibuffer "Form: " nil read-expression-map t 'read-expression-history))
         (equal (read-char-exclusive "Global hook (default: no) ? (y/n) ") ?y)
         current-prefix-arg))
  (if remove
      (remove-hook hook `(lambda () ,form) (not global))
    (add-hook hook `(lambda () ,form) nil (not global))))

(provide 'hookify)

;;; hookify.el ends here
