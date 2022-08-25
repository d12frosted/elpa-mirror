;;; nv-delete-back.el --- backward delete like modern text editors -*- lexical-binding: t -*-

;; Copyright (C) 2017 Nicolas Vaughan

;; Author: Nicolas Vaughan <n.vaughan [at] oxon.org>
;; Keywords: lisp
;; Package-Version: 20170224.1249
;; Package-Commit: 44d506105989873dc1725e0cfc675925b35c9c98
;; Version: 0.0.3
;; Package-Requires: ((emacs "24"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package replicates the backward delete behavior of modern text editors like oXygen XML or Sublime Text.
;; Recomended binding (requires bind-key):
;; (bind-key "C-<backspace>" 'nv-delete-back-all)
;; (bind-key "M-<backspace>" 'nv-delete-back)


;;; Code:

;;;###autoload
(defun nv-delete-back-all ()
  "Backward deletes either (i) all empty lines, or (ii) one whole word, or (iii) a single non-word character."
  (interactive)
  ;; If region is selected, delete it:
  (if (region-active-p)
      ;; then:
      (delete-region (region-beginning) (region-end))
    ;; else continue:
    (let ((nl-p nil))
      ;; First part:
      ;; Look back and find if we have to do a full back-delete
      (save-excursion
        (while (looking-back "[\n\s-]" 1 nil)
          (progn
            (if (looking-back "[\s-]" 1 nil)
                (while (looking-back "[\s-]" 1 nil)
                  (left-char 1))
              )
            (if (looking-back "[\n]" 1 nil)
                (progn
                  (while (looking-back "[\n]" 1 nil)
                    (left-char 1))
                  (setq nl-p t)
                  )
              )
            )
          )
        )
      ;; Second part:
      ;; Do we have to do a full back-delete?
      (if nl-p
          (if (looking-back "[\n\s-]" 1 nil)
              ;; delete all spaces and newline chars behind the point
              (while (looking-back "[\n\s-]" 1 nil)
                (delete-char -1))
            )
        ;; else, delete one word
        (progn
          ;; delete all trailing spaces
          (if (looking-back "[\s-]" 1 nil)
              (while (looking-back "[\s-]" 1 nil)
                (delete-char -1))
            )
          ;; delete one word
          (nv-delete-back-word 1)
          )
        )
      )
    )
  )


;;;###autoload
(defun nv-delete-back ()
  "Backward-deletes either (i) all spaces, (ii) one whole word, or (iii) a single non-word/non-space character."
  (interactive)
  ;; If region is selected, delete it:
  (if (region-active-p)
      ;; then:
      (delete-region (region-beginning) (region-end))
    ;; else continue:
    ;; Do we have a newline char behind the point?
    (if (looking-back "[\n]" 1 nil)
        ;; then, delete the newline char
        (delete-char -1)
      ;; else
      (progn
        ;; delete all spaces behind the point
        (while (looking-back "[[:space:]]" 1 nil)
          (delete-char -1))
        ;; and finally delete one word
        (nv-delete-back-word)
        )
      )
    )
  )



;;;###autoload
(defun nv-delete-back-word (&optional amount)
  "Backward-deletes either (i) one whole word, or (ii) a single non-word character.  If AMOUNT is supplied, the function will delete AMOUNT times of words or non-word characters.  The function can also be called with a prefix."
  (interactive "p")
  ;; set default of 1 for optional argument 'amount'
  (let ((amount (or amount 1)))
    ;; begin our decreasing while loop
    (while (>= amount 1)
      ;; first check if text is selected
      (if (region-active-p)
          ;; then:
          (delete-region (region-beginning) (region-end))
        ;; else continue:
        (progn
          ;; now, first check if there are any spaces
          (if (looking-back "[[:space:]]" 1 nil)
              ;; then, delete all spaces
              (while (looking-back "[[:space:]]" 1 nil)
                (delete-char -1))
            ) ;; space if
          ;; second, proceed to check if there is a word
          (if (looking-back "[[:alnum:]]" 1 nil)
              ;; then proceed to back-delete it
              (while (looking-back "[[:alnum:]]" 1 nil)
                (delete-char -1))
            ;; else: check whether there is a non-word-non-space char
            (if (looking-back "[^[:alnum:][:space:]\n]" 1 nil)
                (delete-char -1)
              )
            )
          )
        )
      (setq amount (1- amount))
      ) ;; while loop ends here
    )
  )

(provide 'nv-delete-back)
;;; nv-delete-back.el ends here
