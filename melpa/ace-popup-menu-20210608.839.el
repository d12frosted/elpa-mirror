;;; ace-popup-menu.el --- Replace GUI popup menu with something more efficient -*- lexical-binding: t; -*-
;;
;; Copyright © 2015–present Mark Karpov <markkarpov92@gmail.com>
;;
;; Author: Mark Karpov <markkarpov92@gmail.com>
;; URL: https://github.com/mrkkrp/ace-popup-menu
;; Package-Version: 20210608.839
;; Package-Commit: bc3524eaa28b21725287b59b903c03624cbd5316
;; Version: 0.2.1
;; Package-Requires: ((emacs "24.3") (avy-menu "0.1"))
;; Keywords: convenience, popup, menu
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package allows to replace the GUI popup menu (created by
;; `x-popup-menu' by default) with a little textual window.  In this window,
;; menu items are displayed and labeled with one or two letters.

;;; Code:

(require 'avy-menu)
(require 'cl-lib)

(defgroup ace-popup-menu nil
  "Replace GUI popup menu with something more efficient."
  :group  'convenience
  :tag    "Ace popup menu"
  :prefix "ace-popup-menu-"
  :link   '(url-link :tag "GitHub" "https://github.com/mrkkrp/ace-popup-menu"))

(defcustom ace-popup-menu-show-pane-header nil
  "Whether to print headers of individual panes in Ace Popup Menu."
  :tag "Show pane header"
  :type 'boolean)

;;;###autoload
(define-minor-mode ace-popup-menu-mode
  "Toggle the `ace-popup-menu-mode' minor mode.

With a prefix argument ARG, enable `ace-popup-menu-mode' if ARG
is positive, and disable it otherwise.  If called from Lisp,
enable the mode if ARG is omitted or NIL, and toggle it if ARG is
`toggle'.

This minor mode is global. When it's active any call to
`x-popup-menu' will result in a call of `ace-popup-menu'
instead. That function in turn implements a more efficient
interface to select an option from a list. Emacs Lisp code can
also use `ace-popup-menu' directly."
  :global t
  (if ace-popup-menu-mode
      (advice-add 'x-popup-menu :around #'ace-popup-menu)
    (advice-remove 'x-popup-menu #'ace-popup-menu)))

;;;###autoload
(defun ace-popup-menu (orig-fun position menu)
  "Pop up a menu in a temporary window and return user's selection.

If POSITION is nil or MENU is a keymap or list of keymaps, the
original `x-popup-menu' function is called via ORIG-FUN instead
of `avy-menu'.  To understand the format of the MENU argument,
see documentation for `x-popup-menu'."
  (if (and position
           (not (keymapp menu))
           (not (keymapp (car-safe menu))))
      (avy-menu "*ace-popup-menu*"
                menu
                ace-popup-menu-show-pane-header)
    (funcall orig-fun position menu)))

(provide 'ace-popup-menu)

;;; ace-popup-menu.el ends here
