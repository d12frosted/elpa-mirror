;;; popup-imenu.el --- imenu index popup

;; Author: Igor Shymko <igor.shimko@gmail.com>
;; Version: 0.6.1
;; Package-Version: 20210404.1153
;; Package-Commit: b00c4d503cbbaf01c136b1647329e6a6257d012c
;; Package-Requires: ((dash "2.12.1") (popup "0.5.3") (flx-ido "0.6.1"))
;; Keywords: popup, imenu
;; URL: https://github.com/ancane/popup-imenu

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
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; Shows imenu index in a popup window. Fuzzy matching supported.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(eval-when-compile (require 'cl))

(require 'dash)
(require 'popup)
(require 'imenu)
(require 'flx-ido)

(defgroup popup-imenu nil
  "Shows imenu index in a popup window."
  :group 'imenu
  :link '(url-link :tag "popup-imenu @ GitHub"
                   "https://github.com/ancane/popup-imenu"))

(defcustom popup-imenu-fuzzy-match t
  "Turns on flx matching."
  :group 'popup-imenu
  :type 'boolean
  :safe #'booleanp)

(defcustom popup-imenu-hide-rescan t
  "Hide *Rescan* menu item."
  :group 'popup-imenu
  :type 'boolean
  :safe #'booleanp)

(defcustom popup-imenu-position 'point
  "Defines popup position.  Possible values are:
'point - open popup at point. (default option)
'center - opens popup at window center
'fill-column - center relative to `fill-column'"
  :group 'popup-imenu
  :type '(choice
          (const :tag "point - open popup at point" point)
          (const :tag "center - opens popup at window center" center)
          (const :tag "fill-column - center relative to `fill-column'" fill-column)))

(defcustom popup-imenu-style 'flat
  "Defines a way to present hierarchical imenus. Possible values are:
'flat - flattened imenu representation
'indent - subitems indented by 2 spaces"
  :group 'popup-imenu
  :type '(choice
          (const :tag "flat - flattened imenu representation" flat)
          (const :tag "indent - subitems indented by 2 spaces" indent)))

(defcustom popup-imenu-force-position nil
  "When popup position, as calculated according to 'center or 'fill-column settings,
points to a line that is not long enough, then popup will not be open at
'center or 'fill-column position.
Setting this var to `t' will add whitespaces at the end of the line to reach the column."
  :group 'popup-imenu
  :type 'boolean
  :safe #'booleanp)

(defcustom popup-imenu-max-items 15
  "Maximum number of elements in a mouse menu for Imenu."
  :group 'popup-imenu
  :type 'integer)

(defun popup-imenu--filter ()
  "Function that return either flx or a regular filtering function."
  (if popup-imenu-fuzzy-match
      'popup-imenu--flx-match
    'popup-isearch-filter-list))

(defun popup-imenu--flx-match (query items)
  "Flx filtering function.
QUERY - search string
ITEMS - popup menu items list"
  (if (> (length query) 0)
      (let ((flex-result (flx-flex-match query items)))
        (let* ((matches (cl-loop for item in flex-result
                                 for string = (ido-name item)
                                 for score = (flx-score string query flx-file-cache)
                                 if score
                                 collect (cons item score)
                                 into matches
                                 finally return matches)))
          (popup-imenu--flx-decorate
           (sort matches
                 (lambda (x y) (> (cadr x) (cadr y))))
           )))
    items))

(defun popup-imenu--flx-decorate (things)
  "Highlight imenu items matching search string.
THINGS - popup menu items list"
  (if flx-ido-use-faces
      (let ((decorate-count (min ido-max-prospects
                                 (length things))))
        (nconc
         (cl-loop for thing in things
                  for i from 0 below decorate-count
                  collect (popup-imenu--propertize thing))
         (mapcar 'car (nthcdr decorate-count things))))
    (mapcar 'car things)))

(defun popup-imenu--propertize (thing)
  "Add value property to imenu item to be returned in case of thing selection.
THING - imenu item."
  (let* ((item-value (popup-item-value (car thing)))
         (flx-propertized (flx-propertize (car thing) (cdr thing))))
    (popup-item-propertize flx-propertized 'value item-value)))

(defun popup-imenu--flatten-index (imenu-index)
  "Flatten imenu index into a plain list.
IMENU-INDEX - imenu index tree."
  (-mapcat
   (lambda (x)
     (if (imenu--subalist-p x)
         (mapcar (lambda (y)
                   (if (string= "." (car y))
                       (cons (car x) (cdr y))
                     (cons (concat (car x) ":" (car y)) (cdr y))
                     )
                   )
                 (popup-imenu--flatten-index (cdr x)))
       (list x)))
   imenu-index))

(defun popup-imenu--indent-index (imenu-index &optional indent)
  "Indent hierarchical subitems with spaces.
IMENU-INDEX - imenu index tree."
  (-mapcat
   (lambda (x)
     (if (imenu--subalist-p x)
         (let* ((first-subitem (car (cdr x)))
		(first-subitem-rest (cdr first-subitem))
                (cur-item (if (consp first-subitem-rest)
			      (car first-subitem-rest)
			    (cons (car x) first-subitem-rest)))
                (cur-subitems (if (string= "." (car first-subitem))
                                  (cdr (cdr x))
                                (cdr x)
                                )))
           (cons cur-item
                 (mapcar (lambda (y) (cons (concat (or indent "  ") (car y)) (cdr y)))
                         (popup-imenu--indent-index cur-subitems (concat indent "  ")))))
       (list x)))
   imenu-index))

(defun popup-imenu--build-popup-items-in-style (index-items)
  (if (eq popup-imenu-style 'flat)
      (mapcar
       (lambda (x) (popup-make-item (car x) :value x))
       (popup-imenu--flatten-index index-items))
    (mapcar
     (lambda (x) (popup-make-item (car x) :value x))
     (popup-imenu--indent-index index-items)))
  )

(defun popup-imenu--index ()
  "Build imenu index."
  (let ((popup-index (imenu--make-index-alist)))
    (if popup-imenu-hide-rescan
        (delq imenu--rescan-item popup-index)
      popup-index
      )))

(defun popup-imenu--pos (menu-height popup-items)
  "Return the position for a popup menu.
MENU-HEIGHT - required menu height,
POPUP-ITEMS - items to be shown in the popup."
  (if (eq popup-imenu-position 'point)
      (point)
    (let* ((line-number (save-excursion
                          (goto-char (window-start))
                          (line-number-at-pos)))
           (x (+ (/ (- (if (eq popup-imenu-position 'center) (window-width) fill-column)
                       (apply 'max (mapcar (lambda (z) (length (car z))) popup-items)))
                    2)
                 (window-hscroll)))
           (y (+ (- line-number 2)
                 (/ (- (window-height) menu-height) 2))))
      (popup-imenu--point-at-col-row x y)
      )))

(defun popup-imenu--point-at-col-row (column row)
  (save-excursion
    (forward-line row)
    (move-to-column column popup-imenu-force-position)
    (point)))

(defun popup-imenu--jump-to (selected)
    (pcase selected
      (`(,name ,pos ,fn . ,args)
       (push-mark nil t)
       (apply fn name pos args)
       (run-hooks 'imenu-after-jump-hook))
      (`(,name . ,pos) (popup-imenu--jump-to (list name pos imenu-default-goto-function)))
      (_ (error "Unknown imenu item: %S" selected))))

;;;###autoload
(defun popup-imenu ()
  "Open the popup window with imenu items."
  (interactive)
  (let* ((popup-list (popup-imenu--index))
         (popup-items (popup-imenu--build-popup-items-in-style popup-list))
         (menu-height (min popup-imenu-max-items (length popup-items) (- (window-height) 4)))
         (selected (popup-menu*
                    popup-items
                    :point (popup-imenu--pos menu-height popup-list)
                    :height menu-height
                    :isearch t
                    :isearch-filter (popup-imenu--filter)
                    :scroll-bar nil
                    :margin-left 1
                    :margin-right 1
                    )))
    (popup-imenu--jump-to selected)))

(provide 'popup-imenu)

;;; popup-imenu.el ends here
