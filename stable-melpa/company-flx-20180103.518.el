;;; company-flx.el --- flx based fuzzy matching for company -*- lexical-binding: t -*-

;; Copyright (C) 2015, 2018 PythonNut

;; Author: PythonNut <pythonnut@pythonnut.com>
;; Keywords: convenience, company, fuzzy, flx
;; Package-Version: 20180103.518
;; Package-Commit: 05efcafb488f587bb6e60923078d97227462eb68
;; Version: 20151016
;; URL: https://github.com/PythonNut/company-flx
;; Package-Requires: ((emacs "24") (company "0.8.12") (flx "0.5"))

;;; License:

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

;; This package adds fuzzy matching to company, powered by the sophisticated sorting heuristics in flx.

;; Usage
;; =====

;; To install, either clone this package directly, or execute M-x package-install RET company-flx RET.

;; After the package is installed, you can enable `company-flx` by adding the following to your init file:

;;     (with-eval-after-load 'company
;;       (company-flx-mode +1))

;;; Code:

(require 'company)
(require 'cl-lib)

(eval-when-compile
  (with-demoted-errors "Load error: %s"
    (require 'flx)))

(defgroup company-flx nil
  "Sort company candidates by flx score"
  :group 'convenience
  :prefix "company-flx-")

(defcustom company-flx-limit 500
  "The maximum number of company candidates to flx sort"
  :type 'number
  :group 'company-flx)

(defvar company-flx-cache nil
  "Stores company-mode's flx-cache")

(defun company-flx-commonality (strs)
  "Return the largest string that fuzzy matches all STRS"
  (cl-letf* ((commonality-cache (make-hash-table :test 'equal :size 200))
             ((symbol-function
               #'fuzzy-commonality)
              (lambda (strs)
                (let ((hash-value (gethash strs commonality-cache nil)))
                  (if hash-value
                      (if (eq hash-value 'nothing)
                          nil
                        hash-value)

                    (setq strs (mapcar #'string-to-list strs))
                    (let ((res) (tried) (idx))
                      (dolist (char (car strs))
                        (unless (memq char tried)
                          (catch 'notfound
                            (setq idx (mapcar (lambda (str)
                                                (or
                                                 (cl-position char str)
                                                 (throw 'notfound nil)))
                                              strs))
                            (push (cons char
                                        (fuzzy-commonality
                                         (cl-mapcar (lambda (str idx)
                                                      (cl-subseq str (1+ idx)))
                                                    strs idx)))
                                  res)
                            (push char tried))))
                      (setq res (if res
                                    (cl-reduce
                                     (lambda (a b)
                                       (if (> (length a) (length b)) a b))
                                     res)
                                  nil))
                      (puthash strs
                               (if res res 'nothing)
                               commonality-cache)
                      res))))))
    (concat (fuzzy-commonality strs))))

(defun company-flx-find-holes (merged str)
  "Find positions in MERGED, where insertion by the user is likely, wrt. STR"
  (require 'flx)
  (let ((holes) (matches (cdr (flx-score str merged company-flx-cache))))
    (dolist (i (number-sequence 0 (- (length matches) 2)))
      (when (>
             (elt matches (1+ i))
             (1+ (elt matches i)))
        (push (1+ i) holes)))
    (unless (<= (length str) (car (last matches)))
      (push (length merged) holes))
    holes))

(defun company-flx-merge (strs)
  "Merge a collection of strings, including their collective holes"
  (let ((common (company-flx-commonality strs))
        (holes))
    (setq holes (make-vector (1+ (length common)) 0))
    (dolist (str strs)
      (dolist (hole (company-flx-find-holes common str))
        (cl-incf (elt holes hole))))

    (cons common (append holes nil))))

(defun company-flx-completion (string table predicate point
                                      &optional all-p)
  "Helper function implementing a fuzzy completion-style"
  (let* ((beforepoint (substring string 0 point))
         (afterpoint (substring string point))
         (boundaries (completion-boundaries beforepoint table predicate afterpoint))
         (prefix (substring beforepoint 0 (car boundaries)))
         (infix (concat
                 (substring beforepoint (car boundaries))
                 (substring afterpoint 0 (cdr boundaries))))
         (suffix (substring afterpoint (cdr boundaries)))
         ;; |-              string                  -|
         ;;              point^
         ;;            |-  boundaries -|
         ;; |- prefix -|-    infix    -|-  suffix   -|
         ;;
         ;; Infix is the part supposed to be completed by table, AFAIKT.
         (regexp (concat "\\`"
                         (mapconcat
                          (lambda (x)
                            (setq x (string x))
                            (concat "[^" x "]*" (regexp-quote x)))
                          infix
                          "")))
         (completion-regexp-list (cons regexp completion-regexp-list))
         (candidates (or (all-completions prefix table predicate)
                         (all-completions infix table predicate))))

    (if all-p
        ;; Implement completion-all-completions interface
        (when candidates
          ;; Not doing this may result in an error.
          (setcdr (last candidates) (length prefix))
          candidates)
      ;; Implement completion-try-completions interface
      (if (= (length candidates) 1)
          (if (equal infix (car candidates))
              t
            ;; Avoid quirk of double / for filename completion. I don't
            ;; know how this is *supposed* to be handled.
            (when (and (> (length (car candidates)) 0)
                       (> (length suffix) 0)
                       (char-equal (aref (car candidates)
                                         (1- (length (car candidates))))
                                   (aref suffix 0)))
              (setq suffix (substring suffix 1)))
            (cons (concat prefix (car candidates) suffix)
                  (length (concat prefix (car candidates)))))
        (if (= (length infix) 0)
            (cons string point)
          (cl-destructuring-bind (merged . holes)
              (company-flx-merge candidates)
            (cons
             (concat prefix merged suffix)
             (+ (length prefix)
                (cl-position (apply #'max holes) holes)))))))))

(defun company-flx-try-completion (string table predicate point)
  "Fuzzy version of completion-try-completion"
  (company-flx-completion string table predicate point))
(defun company-flx-all-completions (string table predicate point)
  "Fuzzy version of completion-all-completions"
  (company-flx-completion string table predicate point 'all))

(defun company-flx-company-capf-advice (old-fun &rest args)
  (let ((completion-styles (list 'fuzzy)))
    (apply old-fun args)))

(defun company-flx-transformer (cands)
  "Sort up to company-flx-limit candidates by their flx score."
  (require 'flx)
  (or company-flx-cache
      (setq company-flx-cache (flx-make-string-cache #'flx-get-heatmap-str)))

  (let ((num-cands (length cands)))
    (mapcar #'car
            (sort (mapcar
                   (lambda (cand)
                     (cons cand
                           (or (car (flx-score cand
                                               company-prefix
                                               company-flx-cache))
                               most-negative-fixnum)))
                   (if (< num-cands company-flx-limit)
                       cands
                     (let* ((seq (sort cands (lambda (c1 c2)
                                               (< (length c1)
                                                  (length c2)))))
                            (end (min company-flx-limit
                                      num-cands
                                      (length seq)))
                            (result nil))
                       (dotimes (_ end  result)
                         (push (pop seq) result)))))
                  (lambda (c1 c2)
                    ;; break ties by length
                    (if (/= (cdr c1) (cdr c2))
                        (> (cdr c1)
                           (cdr c2))
                      (< (length (car c1))
                         (length (car c2)))))))))

;;;###autoload
(define-minor-mode company-flx-mode
  "company-flx minor mode"
  :init-value nil
  :group 'company-flx
  :global t
  (if company-flx-mode
      (progn
        (add-to-list 'completion-styles-alist
                     '(fuzzy
                       company-flx-try-completion
                       company-flx-all-completions
                       "An intelligent fuzzy matching completion style."))

        (advice-add 'company-capf :around #'company-flx-company-capf-advice)
        (add-to-list 'company-transformers #'company-flx-transformer t))

    (advice-remove 'company-capf #'company-flx-company-capf-advice)
    (setq company-transformers
          (delete #'company-flx-transformer company-transformers))))

(provide 'company-flx)
;;; company-flx.el ends here
