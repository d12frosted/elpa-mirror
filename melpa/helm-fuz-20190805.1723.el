;;; helm-fuz.el --- Integrate Helm and Fuz -*- lexical-binding: t -*-

;; Copyright (C) 2019 Zhu Zihao

;; Author: Zhu Zihao <all_but_last@163.com>
;; URL: https://github.com/cireu/fuz.el
;; Package-Version: 20190805.1723
;; Package-Commit: 90ca9207a9c1decda24a552b94ff41169ecccb14
;; Version: 1.3.0
;; Package-Requires: ((emacs "25.1") (fuz "1.3.0") (helm "3.2"))
;; Keywords: convenience

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Fuzzy sorting support for `helm'.

;; By using this package, you should enable `helm-fuz-mode' after
;; loaded `helm'.

;;; Code:

(require 'inline)
(require 'fuz)
(require 'fuz-extra)
(require 'helm)
(require 'helm-command)

(eval-when-compile
  (require 'pcase)
  (require 'subr-x))

;;; Type Alias

;; (define-type Cand (U Str (Cons Str Str)))

;;; Customize

(defgroup helm-fuz ()
  "Sort `helm' candidates by fuz."
  :group 'helm
  :prefix "helm-fuz-")

(defcustom helm-fuz-sorting-method 'skim
  "The fuzzy sorting method in use.

The value should be `skim' or `clangd', skim's scoring function is a little
slower but return better result than clangd's."
  :type '(choice
          (const :tag "Skim" skim)
          (const :tag "Clangd" clangd))
  :group 'helm-fuz)

;; Internal use variables

(defvar helm-fuz-old-fuzzy-sort-fn nil)
(defvar helm-fuz-old-fuzzy-highlight-match-fn nil)
(defvar helm-fuz-old-M-x-fuzzy-sort-fn nil)

;;; Utils

(define-inline helm-fuz--fuzzy-indices (pattern str)
  "Return all char positions where STR fuzzy matched with PATTERN.

Sign: (-> Str Str (Option (Listof Long)))"
  (inline-quote
   (pcase-exhaustive helm-fuz-sorting-method
     (`clangd (fuz-find-indices-clangd ,pattern ,str))
     (`skim (fuz-find-indices-skim ,pattern ,str)))))

(define-inline helm-fuz--fuzzy-score (pattern str)
  "Calc the fuzzy match score of STR with PATTERN.

Sign: (-> Str Str Long)"
  (inline-quote
   (or (pcase-exhaustive helm-fuz-sorting-method
         (`clangd (fuz-calc-score-clangd ,pattern ,str))
         (`skim (fuz-calc-score-skim ,pattern ,str)))
       most-negative-fixnum)))

(define-inline helm-fuz--fuzzy-match (pattern str)
  "Return the fuzzy match result of STR with PATTERN.

Sign: (-> Str Str (Option (Listof Long)))"
  (inline-quote
   (pcase-exhaustive helm-fuz-sorting-method
     (`clangd (fuz-fuzzy-match-clangd ,pattern ,str))
     (`skim (fuz-fuzzy-match-skim ,pattern ,str)))))

(defun helm-fuz--get-cand-str (cand &optional use-real? basename?)
  "Return the real string of CAND.

Sign: (->* (Cand) (Bool Bool) Str)

If USE-REAL? and PATTERN is a cons, use the `cdr' of PATTERN, otherwise use `car'.
If BASENAME?, use `helm-basename' to transfrom PATTERN."
  (let* ((visitor (if use-real? #'cdr #'car)))
    (cond ((and basename? (consp cand))
           (helm-basename (funcall visitor cand)))
          ((consp cand) (funcall visitor cand))
          (basename? (helm-basename cand))
          (t cand))))

(defun helm-fuz--get-single-cand-score-data (pattern cand
                                             &optional
                                               use-real? basename?)
  "Return (LENGTH SCORE) by matching CAND with PATTERN.

Sign: (->* (Str Cand) (Bool Bool) (Vector Long Long))

USE-REAL? and BASENAME? will be passed to `helm-fuz--get-cand-str' to get the
real candidate string."
  (let* ((realstr (helm-fuz--get-cand-str cand use-real? basename?))
         (len (length realstr)))
    ;; FIXME: Short pattern may have higher score matching longer pattern
    ;; than exactly matching itself
    ;; e.g. "ielm" will prefer [iel]m-[m]enu than [ielm]
    (if (string= realstr pattern)
        (vector len most-positive-fixnum)
      (vector len (helm-fuz--fuzzy-score pattern realstr)))))

(defun helm-fuz-fuzzy-matching-sort-fn-1! (pattern
                                           cands
                                           data-fn
                                           &optional
                                             preserve-tie-order?)
  "Main helper of helm sorting functions.

Sign: (->* (Str (Listof Cand) (-> Str Cand (Vector Long Long)))
           (Bool)
           (Listof Cand))

PATTERN and each candidate of CANDS will be passed to DATA-FN to calcuate fuzzy
matching data, then sort CANDS with those data. If PRESERVE-TIE-ORDER? is nil,
tie in scores are sorted by length of the candidates."
  (if (string= pattern "")
      cands
    (let* ((len (length cands))
           (memo-data-fn (fuz-memo-function (lambda (cand)
                                              (funcall data-fn pattern cand))
                                            #'equal
                                            len)))
      ;; No need to use `cl-sort' here,
      ;; we can perform destructive operation on cands.
      (fuz-sort-with-key! cands
                          (pcase-lambda (`[,len1 ,scr1] `[,len2 ,scr2])
                              (if (= scr1 scr2)
                                  (when (not preserve-tie-order?)
                                    (< len1 len2))
                                (> scr1 scr2)))
                          memo-data-fn))))

;;; Export function

(defun helm-fuz-fuzzy-matching-sort-fn! (cands _source)
  "Sort the CANDS by scoring it with `helm-pattern'

Sign: (-> (Listof Cand) Any (Listof Cand))"
  (helm-fuz-fuzzy-matching-sort-fn-1! helm-pattern
                                      cands
                                      #'helm-fuz--get-single-cand-score-data))

(defun helm-fuz-fuzzy-matching-sort-fn-preserve-ties-order! (cands _source)
  "Sort the CANDS by scoring it with `helm-pattern', preserve ties order.

Sign: (-> (Listof Cand) Any (Listof Cand))"
  (helm-fuz-fuzzy-matching-sort-fn-1! helm-pattern
                                     cands
                                     #'helm-fuz--get-single-cand-score-data
                                     t))



(defun helm-fuz-M-x-fuzzy-sort-fn! (cands _source)
  "Sorting function for `helm-M-x'

Sign: (-> (Listof Cand) Any (Listof Cand))"
  (helm-fuz-fuzzy-matching-sort-fn-1! helm-pattern
                                     cands
                                     (lambda (pat cand)
                                       (helm-fuz--get-single-cand-score-data pat cand t))
                                     t))

(defun helm-fuz-fuzzy-highlight-match! (cand)
  "Highlight the fuzzy matched part of CAND.

Sign: (-> Cand Cand)"
  (if (string= helm-pattern "")
      cand
    (let ((highlighter (lambda (str)
                         (let ((realstr (helm-stringify str)))
                           (fuz-highlighter
                            (helm-fuz--fuzzy-indices helm-pattern realstr)
                            'helm-match realstr)))))
      (pcase cand
        (`(,display . ,real)
          (cons (funcall highlighter display) real))
        (_
         (funcall highlighter cand))))))

;;; Find Files Fuzzy

(defun helm-fuz--get-ff-cand-score-data (pattern cand)
  "Like `helm-fuz--get-single-cand-score-data', but for `helm-find-files' like function.

Sign: (-> Str Cand (Vector Long Long))"
  (pcase cand
    ((and `(,disp . ,real)
          (guard (or (member real '("." ".."))
                     (and (string-match-p (rx bos "  ") real)
                          (string= real (substring-no-properties disp 2))))))
     (ignore disp)                 ;Suppress byte-compiler
     (vector (length real) most-positive-fixnum))
    (_
     (helm-fuz--get-single-cand-score-data (helm-basename pattern) cand t t))))

(defun helm-fuz--ff-filter-candidate-one-by-one-advice! (orig-fun file)
  "Advice for `helm-ff-filter-candidate-one-by-one'.

Sign: (-> (-> Str (Option Cand)) Str (Option Cand))"
  (let ((cand (funcall orig-fun file)))
    (pcase cand
      ((and `(,disp . ,_)
            (guard (and (not (string-match-p (rx "/" eol) helm-input))
                        (not (string-match-p (rx bol " ") disp)))))
       (let* ((dir-len (length (file-name-nondirectory disp)))
              (dir (substring disp 0 dir-len))
              (basename (substring disp dir-len)))
         ;; According to `helm-flx', candidates should be modified in-place.
         (setcar
          cand
          (concat dir
                  (fuz-highlighter
                   (helm-fuz--fuzzy-indices basename
                                            (helm-basename helm-input))
                   'helm-match
                   basename))))))
    cand))

(defun helm-fuz-fuzzy-ff-sort-candidate-advice! (orig-fun cands source)
  "Advice function of `helm-ff-sort-candidates'.

Sign: (-> (-> (Listof Cand) Any (Listof Cand)) (Listof Cand) Any (Listof Cand))"
  (cond ((string= (file-name-nondirectory helm-input) "")
         cands)
        ((string-match-p " " helm-pattern)
         (funcall orig-fun cands source))
        (t
         (helm-fuz-fuzzy-matching-sort-fn-1! helm-input
                                             cands
                                             #'helm-fuz--get-ff-cand-score-data))))


;;; Minor Mode

;;;###autoload
(define-minor-mode helm-fuz-mode
  "helm-fuz minor mode."
  :init-value nil
  :group 'helm-fuz
  :global t
  :lighter " Helm-Fuz"
  (if helm-fuz-mode
      (progn
        (setq helm-fuz-old-fuzzy-sort-fn helm-fuzzy-sort-fn
              helm-fuzzy-sort-fn #'helm-fuz-fuzzy-matching-sort-fn!)
        (setq helm-fuz-old-fuzzy-highlight-match-fn helm-fuzzy-matching-highlight-fn
              helm-fuzzy-matching-highlight-fn #'helm-fuz-fuzzy-highlight-match!)
        (setq helm-fuz-old-M-x-fuzzy-sort-fn helm-M-x-default-sort-fn
              helm-M-x-default-sort-fn #'helm-fuz-M-x-fuzzy-sort-fn!)

        (advice-add 'helm-ff-sort-candidates
                    :around
                    #'helm-fuz-fuzzy-ff-sort-candidate-advice!)
        (advice-add 'helm-ff-filter-candidate-one-by-one
                    :around
                    #'helm-fuz--ff-filter-candidate-one-by-one-advice!))
    (progn
      (setq helm-fuzzy-sort-fn (or helm-fuz-old-fuzzy-sort-fn
                                   #'helm-fuzzy-matching-default-sort-fn))
      (setq helm-fuzzy-matching-highlight-fn (or helm-fuz-old-fuzzy-highlight-match-fn
                                                 #'helm-fuzzy-default-highlight-match))
      (setq helm-M-x-default-sort-fn (or helm-fuz-old-M-x-fuzzy-sort-fn
                                         #'helm-M-x-fuzzy-sort-candidates))

      (advice-remove 'helm-ff-sort-candidates
                     #'helm-fuz-fuzzy-ff-sort-candidate-advice!)
      (advice-remove 'helm-ff-filter-candidate-one-by-one
                     #'helm-fuz--ff-filter-candidate-one-by-one-advice!))))

(provide 'helm-fuz)

;; Local Variables:
;; coding: utf-8
;; End:

;;; helm-fuz.el ends here
