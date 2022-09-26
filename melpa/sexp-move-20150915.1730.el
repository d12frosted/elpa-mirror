;;; sexp-move.el --- Improved S-Expression Movement -*- lexical-binding: t -*-

;; Copyright © 2015 Philip Woods

;; Author: Philip Woods <elzairthesorcerer@gmail.com>
;; Version: 0.2.6
;; Package-Version: 20150915.1730
;; Package-Commit: 117f7a91ab7c25e438413753e916570122011ce7
;; Keywords: sexp
;; URL: https://gitlab.com/elzair/sexp-move

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides two interactive functions to traverse syntactic
;; elements common to S-Expressions and the languages that use them:
;; Scheme, Common Lisp, Clojure, etc.

;; The two functions are `sexp-move-forward' and `sexp-move-backward'.

;;; Code:

(defvar *sexp-move-read-table*
  (make-hash-table)
  "Symbol table for `sexp-move'.")

(defun sexp-move-whitespace (dir)
  "Traverse whitespace in the specified direction, DIR."
  (if (> dir 0)
      (forward-char)
    (backward-char))
  (while (and (if (> dir 0)
                  (< (point) (point-max))
                (> (point) (point-min)))
              (member (get-char-code-property (if (> dir 0)
                                                  (char-after)
                                                (char-before))
                                              'general-category)
                      '(Cc Zl Zp Zs)))
    (if (> dir 0)
        (forward-char)
      (backward-char))))

(defun sexp-move-symbol (dir)
  "Traverse a symbol in the specified direction, DIR."
  (if (> dir 0)
      (forward-char)
    (backward-char))
  (while (and (if (> dir 0)
                  (< (point) (point-max))
                (> (point) (point-min)))
              (member (get-char-code-property (if (> dir 0)
                                                  (char-after)
                                                (char-before))
                                              'general-category)
                      '(LC Ll Lm Lo Lt Lu Mc Me Mn Nd
                           Nl No Pc Pd Po Sc Sk Sm So))
              (not (member (string (char-after))
                           '("'" "\"" "`" ","))))
    (if (> dir 0)
        (forward-char)
      (backward-char))))

(defun sexp-move-single (dir)
  "Traverse a single character in the specified direction, DIR."
  (if (> dir 0)
      (forward-char)
    (backward-char)))

(puthash (intern "(")  #'sexp-move-single     *sexp-move-read-table*)
(puthash (intern ")")  #'sexp-move-single     *sexp-move-read-table*)
(puthash (intern "[")  #'sexp-move-single     *sexp-move-read-table*)
(puthash (intern "]")  #'sexp-move-single     *sexp-move-read-table*)
(puthash (intern "{")  #'sexp-move-single     *sexp-move-read-table*)
(puthash (intern "}")  #'sexp-move-single     *sexp-move-read-table*)
(puthash (intern "'")  #'sexp-move-single     *sexp-move-read-table*)
(puthash (intern ",")  #'sexp-move-single     *sexp-move-read-table*)
(puthash (intern "`")  #'sexp-move-single     *sexp-move-read-table*)
(puthash (intern ";")  #'sexp-move-single     *sexp-move-read-table*)
(puthash (intern "\"") #'sexp-move-single     *sexp-move-read-table*)
(puthash 'Cc           #'sexp-move-whitespace *sexp-move-read-table*)
(puthash 'LC           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Ll           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Lm           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Lo           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Lt           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Lu           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Mc           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Me           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Mn           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Nd           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Nl           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'No           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Pc           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Pd           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Po           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Sc           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Sk           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Sm           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'So           #'sexp-move-symbol     *sexp-move-read-table*)
(puthash 'Zl           #'sexp-move-whitespace *sexp-move-read-table*)
(puthash 'Zp           #'sexp-move-whitespace *sexp-move-read-table*)
(puthash 'Zs           #'sexp-move-whitespace *sexp-move-read-table*)

(defun sexp-move-forward ()
    "Move cursor position forward by one S-Expression lexeme."
    (interactive)
    (let* ((char    (char-after))
           (sym     (intern (string char)))
           (cat     (get-char-code-property char 'general-category))
           (fst-res (gethash sym *sexp-move-read-table*)))
      (if (not (null fst-res))
          (funcall fst-res 1)
          (funcall (gethash cat *sexp-move-read-table*) 1))))

(defun sexp-move-backward ()
    "Move cursor position backward by one S-Expression lexeme."
    (interactive)
    (let* ((char    (char-before))
           (sym     (intern (string char)))
           (cat     (get-char-code-property char 'general-category))
           (fst-res (gethash sym *sexp-move-read-table*)))
      (if (not (null fst-res))
          (funcall fst-res -1)
          (funcall (gethash cat *sexp-move-read-table*) -1))))

(provide 'sexp-move)
;;; sexp-move.el ends here
