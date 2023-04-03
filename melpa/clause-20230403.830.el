;;; clause.el --- Functions to move, mark, kill by clause -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Marty Hiatt
;; Author: Marty Hiatt <martianhiatus [a t] riseup [dot] net>
;; Keywords: wp, convenience, sentences, text
;; Package-Version: 20230403.830
;; Package-Commit: dfa1cba4b50f224e5e642f68154122ebf52d2962
;; Version: 0.2
;; URL: https://codeberg.org/martianh/clause.el
;; Package-Requires: ((emacs "27.1") (mark-thing-at "0.3"))

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

;; Functions for moving, marking and killing by clause.

;; A clause is delimited by , ; : ( ) and en or em dashes. You can add extra
;; delimiters by customizing `clause-extra-delimiters'.

;; We do our best to imitate `forward-sentence'/`backward-sentence'
;; functionity, rather than rolling with our own preferences, even though with
;; clauses it can only be approximated. So moving forward should leave point
;; after the (last) clause character, before any space, while moving backward
;; should leave point after any clause character and after any space.

;; If sentex. is installed <https://codeberg.org/martianh/sentex>, set
;; `clause-use-sentex' to t and clause.el will use its complex sentence-ending
;; rules.

;;; Code:
(require 'sentex nil :no-error)
(require 'mark-thing-at)

(defgroup clause nil
  "Clause functions."
  :group 'convenience)

(defcustom clause-use-sentex nil
  "Whether to use `sentex' to determine clause and sentence endings.
Note that sentex's rules are language-based. Call
`sentex-set-language-for-buffer' to specify which language rules
to use."
  :type 'boolean)

(defcustom clause-handle-org-footnotes nil
  "Whether to handle org-footnotes."
  :type 'boolean)

(defcustom clause-extra-delimiters nil
  "Extra characters to add to the clause-ending regex."
  :type 'string)

(defvar clause-simplified-org-footnote-re
  "\\(\\[fn:[-_[:word:]]+\\]\\)?")

(defvar clause-non-sentence-end-clause-re
  ;; en dash surrounded by spaces, opening paren, em dash no spaces,
  ;; or 2 to 3 -
  "\\([[:space:]]–[[:space:]]\\|(\\|—\\|\\(-\\)\\{2,3\\}\\)")

(defun clause-forward-sentence-function ()
  "Return the forkward sentence function to use."
  (if clause-use-sentex
      'sentex-forward-sentence
    'forward-sentence))

(defun clause-backward-sentence-function ()
  "Return the backward sentence function to use."
  (if clause-use-sentex
      'sentex-backward-sentence
    'backward-sentence))

(defun clause-forward-sentence (&optional arg)
  "Call `clause-forward-sentence-function' with ARG."
  (apply (clause-forward-sentence-function) (list arg)))

(defun clause-backward-sentence (&optional arg)
  "Call `clause-backward-sentence-function' with ARG."
  (apply (clause-backward-sentence-function) (list arg)))

(defun clause--sentence-end-base-clause-re ()
  "Return a `sentence-end-base' type regex with clause-ending characters added."
  (concat "[" ; opening of sentence-end-base regex
          "),;:" ; our separators
          clause-extra-delimiters
          (substring sentence-end-base 1)
          (when clause-handle-org-footnotes
            clause-simplified-org-footnote-re)))

(defun clause--after-space-clause-char ()
  "Go to next clause character within the reach of `clause-forward-sentence'.
Returns the position just after the character."
  (re-search-forward clause-non-sentence-end-clause-re
                     ;; limit search:
                     (save-excursion (clause-forward-sentence)
                                     (skip-chars-forward " ")
                                     (point))
                     t)) ; nil when nothing found

(defun clause--move-past-clause-char (&optional backward nospace)
  "Move past a clause character.
With BACKWARD, move backwards.
With NOSPACE, don't move past whitespace."
  (let ((clause-chars (if nospace
                          ;; order matters for dashes
                          "\\-–(),;:.!?—"
                        "\\- –(),;:.!?—"))
        moved-p)
    (if backward
        (skip-chars-backward (concat clause-chars
                                     clause-extra-delimiters))
      (setq moved-p (skip-chars-forward (concat clause-chars
                                                clause-extra-delimiters)))
      (when (and nospace (looking-at "[[:space:]]–"))
        ;; only advance if whitespace + en dash
        ;; run separate to not skip space after en dash
        (skip-chars-forward " ")
        (skip-chars-forward "–"))
      moved-p))) ; return value for backward-clause

(defun clause--at-clause-beginning-p ()
  "Return t if point is at the begining of a clause.
Or after the end of clause plus any whitespace."
  (save-excursion
    (backward-char 2)
    ;; in case we backed into a en dash preceded by space:
    ;; TODO: improve this crap:
    (if (looking-back "[ \\t\\r\\n]+" (save-excursion
                                        (clause-backward-sentence)))
        (forward-whitespace -1))
    (or
     (when clause-extra-delimiters
       (looking-at clause-extra-delimiters))
     (looking-at clause-non-sentence-end-clause-re)
     (looking-at (clause--sentence-end-base-clause-re)))))

;;;###autoload
(defun clause-forward-clause (&optional arg)
  "Move forward to beginning of next clause.
With ARG, do this that many times."
  (interactive "p")
  (let ((sentence-end-base (clause--sentence-end-base-clause-re)))
    (dotimes (_count (or arg 1))
      (clause--move-past-clause-char)
      (or (when (clause--after-space-clause-char)
            (skip-chars-backward " ")) ; for en dash + spaces
          (clause-forward-sentence))
      (clause--move-past-clause-char nil :nospace))))

;;;###autoload
(defun clause-backward-clause (&optional arg)
  "Move backward to beginning of current clause.
With ARG, do this that many times."
  (interactive "p")
  (let ((sentence-end-base (clause--sentence-end-base-clause-re)))
    (dotimes (_count (or arg 1))
      (clause--move-past-clause-char :backward)
      (or (when
              (re-search-backward clause-non-sentence-end-clause-re
                                  ;; limit search:
                                  (save-excursion (clause-backward-sentence)
                                                  (skip-chars-backward " ")
                                                  (point))
                                  t)
            (clause--move-past-clause-char))
          (clause-backward-sentence)))))

;;;###autoload
(defun clause-kill-to-clause (&optional arg)
  "Kill text up to the next clause.
With ARG, do so that many times."
  (interactive "p")
  (let ((sentence-end-base (clause--sentence-end-base-clause-re)))
    (dotimes (_count (or arg 1))
      (if (save-excursion (clause--after-space-clause-char))
          (kill-region (point) (re-search-forward
                                clause-non-sentence-end-clause-re))
        (kill-sentence)))))

;;;###autoload
(defun clause-kill-current-clause (&optional arg)
  "Kill the current clause.
With ARG, do so that many times."
  (interactive "p")
  (let ((sentence-end-base (clause--sentence-end-base-clause-re)))
    (unless (clause--at-clause-beginning-p)
      (clause-backward-clause))
    (dotimes (_count (or arg 1))
      (if (clause--after-space-clause-char)
          (kill-region (point) (re-search-forward
                                clause-non-sentence-end-clause-re))
        (kill-sentence)))))

;;;###autoload
(defun clause-mark-clause ()
  "Mark current clause."
  (interactive)
  (let ((sentence-end-base (clause--sentence-end-base-clause-re)))
    (mark-sentence))) ; ext dep

;;;###autoload
(defun clause-mark-to-clause (&optional arg)
  "Mark from point to end of current clause.
With ARG, do so that many times."
  (interactive "p")
  (let ((sentence-end-base (clause--sentence-end-base-clause-re)))
    (mark-end-of-sentence arg)))

;;;###autoload
(defun clause-transpose-clauses (&optional arg)
  "Transpose current clause with next one.
ARG is is a prefix given to `transpose-sentences', meaning
transpose that many clauses."
  ;; FIXME: ideally we would not take ending punctuation with us
  (interactive)
  (let ((sentence-end-base (clause--sentence-end-base-clause-re)))
    (transpose-sentences (or arg 1))))

(defvar clause-mode-map
  (let ((keymap (make-keymap)))
    (define-key keymap (kbd "M-E") #'clause-forward-clause)
    (define-key keymap (kbd "M-A") #'clause-backward-clause)
    (define-key keymap (kbd "M-K") #'clause-kill-to-clause)
    (define-key keymap (kbd "M-U") #'clause-kill-current-clause)
    (define-key keymap (kbd (format "%s a" mark-thing-at-keymap-prefix)) #'clause-mark-clause)
    keymap)
  "Keymap for `clause-minor-mode'.")

;;;###autoload
(define-minor-mode clause-minor-mode
  "Locally bind clause motion commands."
  :lighter " Clause" :keymap clause-mode-map)

(provide 'clause)
;;; clause.el ends here
