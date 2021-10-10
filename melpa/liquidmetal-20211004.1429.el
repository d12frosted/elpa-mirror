;;; liquidmetal.el --- A mimetic poly-alloy of the Quicksilver scoring algorithm  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Shen, Jen-Chieh
;; Created date 2021-06-08 12:59:19

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: A mimetic poly-alloy of the Quicksilver scoring algorithm
;; Keyword: fuzzy matching
;; Version: 1.3.0
;; Package-Version: 20211004.1429
;; Package-Commit: e42baf790629cc3a7310194c4f00d9dafa34f933
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/jcs-elpa/liquidmetal

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; A mimetic poly-alloy of the Quicksilver scoring algorithm
;;
;; The algorithm is created by Ryan McGeary and it's ported from the repository
;; https://github.com/rmm5t/liquidmetal.
;;
;; For more information please visit the upstream repository or see the `why`
;; section in the README, https://github.com/rmm5t/liquidmetal#why.
;;

;;; Code:

(require 'subr-x)

(defconst liquidmetal-score-no-match 0.0
  "The score indicating a negative match.")

(defconst liquidmetal-score-match 1.0
  "The score indicating a full-match.")

(defconst liquidmetal-score-trailing 0.8
  "The score to return when the abrreviation string is empty.")

(defconst liquidmetal-score-trailing-but-started 0.9
  "Trailing score but not the start of string.")

(defconst liquidmetal-score-buffer 0.85
  "Trailing score at the start of string.")

(defconst liquidmetal-word-separators "[ \t_-]"
  "Separator to indentify a next new word.")

(defun liquidmetal--create-array (len)
  "Create a empy array with LEN."
  (let (new-array)
    (dotimes (_ len) (push -1 new-array))
    new-array))

(defun liquidmetal--set-array (array index value)
  "Safe way to set VALUE to ARRAY's item by INDEX."
  (let ((clone-array array) (diff (1+ (- index (length array)))))
    (when (<= 0 index)
      (setq clone-array (append clone-array (liquidmetal--create-array diff)))
      (setf (nth index clone-array) value))
    clone-array))

;;;###autoload
(defun liquidmetal-score (string abbreviation)
  "Computes the score of matching STRING with ABBREVIATION.

The return value is in the range 0.0 to 1.0 the later being full-match."
  (let ((len (length abbreviation)))
    (cond ((= 0 len) liquidmetal-score-trailing)
          ((> len (length string)) liquidmetal-score-no-match)
          (t (liquidmetal-build-score string abbreviation)))))

(defun liquidmetal-fill-array (array value from to)
  "Fill ARRAY with VALUE FROM to TO."
  (let ((clone-array array) (index from))
    (while (< index to)
      (if (nth index clone-array)
          (setf (nth index clone-array) value)
        (setq clone-array (append clone-array (list value))))
      (setq index (1+ index)))
    clone-array))

(defun liquidmetal-index-of (array item &optional start)
  "Return the ITEM's index from ARRAY.

Optional argument START is the starting of the search index."
  (unless start (setq start 0))
  (when (< start 0) (setq start 0))
  (string-match-p item array start))

(defun liquidmetal-is-new-word (string index)
  "Return non-nil if character from INDEX of STRING is new word."
  (let ((c (or (ignore-errors (substring string (1- index) index)) "")))
    (if (string-empty-p c) t
      (string-match-p liquidmetal-word-separators c))))

(defun liquidmetal-is-upper-case (string index)
  "Return non-nil if character from INDEX of STRING is a uppercase."
  (let ((c (or (ignore-errors (substring string index (1+ index))) "")))
    (string= c (upcase c))))

(defun liquidmetal-score-all (string search abbrev search-index abbr-index scores &optional all-scores)
  "Iterate through STRING and determine the overall score.

Argument STRING is target to search through.
Argument SEARCH is the lowercase of of STRING.
Argument ABBREV is the lowercase of abbreviation.
Argument SEARCH-INDEX is pass for iterating matching string.
Argument ABBR-INDEX is pass for iterating abbreviation string
Argument SCORES stores the last result to ALL-SCORES.

Optional argument ALL-SCORES is stored for recusrive result."
  (if (= abbr-index (length abbrev))
      (let* ((started (string= (substring search 0 1) (substring abbrev 0 1)))
             (trail-score (if started liquidmetal-score-trailing-but-started liquidmetal-score-trailing)))
        (setq scores (liquidmetal-fill-array scores trail-score (length scores) (length string)))
        (push scores all-scores))
    (let* ((c (substring abbrev abbr-index (1+ abbr-index)))
           (index (liquidmetal-index-of search c search-index))
           (score-index search-index))
      (setq abbr-index (1+ abbr-index))
      (when index
        (while (progn
                 (setq index (liquidmetal-index-of search c (1+ search-index)))
                 index)
          (cond ((liquidmetal-is-new-word string index)
                 (setq scores (liquidmetal--set-array scores (1- index) liquidmetal-score-match))
                 (setq scores
                       (liquidmetal-fill-array scores liquidmetal-score-buffer (1+ score-index) (1- index))))
                ((liquidmetal-is-upper-case string index)
                 (setq scores
                       (liquidmetal-fill-array scores liquidmetal-score-buffer (1+ score-index) index)))
                (t
                 (setq scores
                       (liquidmetal-fill-array scores liquidmetal-score-no-match (1+ score-index) index))))
          (if (nth index scores)
              (setf (nth index scores) liquidmetal-score-match)
            (push liquidmetal-score-match scores))
          ;; consume matched string and continue search
          (setq search-index index)
          (setq all-scores
                (liquidmetal-score-all string search abbrev search-index abbr-index scores all-scores))))))
  all-scores)

(defun liquidmetal-build-score (string abbreviation)
  "Calculates the fuzzy score of matching STRING with ABBREVIATION."
  (let* ((search (downcase string)) (abbrev (downcase abbreviation))
         (all-scores (liquidmetal-score-all string search abbrev -1 0 nil))
         (max-score 0.0) score-sum)
    (if (= (length all-scores) 0) 0.0
      (dolist (scores all-scores)
        (setq score-sum (apply '+ scores))
        (when (> score-sum max-score)
          (setq max-score score-sum)))
      (setq max-score (/ max-score (length string))))
    max-score))

(provide 'liquidmetal)
;;; liquidmetal.el ends here
