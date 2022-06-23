;;; markup.el --- Simple markup generation helpers.

;; Copyright (c) 2012 Arthur Leonard Andersen
;;
;; Author: Arthur Leonard Andersen <leoc.git@gmail.com>
;; URL: http://github.com/leoc/markup.el
;; Package-Version: 20170420.1129
;; Package-Commit: 876da2d3f23473475bb0fd0a1480ae11d2671291
;; Version: 2.0.1
;; Keywords: Convenience, Markup, HTML
;; Package-Requires: ((cl-lib "0.5"))
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
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

;; This is an emacs lisp port of the cl-markup library written in 2011
;; by Eitarow Fukamachi.

;;; Code:

(require 'cl-lib)

(defun keyword-name (keyword)
  (substring (format "%s" keyword) 1 nil))

(defun ensure-string (val)
  (if (stringp val)
      val
    (format "%s" val)))

(defun map-group-if (pred list fn)
  (cl-loop
   while list
   for cur = (pop list)
   for cur-res = (funcall pred cur)
   append
   (let ((res (nreverse
               (cl-loop with acc = (list cur)
                        while list
                        for x = (pop list)
                        if (eq cur-res (funcall pred x)) do
                        (push x acc)
                        else do
                        (progn (push x list)
                               (cl-return acc))
                        finally
                        (cl-return acc)))))
     (if cur-res (list (apply fn res)) res))))

(defun markup-escape-string (string)
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (while (search-forward "&" nil t)
      (replace-match "&amp;" nil t))
    (goto-char (point-min))
    (while (search-forward "<" nil t)
      (replace-match "&lt;" nil t))
    (goto-char (point-min))
    (while (search-forward ">" nil t)
      (replace-match "&gt;" nil t))
    (goto-char (point-min))
    (while (search-forward "'" nil t)
      (replace-match "&#039;" nil t))
    (goto-char (point-min))
    (while (search-forward "\"" nil t)
      (replace-match "&quot;" nil t))
    (buffer-string)))

(defmacro markup-raw (&rest forms)
  `(list ,@forms))

(defmacro markup-esc (&rest forms)
  `(list
    ,@(cl-loop for form in forms
               collect (markup-escape-string-form form))))

(defvar *markup-output-stream* nil
  "Stream to output the generated string. If this is nil, then just
return as a string the result. t means *standard-output*.")

(defvar *markup-language* :html5
  "Valid markup languages are :html, :html5, :xhtml and :xml")

(defun markup-should-escape-p (val)
  (not (and (stringp val)
            (string= val (markup-escape-string val)))))

(defmacro markup-write-strings (&rest strings)
  (let ((s (cl-gensym))
        (strings (map-group-if #'stringp strings
                               (lambda (&rest args)
                                 (apply #'concat args)))))
    `(if *markup-output-stream*
         (progn ,@(cl-loop for str in strings
                           collect `(princ ,str *markup-output-stream*)))
       (with-output-to-string
         ,@(cl-loop for str in strings
                    collect `(princ ,str))))))

(defmacro markup-escape-string-form (val)
  (let ((val2 (cl-gensym)))
    `(let ((,val2 ,val))
       (if (markup-should-escape-p ,val2)
           `(markup-escape-string ,,val2)
         ,val2))))

(defun markup-dirty-string-form (form)
  (cond
   ((consp form) (let ((res (cl-gensym))
                       (r (cl-gensym)))
                   `(let* ((*markup-language* ,*markup-language*)
                           (,res ,form))
                      (if (listp ,res)
                          (with-output-to-string
                            (dolist (,r ,res)
                              (if ,r (princ ,r))))
                        (markup-escape-string ,res)))))
   ((eq form nil) "")
   ((stringp form) (markup-escape-string-form form))
   ((symbolp form) `(markup-escape-string (ensure-string ,form)))
   (t (markup-escape-string-form (format "%s" form)))))

(defun markup-tagp (form)
  (and (consp form)
       (keywordp (car form))))

(defun markup-parse-tag (tag)
  "Splits the tag from into its single parts. Returns a form with the tag
name, a list of attributes and the body of the form."
  (cl-values
   (keyword-name (pop tag))
   (cl-loop while (and tag (keywordp (car tag)))
            collect (pop tag)
            collect (pop tag))
   tag))

(defun markup-attributes-to-string (attributes)
  "Converts the given attributes to a list of strings."
  (and (consp attributes)
       (butlast
        (cl-loop for (key val) on attributes by #'cddr
                 append
                 `(,(concat (downcase (keyword-name key))
                            "=\"")
                   ,(markup-dirty-string-form val)
                   "\""
                   " ")))))

(defun markup-element-to-string (tag)
  (cond ((markup-tagp tag)
         (cl-multiple-value-bind (name attributes body) (markup-parse-tag tag)
           (nconc
            (list (concat "<" name))
            (let ((attribute-string (markup-attributes-to-string attributes)))
              (if attribute-string
                  (cons " " attribute-string)))
            (if body
                (nconc (list ">")
                       (cl-loop for elem in body
                                if (markup-tagp elem)
                                append (markup-element-to-string elem)
                                else
                                collect (markup-dirty-string-form elem))
                       (list (concat "</" name ">")))
              (if (eq *markup-language* :xhtml)
		  (list " />")
		(list ">"))))))
        ((stringp tag)
         `(,tag))
        (t
         `(,(markup-dirty-string-form tag)))))


(defun markup-doctype (lang)
  (cl-case lang
    (:xml "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    (:html "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">")
    (:html5 "<!DOCTYPE html>")
    (:xhtml "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">")
    (t "")))

(defmacro markup-with-doctype (lang &rest body)
  `(markup-write-strings
    ,(markup-doctype lang)
    ,@(let ((*markup-language* lang))
        (cl-loop for element in body
                 append (eval element)))))

(defmacro markup (&rest elements)
  `(markup-write-strings
    ,@(cl-loop for element in elements
               append (markup-element-to-string element))))

(defun markup* (&rest tags)
  (eval `(markup ,@tags)))

(defmacro markup-html5 (&rest elements)
  `(markup-with-doctype :html5
                        (markup-element-to-string (cons :html ',elements))))

(defmacro markup-html (&rest elements)
  `(markup-with-doctype :html
                        (markup-element-to-string (cons :html ',elements))))

(defmacro markup-xhtml (&rest elements)
  `(markup-with-doctype :xhtml
                        (markup-element-to-string (cons :html ',elements))))

(defmacro markup-xml (&rest elements)
  `(markup-with-doctype :xml
     ,@(cl-loop for element in elements
                append `((markup-element-to-string ',element)))))

(provide 'markup)

;;; markup.el ends here
