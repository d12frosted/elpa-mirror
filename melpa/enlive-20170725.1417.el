;;; enlive.el --- query html document with css selectors

;; Copyright (C) 2015 ZHOU Feng

;; Author: ZHOU Feng <zf.pascal@gmail.com>
;; URL: http://github.com/zweifisch/enlive
;; Package-Version: 20170725.1417
;; Package-Commit: 604a8ca272b6889f114e2b5a13adb5b1dc4bae86
;; Keywords: css selector query
;; Version: 0.0.1
;; Created: 2st July 2015

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; query html document with css selectors
;;

;;; Code:
(require 'cl)

(defun enlive-parse (input)
  (with-temp-buffer
    (insert input)
    (libxml-parse-html-region (point-min) (point-max))))

(defalias 'enlive-parse-region 'libxml-parse-html-region)

(defun enlive-fetch (url &optional encoding timeout)
  (with-timeout ((or timeout 5) nil)
    (with-current-buffer (url-retrieve-synchronously url)
      (goto-char (point-min))
      (search-forward-regexp "\n[\t\n ]*\n+")
      (decode-coding-region (point) (point-max) (or encoding 'utf-8))
      (libxml-parse-html-region (point) (point-max)))))

(defun enlive-is-element (element)
  (and (listp element) (symbolp (car element))))

(defun enlive-direct-children (element)
  (when (enlive-is-element element)
    (cdr (cdr element))))

(defun enlive-text (element)
  (if (stringp element) element
    (let ((result ""))
      (dolist (child (enlive-direct-children element))
        (setq result (concat result (enlive-text child))))
      result)))

(defun enlive-attr (element attr)
  (cdr (assoc attr (cadr element))))

(defun enlive-has-class (element class)
  (let ((class-names (enlive-attr element 'class)))
    (when class-names 
      (member class (split-string class-names)))))

(defun enlive-some (element predict)
  (if (funcall predict element) element
    (let (result)
      (dolist (child (enlive-direct-children element))
        (when (and (listp child) (null result))
          (let ((r (enlive-get-element-by-id child id)))
            (when r (setq result r)))))
      result)))

(defun enlive-filter (element predict)
  (let ((results (when (and (enlive-is-element element) (funcall predict element)) (list element)))
         (children (enlive-direct-children element)))
    (when children
      (dolist (child children)
        (when (listp child)
          (let ((elements (enlive-filter child predict)))
            (when elements
              (setq results (append results elements)))))))
    results))

(defun enlive-get-elements-by-class-name (element class)
  (enlive-filter element (lambda (node) (enlive-has-class node class))))

(defun enlive-get-elements-by-tag-name (element tag)
  (enlive-filter element (lambda (node) (eq tag (car node)))))

(defun enlive-get-element-by-id (element id)
  (enlive-some element (lambda (node) (string= id (enlive-attr node 'id)))))

(defun enlive-all (element)
  (enlive-filter element (lambda (node) t)))

(defun enlive-match-element (element criteria)
  (when (enlive-is-element element)
    (when
        (loop for (type . val) in criteria
              always (pcase type
                       (`id (string= val (enlive-attr element 'id )))
                       (`class (enlive-has-class element val))
                       (`tag (string= (symbol-name (car element)) val))))
      (list element))))

(defun enlive-find-elements (element criteria)
  (enlive-filter element (lambda (node) (enlive-match-element node criteria))))

(defun enlive-tokenize (selector)
  "selector should be tag:id.cls.cls2"
  (let ((tokens '())
        (type 'tag)
        (value nil)
        (collect (lambda () (when value (push (cons type value) tokens) (setq value nil)))))
    (dotimes (i (length selector))
      (let ((c (char-to-string (elt selector i))))
        (cond ((string= ":" c) (funcall collect) (setq type 'id))
              ((string= "." c) (funcall collect) (setq type 'class))
              (t (setq value (concat value c))))))
    (funcall collect)
    (nreverse tokens)))

(defun enlive-parse-selector (selector)
  (let ((result '()))
    (dotimes (n (length selector))
      (let ((current (elt selector n))
            (prev (when (> n 0) (elt selector (- n 1)))))
        (when (and prev (not (eq prev '>)) (not (eq current '>)))
          (push '(enlive-direct-children node) result))
        (push (cond ((eq current '>) '(enlive-direct-children node))
                    ((eq current '*) '(enlive-all node))
                    (t `(,(if (eq prev '>) 'enlive-match-element 'enlive-find-elements)
                         node ',(enlive-tokenize (symbol-name current)))))
              result)))
    (nreverse result)))

(defun enlive-query-all (element selector)
  (let ((criteria (enlive-parse-selector selector))
        (element (if (enlive-is-element element) (list element) element)))
    (while (and element criteria)
      (let ((head (car criteria)))
        (setq criteria (cdr criteria))
        (setq element (apply 'append (delq nil (eval `(mapcar (lambda (node) ,head) element)))))))
    element))

(defun enlive-query (element selector)
  (car (enlive-query-all element selector)))

(defun enlive-insert-element (exp)
  (let ((exp (mapcar (lambda (x) (if (listp x) (enlive-insert-element x) x)) exp)))
    (if (member (car exp) '(enlive-query enlive-query-all))
        (append (list (car exp) element) (cdr exp))
      exp)))

(defmacro enlive-with (element &rest body)
  (cons 'progn
        (mapcar 'enlive-insert-element body)))

(defmacro enlive-let (element bindings &rest body)
  (append
   (list (append (list 'lambda (mapcar 'car bindings)) body))
        (mapcar (lambda (x) (list 'enlive-query-all element (cadr x))) bindings)))

(provide 'enlive)
;;; enlive.el ends here
