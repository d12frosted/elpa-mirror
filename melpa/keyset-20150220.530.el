;;; keyset.el --- A small library for structuring key bindings.

;; Copyright (C) 2014  Hiroki YAMAKAWA

;; Author: Hiroki YAMAKAWA <s06139@gmail.com>
;; URL: https://github.com/HKey/keyset
;; Package-Version: 20150220.530
;; Package-Commit: 45ce83c4b56f064874256db37e697a63b2c69e65
;; Version: 0.1.2
;; Package-Requires: ((dash "2.8.0") (cl-lib "0.5"))
;; Keywords:

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

;;

;;; Code:

(require 'cl-lib)
(require 'dash)
(require 'edmacro)

(defvar keyset--modifiers-plist
  (list :A       "A"
        :H       "H"
        :M       "M"
        :s       "s"
        :S       "S"
        :C       "C"
        :alt     "A"
        :hyper   "H"
        :meta    "M"
        :super   "s"
        :shift   "S"
        :control "C"))

(defvar keyset--key-table (make-hash-table))

(defvar keyset-layout :default
  "Current layout for `keyset-key' and `keyset-key-string'.")

(defun keyset--parse-key-string (str)
  (--mapcat
   (if (or (symbolp it) (string= "-" it))
       (list it)
     (let* ((list (split-string it "-"))
            (mods (butlast list))
            (key (car (last list))))
       `(,@(--map (intern (concat ":" it)) mods) ,key)))
   (--map (if (numberp it)
              (format-kbd-macro (vector it))
            it)
          (edmacro-parse-keys str t))))

(defun keyset--get-key (name)
  (let* ((undef (cl-gensym))
         (plist (gethash name keyset--key-table undef)))
    (when (eq undef plist)
      (error (format "%s is not defined by `keyset-defkey'" name)))
    (or
     (plist-get plist keyset-layout)
     (plist-get plist :default))))

;;;###autoload
(defun keyset-defkey (name default &rest layout-keys)
  "Define key sequence as NAME.
NAME is a keyword which does not mean a modifier key.
LAYOUT is a keyword which is a name of the layout.
DEFAULT and KEY are a `kbd' style string or a list of arguments
 of `keyset-key'.
This function returns NAME.

\(fn NAME DEFAULT LAYOUT KEY LAYOUT KEY ...)"
  (setf (gethash name keyset--key-table)
        (cl-loop for (layout key) on `(:default ,default ,@layout-keys)
                 by 'cddr
                 append (list layout
                              (if (stringp key)
                                  (keyset--parse-key-string key)
                                key))))
  name)

;;;###autoload
(defun keyset-key-string (&rest params)
  "Get key sequence like `keyset-key', but return a string.
Returned value is not designed for `define-key'."
  (edmacro-format-keys (apply #'keyset-key params)))

;;;###autoload
(defun keyset-key (&rest params)
  "Get key sequence for `define-key'.
PARAMS are anything below:
- a `kbd' style string
- a symbol
- a keyword which means a modifier key (e.g. :C, :M, and :shift)
- a keyword which means a name of key sequence defined by `keyset-defkey'
- a list of these elements

Examples:
  (keyset-key :key-seq-name)
  (keyset-key :C \"x\" :C \"c\")"
  (cl-labels
      ((modifierp (x) (plist-get keyset--modifiers-plist x))
       (expand (x)
               (cond ((listp x) (-map #'expand x))
                     ((modifierp x) x)
                     ((keywordp x) (expand (keyset--get-key x)))
                     ((symbolp x) x)
                     (x (keyset--parse-key-string x))))
       (to-string (x)
                  (cond ((modifierp x) (plist-get keyset--modifiers-plist x))
                        ((symbolp x) (format-kbd-macro (vector x)))
                        (x)))
       (join (separator list) (mapconcat 'identity list separator))
       (upcase-maybe (list)
                     (let ((key (-last-item list)))
                       (if (and (or (memq :S list) (memq :shift list))
                                (not (or (memq :C list) (memq :control list)))
                                (stringp key)
                                (string-match-p "[a-zA-Z]" key))
                           (append
                            (-butlast (-reduce-r 'remq (list :S :shift list)))
                            (list (upcase key)))
                         list))))
    (cl-coerce
     (cl-loop for item in (-flatten (-map #'expand params))
              with tmp = nil
              collect item into tmp
              unless (modifierp item)
              collect (aref
                       (edmacro-parse-keys
                        (join "-"
                              (-map #'to-string (upcase-maybe (-uniq tmp))))
                        t)
                       0)
              and do (setq tmp nil))
     'vector)))

(provide 'keyset)
;;; keyset.el ends here
