;;; most-used-words.el --- Display most used words in buffer
;;; -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Udyant Wig
;;
;; Author: Udyant Wig <udyant.wig@gmail.com>
;; URL: https://github.com/udyantw/most-used-words
;; Package-Version: 20200808.931
;; Package-Commit: f712879493660c3c3ee3793470b8f8939b79c2b0
;; Version: 0.1
;; Package-Requires: ((emacs "24.3"))
;; Keywords: convenience, wp

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:
;; Identify the most frequently used words in a buffer.
;;
;; The command
;;   M-x most-used-words-buffer
;; goes through the current buffer keeping a count of words, as defined
;; by the default syntax table.  Once done, it displays a buffer of the
;; most frequently used words.
;;
;; I wrote the following functions, and the wonderful posters at
;; gnu.emacs.help reviewed it.
;; Part of a discussion thread on gnu.emacs.help follows the
;; development:
;; https://groups.google.com/d/topic/gnu.emacs.help/nC8IsIuNeek/discussion
;;
;; Special thanks are due to Stefan Monnier and Eric Abrahamsen, who
;; made suggestions that greatly improved performance; Emmanuel Berg
;; reminded me to prefix functions from CL-LIB; Bob Proulx,
;; Ben Bacarisse, Nick Dokos, Eli Zaretskii shared of their Unix wisdom
;; and experience; and Bob Newell tested it for his purposes.

;;; Code:

(require 'cl-lib)
(require 'tabulated-list)

(defgroup most-used-words nil
  "Display most used words in buffer."
  :prefix "most-used-words-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/udyantw/most-used-words"))

(defcustom most-used-words-word-display 3
  "Default word data to display."
  :type 'integer
  :group 'most-used-words)

(defcustom most-used-words-display-type 'table
  "The method to display most used words."
  :type '(choice (const :tag "buffer" buffer)
                 (const :tag "table" table))
  :group 'most-used-words)

(defvar most-used-words--buffer-name "*Most used words*"
  "Buffer name for displaying most used words.")

(defvar most-used-words--buffer nil
  "Recorded buffer for currently doing most used words.")

;;; Util

(cl-defmacro most-used-words-with-view-buffer (buffer &body body)
  "Execute BODY in BUFFER, and view it in another window."
  `(progn
     (with-current-buffer ,buffer ,@body)
     (view-buffer-other-window ,buffer nil #'kill-buffer)))

(defun most-used-words--form-data (word count percent)
  "Form the plist data item with WORD, COUNT, PERCENT."
  (list :word word :count count :percent percent))

(defun most-used-words-data (n)
  "Form used word data base on N count of data displayed."
  (let* ((most-used (most-used-words-buffer-1 n t))
         (word-counts (cl-first most-used))
         (total-count (float (cl-second most-used))))
    (cl-loop with data-list = '()
       with data-item = nil
       for (word count) in word-counts
       do
         (setf data-item (most-used-words--form-data word count (* 100 (/ count total-count))))
         (push data-item data-list)
       finally (return (nreverse data-list)))))

;;; Core

(defun most-used-words-buffer-1 (n &optional show-percentages-p)
  "Make a list of the N most used words in buffer.

Optional argument SHOW-PERCENTAGES-P displays word counts and percentages."
  (with-current-buffer most-used-words--buffer
    (let ((counts (make-hash-table :test #'equal))
          (total-count 0)
          sorted-counts
          uniques-count
          start end)
      (save-excursion
        (goto-char (point-min))
        (skip-syntax-forward "^w")
        (setf start (point))
        (cl-loop until (eobp)
           do
             (skip-syntax-forward "w")
             (setf end (point))
             (cl-incf (gethash (buffer-substring start end) counts 0))
             (skip-syntax-forward "^w")
             (setf start (point))
             (cl-incf total-count)))
      (cl-loop for word being the hash-keys of counts
         using (hash-values count)
         do
           (push (list word count) sorted-counts)
         finally (setf sorted-counts (cl-sort sorted-counts #'>
                                              :key #'cl-second)))
      (setf uniques-count (length sorted-counts))
      (when (< uniques-count n)
        (message "You chose to show %d words, which are more than the number of unique words.
Showing the maximum possible (%d)." n uniques-count)
        (setf n uniques-count))
      (if show-percentages-p
          (list (cl-subseq sorted-counts 0 n) total-count)
        (mapcar #'cl-first (cl-subseq sorted-counts 0 n))))))

(defun most-used-words-buffer-aux (&optional n show-counts-p)
  "Show the N (default 3) most used words in the current buffer.

Optional argument SHOW-COUNTS-P also shows the counts and percentages."
  (let* ((most-used-words--buffer (current-buffer))
         (most-used-words-buffer (get-buffer-create most-used-words--buffer-name))
         (most-used (most-used-words-data n))
         word count percent)
    (cl-case most-used-words-display-type
      ('buffer
       (most-used-words-with-view-buffer
        most-used-words-buffer
        (dolist (word-data most-used)
          (setq word (plist-get word-data :word)
                count (plist-get word-data :count)
                percent (plist-get word-data :percent))
          (if show-counts-p
              (insert (format "%-24s    %5d    %0.2f%%" word count percent))
            (insert (format "%s" word)))
          (newline))))
      ('table
       (pop-to-buffer most-used-words-buffer)
       (let ((most-used-words-word-display n))
	 (most-used-words-mode))))))

;;; Tabluldated List

(defconst most-used-words--format
  (vector (list "Word" 15 t)
          (list "Counts" 10 #'most-used-words--sort-counts)
          (list "Percentages" 10 #'most-used-words--sort-percentages))
  "Format to assign to `tabulated-list-format' variable.")

(defun most-used-words--sort-percentages (var1 var2)
  "Sort percentages entries, VAR1 and VAR2."
  (let* ((percent-index 2)
         (cnt1 (elt (nth 1 var1) percent-index))
         (cnt2 (elt (nth 1 var2) percent-index)))
    (setq cnt1 (string-to-number cnt1))
    (setq cnt2 (string-to-number cnt2))
    (< cnt1 cnt2)))

(defun most-used-words--sort-counts (var1 var2)
  "Sort counts entries, VAR1 and VAR2."
  (let* ((count-index 1)
         (cnt1 (elt (nth 1 var1) count-index))
         (cnt2 (elt (nth 1 var2) count-index)))
    (setq cnt1 (string-to-number cnt1))
    (setq cnt2 (string-to-number cnt2))
    (< cnt1 cnt2)))

(defun most-used-words--get-entries (n)
  "Data entries for N most used words."
  (let ((most-used (most-used-words-data n))
        (entries '()) (id-count 0))
    (dolist (word-data most-used)
      (let ((new-entry '()) (new-entry-value '())
            (word (plist-get word-data :word))
            (count (plist-get word-data :count))
            (percent (plist-get word-data :percent)))
        (push (concat (format "%0.2f" percent) "%") new-entry-value)  ; Percentages
        (push (format "%s" count) new-entry-value)  ; Counts
        (push word new-entry-value)  ; Word
        (push (vconcat new-entry-value) new-entry)  ; Turn into vector.
        (push (number-to-string id-count) new-entry)  ; ID
        (push new-entry entries)
        (setq id-count (1+ id-count))))
    entries))

(define-derived-mode most-used-words-mode tabulated-list-mode
  "most-used-words-mode"
  "Major mode for Most Used Words display."
  :group 'most-used-words
  (setq tabulated-list-format most-used-words--format)
  (setq tabulated-list-padding 1)
  (setq tabulated-list-sort-key (cons "Counts" t))
  (tabulated-list-init-header)
  (setq tabulated-list-entries (most-used-words--get-entries most-used-words-word-display))
  (tabulated-list-print t))

;;; Entry

;;;###autoload
(defun most-used-words-buffer (&optional n)
  "Show the N (default 3) most used words in the current buffer."
  (interactive (list (completing-read
                      (format "How many words? (default %s) "
                              most-used-words-word-display)
                      nil nil nil nil nil
                      most-used-words-word-display
                      nil)))
  (unless (numberp n) (setf n (string-to-number n)))
  (most-used-words-buffer-aux n nil))

;;;###autoload
(defun most-used-words-buffer-with-counts (&optional n)
  "Show with counts the N (default 3) most used words in the current buffer."
  (interactive (list (completing-read
                      (format "How many words? (default %s) "
                              most-used-words-word-display)
                      nil nil nil nil nil
                      most-used-words-word-display
                      nil)))
  (unless (numberp n) (setf n (string-to-number n)))
  (most-used-words-buffer-aux n t))

(provide 'most-used-words)

;;; most-used-words.el ends here
