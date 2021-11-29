;;; html-to-hiccup.el --- Convert HTML to Hiccup syntax

;; Copyright (C) 2016 Arne Brasseur, Jack Rusher

;; Author: Arne Brasseur <arne@arnebrasseur.net>
;; URL: https://github.com/plexus/html-to-hiccup
;; Package-Version: 20211129.944
;; Package-Commit: 97ecc8cce11f577ad4406da0367aa5eeec1bd8c6
;; Version: 1.0
;; Created: 27 October 2016
;; Keywords: HTML Hiccup Clojure
;; Package-Requires: ((emacs "25.1") (dash "2.13.0") (s "1.10.0"))

;; This file is NOT part of GNU Emacs.

;;; License:

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

;;; Attribution :

;; The first version was written by Arne Brasseur, then vastly cleaned up by
;; Jack Rusher, then Arne gave it some finishing touches.

;;; Commentary:

;; There is a single interactive command, `html-to-hiccup-convert-region',
;; which parses the current region as HTML, and replaces it with the
;; equivalent Hiccup.  This is especially useful when doing Clojure
;; development and copying HTML snippets from the web.

;; This package does not contain any keybindings, bind it to whatever you see
;; fit.

;; Goes well with `cider-format-edn-region', or with fresh lemonade.

;;; Code:

(require 's)
(require 'dash)
(require 'subr-x)

(defun html-to-hiccup--sexp-to-hiccup-tag (elem tag-class?)
  "Generate Hiccup for the HTML ELEM tag + id + (iff TAG-CLASS?)
class shorthands."
  (let ((attrs (cadr elem)))
    (concat ":" (symbol-name (car elem))
            (when-let ((id (cdr (assoc 'id attrs))))
              (concat "#" id))
            (when tag-class?
              (when-let ((class (cdr (assoc 'class attrs))))
                (concat "." (s-replace " " "." (s-trim class))))))))

(defun html-to-hiccup--sexp-to-hiccup-attrs (attrs attrs-remove-class?)
  "Generate a Hiccup ATTRS map with the class attribute removed
when ATTRS-REMOVE-CLASS?."
  (if-let ((attrs (--map (format ":%s %S" (car it) (cdr it))
                         (assq-delete-all 'id
                           (if attrs-remove-class?
                               (assq-delete-all 'class attrs)
                             attrs)))))
      (concat " {" (s-join " " attrs) "}")))

(defun html-to-hiccup--sexp-to-hiccup-children (cs)
  "Recursively render Hiccup children, skipping empty (whitespace) strings."
  (s-join "" (--map (if (stringp it)
                        (when (string-match "[^\s\n]" it) ; contains non-whitespace
                          (format " %S" it))
                      (concat " " (html-to-hiccup--sexp-to-hiccup it)))
                    cs)))

(defun html-to-hiccup--sexp-to-hiccup (html-sexp)
  "Turn a html-sexp (as returned by libxml-parse-*) into a Hiccup element."
  (let* ((attrs (cadr html-sexp))
         (class (cdr (assoc 'class attrs)))
         ;; not all class chars are valid for shorthand syntax
         (tag-class-shorthand? (when class (not (s-contains? "/" class)))))
    (concat "["
            (html-to-hiccup--sexp-to-hiccup-tag html-sexp tag-class-shorthand?)
            (html-to-hiccup--sexp-to-hiccup-attrs attrs tag-class-shorthand?)
            (html-to-hiccup--sexp-to-hiccup-children (cddr html-sexp))
            "]")))

;;;###autoload
(defun html-to-hiccup-convert-region (start end &optional bodytags)
  "Convert the region between START and END from HTML to Hiccup."
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (let ((html-sexp (if bodytags
                           (nth 2  (nth 2 (libxml-parse-html-region (point-min) (point-max))))
                           (libxml-parse-html-region (point-min) (point-max)))))
	(delete-region (point-min) (point-max))
	(insert (html-to-hiccup--sexp-to-hiccup html-sexp))))))

(provide 'html-to-hiccup)

;;; html-to-hiccup.el ends here
