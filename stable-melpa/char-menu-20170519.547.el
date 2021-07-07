;;; char-menu.el --- Create your own menu for fast insertion of arbitrary symbols -*- lexical-binding: t; -*-
;;
;; Copyright © 2016–2017 Mark Karpov <markkarpov92@gmail.com>
;;
;; Author: Mark Karpov <markkarpov92@gmail.com>
;; URL: https://github.com/mrkkrp/char-menu
;; Package-Version: 20170519.547
;; Package-Commit: f4d8bf8fa6787e2aaca2ccda5223646541d7a4b2
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.3") (avy-menu "0.1"))
;; Keywords: convenience, editing
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

;; This package allows to insert arbitrary symbols in Emacs in a very
;; efficient and straightforward way.  Whether you ever need to insert only
;; a couple of proper punctuation symbols or you're a Unicode geek who likes
;; all sorts of arrows and fancy math symbols, this package may be of some
;; use.
;;
;; Features:
;;
;; * it allows you organize all symbols you ever need into a hierarchy you
;;   define;
;;
;; * in that tree-like structure most frequently used commands will require
;;   only one key-press, while others may get dedicated section (for
;;   example, “arrows”) so you first select that section and then you choose
;;   a symbol in it;
;;
;; * it makes sense to have paired characters in that menu, like “” (and for
;;   that matter arbitrary combinations of symbols);
;;
;; * however insertion of paired characters will place the point between
;;   them;
;;
;; * …and if you insert paired characters while some text is selected, they
;;   will wrap it.

;;; Code:

(require 'avy-menu)
(require 'cl-lib)

(defgroup char-menu nil
  "A menu for efficient insertion of arbitrary symbols."
  :group  'convenience
  :tag    "Char Menu"
  :prefix "char-menu-"
  :link   '(url-link :tag "GitHub" "https://github.com/mrkkrp/char-menu"))

(defcustom char-menu '("—" "‘’" "“”" "…")
  "The char menu.

This is a list containing either menu items directly as strings,
or sub-menus as lists where the first element is sub-menu header
and the rest is menu items.

Usually every insertable menu item is one character long, but
paired characters will have additional support for insertion and
wrapping of selected text."
  :tag "The menu to show"
  :type '(repeat
          (choice
           (string :tag "Symbol to insert")
           (cons   :tag "Sub-menu"
                   (string :tag "Sub-menu header")
                   (repeat (string :tag "Symbol to insert"))))))

;;;###autoload
(defun char-menu (&optional menu header)
  "Display the given MENU and insert selected item, if any.

See information about format of the menu in documentation of
`char-menu'.  If no argument is supplied, menu from that variable
will be used.  Note that MENU should not be empty, or error will
be signalled.

HEADER, if supplied, will be appended to the default menu
header."
  (interactive)
  (let ((menu (or menu char-menu)))
    (unless menu
      (error "Cannot display empty menu"))
    (let ((selection
           (avy-menu
            "*char-menu*"
            (cons (concat "Character Menu"
                          (when header
                            (format " | %s" header)))
                  (list
                   (cons "Pane"
                         (mapcar #'char-menu--make-item menu)))))))
      (if (consp selection)
          (cl-destructuring-bind (header . sub-menu) selection
            (char-menu sub-menu header))
        (char-menu--insert selection)))))

(defun char-menu--make-item (item)
  "Format ITEM in the way suiteable for use with `avy-menu'."
  (cons (if (consp item)
            (car item)
          item)
        item))

(defun char-menu--insert (str)
  "Insert STR at point handling special cases like paired characters."
  (let ((p (char-menu--pairp str)))
    (if (and p mark-active)
        (let ((beg (region-beginning))
              (end (1+ (region-end))))
          (goto-char beg)
          (insert (elt str 0))
          (goto-char end)
          (insert (elt str 1)))
      (insert str)
      (when p
        (backward-char 1)))))

(defun char-menu--pairp (str)
  "Select STR representing paired character sequence."
  (and (= (length str) 2)
       (cl-every
        (lambda (x)
          (memq (get-char-code-property x 'general-category)
                '(Pi Pf)))
        str)))

(provide 'char-menu)

;;; char-menu.el ends here
