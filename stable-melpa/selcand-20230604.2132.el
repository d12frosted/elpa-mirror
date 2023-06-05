;;; selcand.el --- Select a candidate from a tree of hint characters -*- lexical-binding: t; -*-
;;
;; Filename: selcand.el
;; Author: Ernesto Alfonso
;; Maintainer: (concat "erjoalgo" "@" "gmail" ".com")
;; Created: Thu Jan 24 00:18:56 2019 (-0800)
;; Version: 0.0.2
;; Package-Version: 20230604.2132
;; Package-Commit: c41b4c8a4ee01f8c069b219e2fea16a084c79f19
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/erjoalgo/selcand
;; Keywords: lisp completing-read prompt combinations vimium
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;; Like vimium, selcand-select enumerates a potentially large list
;; of candidates using very short hints that the user may type to
;; make a selection.
;; It is intended to be used from emacs lisp code to prompt the user
;; to select from a list of choices.
;; Sample usage: (load-theme (selcand-select (custom-available-themes)))
;;
;;; Code:


(require 'cl-lib)
(require 'subr-x)

(defcustom selcand-default-hint-chars
  "1234acdefqrstvwxz"
  "Default hint chars."
  :type 'string
  :group 'selcand)

;;;###autoload
(cl-defun selcand-select (candidates
                          &key
                          prompt
                          stringify-fn
                          autoselect-if-single
                          initial-input
                          read-char
                          chars)
  "Use PROMPT to prompt for a selection from CANDIDATES.

STRINGIFY-FN is an optional function to represent a candidate as a string.
If AUTOSELECT-IF-SINGLE is non-nil and there is exactly one candidate,
prompting the user is skipped.
INITIAL-INPUT, if non-nil, is used as the initial input in a
COMPLETING-READ call.
If READ-CHAR is non-nil, a single character key press is read
and mapped to the corresponding single-char candidate."

  (let* ((hints-cands (selcand-hints candidates chars))
         (sep ") ")
         (stringify-fn (or stringify-fn #'prin1-to-string))
         (initial-candidate nil)
         (choices (cl-loop for (hint . cand) in hints-cands
                           as string = (funcall stringify-fn cand)
                           as choice = (concat hint sep string)
                           when (and initial-input
                                     (equal string initial-input))
                           do (setq initial-candidate choice)
                           collect choice))
         (prompt (or prompt "select candidate: "))
         (choice (cond
                  ((and autoselect-if-single (null (cdr choices)))
                   (car choices))
                  (read-char
                   (unless
                       (= 1 (apply #'max (mapcar (lambda (hint-cand)
                                                   (length (car hint-cand)))
                                                 hints-cands)))
                     (error
                      "Not enough 1-char hints for %d candidates"
                      (length candidates)))
                   (char-to-string
                    (read-char
                     (concat prompt "\n" (string-join choices "\n")))))
                  (t (minibuffer-with-setup-hook
                         #'minibuffer-completion-help
                       (completing-read prompt choices
                                        nil
                                        t
                                        initial-candidate)))))
         (cand (let* ((hint (car (split-string choice sep))))
                 (alist-get hint hints-cands nil nil #'equal))))
    cand))

(defun selcand-hints (cands &optional chars)
  "Return an alist (HINT . CAND) for each candidate in CANDS.

  Each hint consists of characters in the string CHARS."
  (setf chars (or chars selcand-default-hint-chars))
  (cl-assert cands)
  (cl-loop with hint-width = (ceiling (log (length cands) (length chars)))
           with current = '("")
           for _ below hint-width do
           (setq current
                 (cl-loop for c across chars nconc
                          (mapcar (apply-partially #'concat (char-to-string c))
                                  current)))
           finally
           (return
            (cl-loop for hint in current
                     for cand in cands
                     collect (cons hint cand)))))

(provide 'selcand)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; selcand.el ends here
