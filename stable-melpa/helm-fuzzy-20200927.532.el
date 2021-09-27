;;; helm-fuzzy.el --- Fuzzy matching for helm source  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Shen, Jen-Chieh
;; Created date 2019-08-26 00:18:09

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Fuzzy matching for helm source.
;; Keyword: fuzzy helm matching source
;; Version: 0.1.6
;; Package-Version: 20200927.532
;; Package-Commit: 8d44247fd3600fe3e5e7a64a1904ae6b11bcc9fe
;; Package-Requires: ((emacs "24.4") (helm "1.7.9") (flx "0.5"))
;; URL: https://github.com/jcs-elpa/helm-fuzzy

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
;; Fuzzy matching for helm source.
;;

;;; Code:

(require 'flx)
(require 'helm)

(defgroup helm-fuzzy nil
  "Fuzzy matching for helm source."
  :prefix "helm-fuzzy-"
  :group 'convenience
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/helm-fuzzy"))

(defcustom helm-fuzzy-not-allow-fuzzy '("*helm-ag*")
  "List of buffer action that doesn't allow fuzzy."
  :type 'list
  :group 'helm-fuzzy)

;;; Util

(defun helm-fuzzy--is-contain-list-string (in-list in-str)
  "Check if a string IN-STR contain in any string in the string list IN-LIST."
  (cl-some #'(lambda (lb-sub-str) (string-match-p (regexp-quote lb-sub-str) in-str)) in-list))

(defun helm-fuzzy--flatten-list (l)
  "Flatten the multiple dimensional array, L to one dimensonal array."
  (cond ((null l) nil)
        ((atom l) (list l))
        (t (loop for a in l appending (helm-fuzzy--flatten-list a)))))

(defun helm-fuzzy--get-faces (pos)
  "Get the font faces at POS."
  (helm-fuzzy--flatten-list
   (remq nil
         (list
          (get-char-property pos 'read-face-name)
          (get-char-property pos 'face)
          (plist-get (text-properties-at pos) 'face)))))

(defun helm-fuzzy--is-current-point-face (in-face)
  "Check if current face the same face as IN-FACE."
  (let ((faces (helm-fuzzy--get-faces (point))))
    (if (listp faces)
        (if (equal (cl-position in-face faces :test 'string=) nil)
            ;; If return nil, mean not found in the `faces' list.
            nil
          ;; If have position, meaning the face exists.
          t)
      (string= in-face faces))))

;;; Core

(defun helm-fuzzy--find-pattern ()
  "Get the raw pattern directly from minibuffer."
  (let ((pattern "") (pos -1))
    (when (active-minibuffer-window)
      (save-selected-window
        (select-window (active-minibuffer-window))
        (setq pattern (buffer-string))
        (save-excursion
          (goto-char (point-min))
          (while (and (< (point) (length pattern))
                      (= pos -1))
            (forward-char 1)
            (unless (helm-fuzzy--is-current-point-face "helm-minibuffer-prompt")
              (setq pos (1- (point))))))
        (setq pattern (substring pattern pos (length pattern)))))
    pattern))

(defun helm-fuzzy--sort-candidates (candidates)
  "Fuzzy matching for all CANDIDATES."
  (when (and (not (string= helm-pattern ""))
             (not (helm-fuzzy--is-contain-list-string helm-fuzzy-not-allow-fuzzy helm-buffer)))
    (let* ((scoring-table (make-hash-table))
           (scoring-keys '())
           (pattern (helm-fuzzy--find-pattern)))
      (dolist (cand candidates)
        (let* ((cand-id (if (listp cand) (cdr cand) cand))
               (scoring (flx-score cand-id pattern))
               ;; Ensure score is not `nil'.
               (score (if scoring (nth 0 scoring) 0)))
          ;; For first time access score with hash-table.
          (unless (gethash score scoring-table) (setf (gethash score scoring-table) '()))
          ;; Push the candidate with the target score to hash-table.
          (push cand (gethash score scoring-table))))
      ;; Get all the keys into a list.
      (maphash (lambda (score-key _cand-lst) (push score-key scoring-keys)) scoring-table)
      (setq scoring-keys (sort scoring-keys #'>))  ; Sort keys in order.
      (setq candidates '())  ; Clean up, and ready for final output.
      (dolist (key scoring-keys)
        (let ((cands (sort (gethash key scoring-table)
                           (lambda (lst1 lst2)
                             (let ((str1 (if (listp lst1) (cdr lst1) lst1))
                                   (str2 (if (listp lst2) (cdr lst2) lst2)))
                               (string-lessp str1 str2))))))
          (setq candidates (append candidates cands))))))
  candidates)

(defun helm-fuzzy--helm-process-filtered-candidate-transformer (candidates source)
  "Filtered by CANDIDATES in SOURCE."
  (helm-aif (assoc-default 'filtered-candidate-transformer source)
      (let ((cands (helm-apply-functions-from-source source it candidates source)))
        (setq cands (helm-fuzzy--sort-candidates cands))
        cands)
    (setq candidates (helm-fuzzy--sort-candidates candidates))
    candidates))

;;; Entry

(defun helm-fuzzy--enable ()
  "Enable `helm-fuzzy'."
  (advice-add 'helm-process-filtered-candidate-transformer :override #'helm-fuzzy--helm-process-filtered-candidate-transformer))

(defun helm-fuzzy--disable ()
  "Disable `helm-fuzzy'."
  (advice-remove 'helm-process-filtered-candidate-transformer #'helm-fuzzy--helm-process-filtered-candidate-transformer))

;;;###autoload
(define-minor-mode helm-fuzzy-mode
  "Minor mode 'helm-fuzzy-mode'."
  :global t
  :require 'helm-fuzzy
  :group 'helm-fuzzy
  (if helm-fuzzy-mode (helm-fuzzy--enable) (helm-fuzzy--disable)))

(provide 'helm-fuzzy)
;;; helm-fuzzy.el ends here
