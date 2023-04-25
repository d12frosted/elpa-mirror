;;; tabgo.el --- Jump to tabs, avy style -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Isa Mert Gurbuz

;; Author: Isa Mert Gurbuz <isamertgurbuz@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20230425.907
;; Package-Commit: 1a2f6b2b75c1829eb7acd188086b14fb75d9c7d1
;; Homepage: https://github.com/isamert/tabgo.el
;; License: GPL-3.0-or-later
;; Package-Requires: ((emacs "27.1"))

;; This program is free software; you can redistribute it and/or modify
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

;; tabgo is a package that allows the user to switch between tabs in a
;; graphical and more intuitive way, like avy.

;; Typically you'll want to bind `tabgo' function to a key.
;;
;;     (define-key global-map (kbd "M-t") #'tabgo)
;;
;; Once you have bound `tabgo', you can call it by pressing the key
;; you bound it to.  You'll see that highlighted characters appear on
;; the tab-bar and tab-line tab names.  Simply press the one that you
;; want to go to and `tabgo' will switch to it for you.

;;; Code:

(require 'map)
(require 'tab-line)
(require 'tab-bar)

(defgroup tabgo nil
  "Jump to tabs, avy style."
  :group 'convenience
  :prefix "tabgo-")

(defface tabgo-face
  '((t (:weight bold :background "blue" :foreground "white")))
  "Face used for the leading chars.")

(defcustom tabgo-tab-bar-keys "1234567890-="
  "Keys to use for selecting tab-bar tabs."
  :group 'tabgo
  :type '(choice
          (string :tag "String containing the characters")
          (repeat character :tag "List of characters")))

(defcustom tabgo-tab-line-keys "qwertyuiop[]"
  "Keys to use for selecting tab-line tabs."
  :group 'tabgo
  :type '(choice
          (string :tag "String containing the characters")
          (repeat character :tag "List of characters")))

(defun tabgo--nth (n xs)
  "Select Nth element from XS.
XS can be an array or list."
  (if (stringp xs)
      (aref xs n)
    (nth n xs)))

(defun tabgo--get-key (type index)
  "Get a key for INDEX.
TYPE can be either \\='line or \\='tab."
  (let* ((keys (pcase type
                 ('line tabgo-tab-line-keys)
                 ('bar tabgo-tab-bar-keys))))
    (if (>= (1+ index) (length keys))
        "?"
      (propertize (format "%c" (tabgo--nth index keys)) 'face 'tabgo-face))))

(defmacro tabgo--with-tab-line-highlighted (&rest forms)
  "Highlight tab-line tabs and execute FORMS."
  `(let* ((tabgo-tab-line-map (make-hash-table :test #'equal))
          (old-tab-line-fn tab-line-tab-name-format-function)
          (tab-line-tab-name-format-function
           (lambda (tab tabs)
             (let ((key (tabgo--get-key 'line (seq-position tabs 'dummy (lambda (it _) (equal tab it)))))
                   (old-format (funcall old-tab-line-fn tab tabs)))
               (map-put! tabgo-tab-line-map (substring-no-properties key) tab)
               (format "%s%s" key (substring old-format 1))))))
     (set-window-parameter nil 'tab-line-cache nil)
     (force-mode-line-update t)
     ,@forms
     (force-mode-line-update t)))

(defmacro tabgo--with-tab-bar-highlighted (&rest forms)
  "Highlight tab-bar tabs and execute FORMS."
  `(let* ((tabgo-tab-bar-map (make-hash-table :test #'equal))
          (old-tab-bar-fn tab-bar-tab-name-format-function)
          (tab-bar-tab-name-format-function
           (lambda (tab i)
             (let* ((key (tabgo--get-key 'bar (1- i)))
                    (old-format (funcall old-tab-bar-fn tab i))
                    (new-format (format "%s%s" key (substring old-format 1))))
               ;; HACK If tab-bar-auto-width is non-nil, then the text
               ;; property of the first char becomes important for
               ;; some reason and we can't override it with
               ;; tabgo-face. Thus, we put our `key' as the second
               ;; char in this case.
               (when tab-bar-auto-width
                 (setq new-format (format "~%s%s" key (substring old-format 2)))
                 (add-text-properties 0 1 (text-properties-at 0 old-format) new-format))
               (map-put! tabgo-tab-bar-map (substring-no-properties key) i)
               (if (string= old-format new-format)
                   ;; HACK If new-format and old-format equal to
                   ;; each other string-wise, even if the text
                   ;; properties are different, tab-bar is not
                   ;; updated with new text properties. So we do
                   ;; some changes the original text.
                   (let ((placeholder "~"))
                     ;; If the old-format has the X button at the
                     ;; end, the resulting new-format will look
                     ;; exactly the same (except for the leading
                     ;; char's face). Otherwise they'll see a "~" at
                     ;; the end of their tab name, instead of what
                     ;; it's supposed to be.
                     (add-text-properties 0 1 (text-properties-at (1- (length new-format)) new-format) placeholder)
                     (format "%s%s" (substring new-format 0 (1- (length new-format))) placeholder))
                 new-format)))))
     (force-mode-line-update t)
     ,@forms
     (force-mode-line-update t)))

(defun tabgo-line ()
  "Jump to tabs on the tab-line."
  (interactive)
  (tabgo--with-tab-line-highlighted
   (let ((result (read-key "Which?")))
     (set-window-parameter nil 'tab-line-cache nil)
     (when-let (selected (map-elt tabgo-tab-line-map result))
       (switch-to-buffer selected)))))

(defun tabgo-bar ()
  "Jump to tabs on the tab-bar."
  (interactive)
  (tabgo--with-tab-bar-highlighted
   (let ((result (char-to-string (read-key "Which?"))))
     (when-let (selected (map-elt tabgo-tab-bar-map result))
       (tab-bar-select-tab selected)))))

(defun tabgo ()
  "Jump to tabs on either tab-bar or tab-line."
  (interactive)
  (tabgo--with-tab-bar-highlighted
   (tabgo--with-tab-line-highlighted
    (let ((result (format "%c" (read-key "Which?"))))
      (set-window-parameter nil 'tab-line-cache nil)
      (when-let (selected (map-elt tabgo-tab-line-map result))
        (switch-to-buffer selected))
      (when-let (selected (map-elt tabgo-tab-bar-map result))
        (tab-bar-select-tab selected))))))

(provide 'tabgo)
;;; tabgo.el ends here
