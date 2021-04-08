;;; salesforce-utils.el --- simple utilities for Salesforce

;; Version: 1.0
;; Package-Version: 20160814.154
;; Package-Commit: 73328baf0fb94ac0d0de645a8f6d42e5ae27f773
;; Author: Sean McAfee
;; Url: https://github.com/grimnebulin/emacs-salesforce
;; Package-Requires: ((cl-lib "0.5"))

;; Copyright 2016 Sean McAfee

;; This file is part of emacs-salesforce.

;; emacs-salesforce is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; emacs-salesforce is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with emacs-salesforce.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a tiny package that facilitates one Salesforce-related
;; task: converting a fifteen-character Salesforce object ID to an
;; eighteen-character object-ID-with-checksum.

;; This project is not associated with Salesforce (the company) in any
;; way.

;; MOTIVATION

;; At my job, I occasionally need to convert a fifteen-digit
;; Salesforce ID into the eighteen-character version.  I was advised by
;; co-workers to use a Chrome plugin for this purpose, but I don't use
;; Chrome and am generally loathe to leave Emacs when it can be
;; avoided.  So I researched the algorithm for generating the three
;; checksum characters and implemented it in Emacs Lisp.

;;; Code:

(require 'cl-lib)
(require 'thingatpt)

;; Typically the Salesforce table would be expressed as the uppercase
;; letters A-Z followed by the digits 0-5.  This version of the table
;; has each character moved from its original position at index N, a
;; 5-bit number, to a position given by reversing the bits of N.  For
;; example, the character Q, originally at position 10000, is here at
;; position 00001.  This saves us a list reversal in
;; salesforce--id-suffix-char below.

(defconst salesforce-table "AQIYEUM2CSK0GWO4BRJZFVN3DTL1HXP5"
  "Salesforce ID checksum lookup table.")

(defun salesforce--id-suffix-char (str)
  "Return the checksum character for the five-character block STR.
The block should be one of the three five-character blocks in a
fifteen-character Salesforce ID."
  (cl-assert (= 5 (length str)) nil "ID block not exactly 5 characters long")
  (let* ((case-fold-search nil)
         (index (cl-reduce (lambda (acc x) (+ (* 2 acc) (if x 1 0)))
                           (cl-map 'list (lambda (x) (string-match-p (rx (any upper)) (string x))) str)
                           :initial-value 0)))
    (substring salesforce-table index (1+ index))))

(defun salesforce-id-suffix (id)
  "Return the three-character checksum suffix for a fifteen-character Salesforce ID."
  (cl-assert (= 15 (length id)) nil "Salesforce ID must be exactly 15 characters long")
  (mapconcat (lambda (i) (salesforce--id-suffix-char (substring id i (+ 5 i)))) '(0 5 10) ""))

(defun salesforce-id-convert (id)
  "Return the given fifteen-character Salesforce ID with the three-character checksum suffix appended."
  (concat id (salesforce-id-suffix id)))

;;;###autoload
(defun salesforce-append-id-suffix ()
  "Append the three-character checksum to the fifteen-character Salesforce ID at point."
  (interactive)
  (let ((suffix (salesforce-id-suffix (word-at-point))))
    (save-excursion
      (unless (looking-at (rx word-end))
        (forward-word))
      (insert suffix))))

(provide 'salesforce-utils)

;;; salesforce-utils.el ends here
