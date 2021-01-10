;;; iterator.el --- A library to create and use elisp iterators objects. -*- lexical-binding: t -*-

;; Author: Thierry Volpiatto <thierry dot volpiatto at gmail dot com>

;; Copyright (C) 2009 ~ 2014 Thierry Volpiatto, all rights reserved.

;; Compatibility: GNU Emacs 24.1+
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))
;; Package-Version: 20210109.1859
;; Package-Commit: b514d4d1d0167e5973afbc93a34070d1aa967d82

;; Version: 1.0
;; X-URL: https://github.com/thierryvolpiatto/iterator

;; This file is not part of GNU Emacs. 

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.


;;; Code:

(require 'cl-lib)

(cl-defsubst iterator:position (item seq &key (test 'eq))
  "Get position of ITEM in SEQ.
A simple replacement of CL `position'."
  (cl-loop for i in seq for index from 0
           when (funcall test i item) return index))

(defun iterator:list (seq)
  "Return an iterator from SEQ."
  (let ((lis seq))
     (lambda ()
       (let ((elm (car lis)))
         (setq lis (cdr lis))
         elm))))

(defun iterator:next (iterator)
  "Return next elm of ITERATOR."
  (and iterator (funcall iterator)))

(cl-defun iterator:sub-next (seq elm &key (test 'eq))
  "Create iterator from position of ELM to end of SEQ."
  (let* ((pos      (iterator:position elm seq :test test))
         (sub      (nthcdr (1+ pos) seq))
         (iterator (iterator:list sub)))
    (lambda ()
      (iterator:next iterator))))

(cl-defun iterator:sub-prec (seq elm &key (test 'eq))
  "Create iterator from position of ELM to beginning of SEQ."
  (let* ((rev-seq  (reverse seq))
         (pos      (iterator:position elm rev-seq :test test))
         (sub      (nthcdr (1+ pos) rev-seq))
         (iterator (iterator:list sub)))
    (lambda ()
      (iterator:next iterator))))

(defun iterator:circular (seq)
  "Infinite iteration on SEQ."
  (let ((lis seq))
     (lambda ()
       (let ((elm (car lis)))
         (setq lis (pcase lis (`(,_ . ,ll) (or ll seq))))
         elm))))

(cl-defun iterator:sub-prec-circular (seq elm &key (test 'eq))
  "Infinite reverse iteration of SEQ starting at ELM."
  (let* ((rev-seq  (reverse seq))
         (pos      (1+ (iterator:position elm rev-seq :test test)))
         (sub      (append (nthcdr pos rev-seq) (cl-subseq rev-seq 0 pos)))
         (iterator (iterator:circular sub)))
    (lambda ()
      (iterator:next iterator))))

(cl-defun iterator:sub-next-circular (seq elm &key (test 'eq))
  "Infinite iteration of SEQ starting at ELM."
  (let* ((pos      (1+ (iterator:position elm seq :test test)))
         (sub      (append (nthcdr pos seq) (cl-subseq seq 0 pos)))
         (iterator (iterator:circular sub)))
    (lambda ()
      (iterator:next iterator))))

(defun iterator:apply-fun-on-list (fun seq)
  "Create an iterator that apply function FUN on each elm of SEQ."
  (let ((lis seq)
        (fn fun))
    (lambda ()
      (let ((elm (if (car lis)
                     (funcall fn (car lis)))))
        (setq lis (cdr lis))
        elm))))

(cl-defun iterator:scroll-list (seq &optional (size (length seq)))
  "Create an iterator on all the cons cells of SEQ of length SIZE.

Similar to (cl-loop for i on SEQ collect i).

Example:
    (setq lst '(a b c d e))
    (setq iter (iterator:scroll-list lst))
    ;; Each call of:
    (iterator:next iter)
    ;; returns
    => (a b c d e)
    => (b c d e)
    => (c d e)
    => (d e)
    => (e)
    => nil "
  (let ((lis seq)
        (end size))
    (lambda ()
      (let ((sub (cl-subseq lis 0 end)))
        (setq lis (cdr lis))
        (when (< (length lis) end)
          (setq end (- end 1)))
        (delq nil sub)))))

(cl-defun iterator:scroll-up (seq elm &optional (size (length seq)))
  "Same as `iterator:scroll-list' but start al ELM and scroll up SEQ.

IOW Move from right to left in SEQ.

Example:

    (setq lst '(a b c d e))
    (setq iter (iterator:scroll-list lst))
    ;; Each call of:
    (iterator:next iter)
    ;; Returns
    =>(a b c d e)
    =>(b c d e)
    =>(c d e)

    (setq iter (iterator:scroll-up lst (iterator:next iter)))
    ;; Each call of:
    (iterator:next iter)
    ;; Returns
    =>(a b c)
    =>(a b)
    =>(a) "
  (when elm
    (let* ((pos (cl-position (if (listp elm) (car elm) elm) seq))
           (sub (reverse (cl-subseq seq 0 pos)))
           (iterator (iterator:scroll-list sub size)))
      (lambda ()
        (reverse (iterator:next iterator))))))

(cl-defun iterator:scroll-down (seq elm &optional (size (length seq)))
  "Same as `iterator:scroll-up' but move from left to right in SEQ."
  (when elm
    (let* ((pos (cl-position (if (listp elm) (car elm) elm) seq))
           (sub (cl-subseq seq pos))
           (iterator (iterator:scroll-list sub size)))
      (lambda ()
        (iterator:next iterator)))))

(defun iterator:fibo ()
  "Fibonacci generator."
  (let ((a 0)
        (b 1))
    (lambda ()
      (cl-psetq a b
                b (+ a b))
      a)))

;;; Provide
(provide 'iterator)

;; Local Variables:
;; byte-compile-warnings: (not cl-functions obsolete)
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; iterator.el ends here
