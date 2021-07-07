;;; hamburger-menu.el --- Mode line hamburger menu  -*- lexical-binding: t -*-

;; Copyright © 2016 Iain Nicol

;; Author: Iain Nicol
;; Maintainer: Iain Nicol
;; URL: https://gitlab.com/iain/hamburger-menu-mode
;; Package-Version: 20160825.2031
;; Package-Commit: 3568159c693c30bed7f61580e4f3b6241253ad4e
;; Version: 1.0.5
;; Keywords: hamburger, menu
;; Package-Requires: ((emacs "24.5"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; A minor mode which adds a hamburger menu button to the mode line.
;;
;; Use instead of `menu-bar-mode' to save vertical space.  The
;; hamburger menu is particularly useful when
;; `mouse-autoselect-window' (Focus Follows Mouse) is enabled.
;;
;; ## Installation
;;
;; Add the [MELPA](https://melpa.org/) repository to Emacs.  Then run:
;;
;;     M-x package-install hamburger-menu
;;
;; Afterwards, configure as follows:
;;
;; 1. Disable `menu-bar-mode', because having two menus is superfluous:
;;
;;        M-x customize-set-variable RET menu-bar-mode RET n
;;        M-x customize-save-customized
;;
;; 2. Add the following to your `~/.emacs'.  This will place the
;;    hamburger menu button at the very left of your mode line:
;;
;;        (require 'hamburger-menu)
;;        (setq mode-line-front-space 'hamburger-menu-mode-line)
;;
;; 3. Restart Emacs.  Enjoy.
;;
;; On the off chance you consider modifying `mode-line-front-space' to
;; be overly invasive, you can instead enable
;; `global-hamburger-menu-mode'.  The downside of the mode is that the
;; hamburger menu button it provides cannot be nicely aligned at the
;; left of the mode line.
;;
;;; Change Log:
;;
;; Run `git log' in the repository.

;;; Code:

(require 'menu-bar)
(require 'mouse)
(require 'tmm)

(defconst hamburger-menu--symbol "☰")
(defconst hamburger-menu--indicator (format " %s" hamburger-menu--symbol)
  "Indicator for the minor mode in the mode line.
Contains whitespace before the symbol to improve the look when
squashed up next to other minor mode indicators.")

(defun hamburger-menu--obey-final-items (final-items keymap)
  "Return a keymap respecting FINAL-ITEMS, based upon KEYMAP.
This typically places the Help menu last, after menu items
specific to the major mode."
  ;; This method is borrowed from tmm.el.
  (let ((menu-bar '())
        (menu-end '()))
    (map-keymap
     (lambda (key binding)
       (push (cons key binding)
             ;; If KEY is the name of an item that we want to put last,
             ;; move it to the end.
             (if (memq key final-items)
                 menu-end
               menu-bar)))
     keymap)
    `(keymap
      ,@(reverse menu-bar)
      ,@(reverse menu-end))))

(defun hamburger-menu--items ()
  "The menu items for the popup."
  (let ((menu-main (tmm-get-keybind [menu-bar])))
    (hamburger-menu--obey-final-items menu-bar-final-items menu-main)))

(defun hamburger-menu--items-add-heading (items)
  "Add a heading to the menu items, ITEMS.
The heading is for consistency with the popups of other modes in
the mode line."
  `(keymap (hamburger-menu-heading menu-item
				   "Hamburger Menu")
	   (sep-hamburger-menu "--")
	   ,items))

;;; Minor mode.

(defun hamburger-menu--minor-mode-menu-from-indicator--advice
    (overridden &rest args)
  "Override `minor-mode-menu-from-indicator', for the hamburger menu.
OVERRIDDEN is the underlying function
`minor-mode-menu-from-indicator', and ARGS are its arguments."
  (let ((indicator (car args)))
    (if (string-equal indicator hamburger-menu--indicator)
	(popup-menu
	 (hamburger-menu--items-add-heading (hamburger-menu--items)))
      (apply overridden args))))

(defun hamburger-menu--enable ()
  "Enable Hamburger Menu mode."
  (advice-add #'minor-mode-menu-from-indicator
	      :around
	      #'hamburger-menu--minor-mode-menu-from-indicator--advice)
  ;; Message is disabled because it behaved badly with the
  ;; minibuffer, interfering with completions.  To reproduce:
  ;;     C-h f advice- TAB
  ;; (message "Hamburger Menu enabled."))
  )

(defun hamburger-menu--disable ()
  "Disable Hamburger Menu mode."
  ;; Ideally we'd advice-remove.  But I'm not sure how to check
  ;; whether the advice is still needed for other buffers.

  ;; No message here because there's no corresponding message in
  ;; --enable.
  ;; (message "Hamburger Menu disabled."))
  )

;;;###autoload
(define-minor-mode hamburger-menu-mode
  "Mode which adds a hamburger menu button to the mode line."
  :lighter hamburger-menu--indicator
  (if hamburger-menu-mode
      (hamburger-menu--enable)
    (hamburger-menu--disable)))

(defun hamburger-menu-mode-on ()
  "Turn on, or leave turned on, Hamburger Menu mode."
  (hamburger-menu-mode 1))

;;;###autoload
(define-globalized-minor-mode
  global-hamburger-menu-mode
  hamburger-menu-mode hamburger-menu-mode-on)

;;; Explicit mode line customization.

(defvar hamburger-menu--mode-line-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line mouse-1]
      (lambda (e)
	(interactive "e")
	(popup-menu (hamburger-menu--items) e)))
    ;; bindings.el loves to pure copy, so we do too.
    (purecopy map))
  "Keymap for `hamburger-menu-mode-line'.")

(defvar hamburger-menu-mode-line
  `(,(propertize
      hamburger-menu--symbol
      'help-echo "Hamburger Menu\nmouse-1: Display popup menu"
      'local-map hamburger-menu--mode-line-map))
  "Mode line construct for displaying a hamburger menu button.

As opposed to `hamburger-menu-mode', this allows you to force the
hamburger-menu to be at a particular location on the mode line.
To do so, add this variable to `mode-line-format'.")

;; Required for `mode-line-format' to respect our use of propertize.
;;;###autoload
(put 'hamburger-menu-mode-line 'risky-local-variable t)

;;; Bye.

(provide 'hamburger-menu)
;;; hamburger-menu.el ends here
