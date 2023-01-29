;;; ruby-extra-highlight.el --- Highlight Ruby parameters.

;; Copyright (C) 2017 Anders Lindgren

;; Author: Anders Lindgren
;; Keywords: languages, faces
;; Package-Version: 20171106.1933
;; Package-Commit: 83942d18eae361998d24c1c523b308eea821f048
;; Created: 2017-09-05
;; Version: 0.0.0
;; URL: https://github.com/Lindydancer/ruby-extra-highlight

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package highlights Ruby method and block parameters.

;; Usage:
;;
;; The minor mode `ruby-extra-highlight-mode' adds highlighting rules
;; to the current buffer for highlighting method and block parameters.
;;
;; The easiest way automatically enable it for Ruby buffers is to add
;; the following to a suitable init file:
;;
;;     (add-hook 'ruby-mode-hook #'ruby-extra-highlight-mode)

;;; Code:


(defun ruby-extra-highlight-skip-comments-and-whitespace ()
  "Move point forward past comment and whitespace in current buffer."
  ;; Note: There is no way to tell `forward-comment' to skip all
  ;; comments.  However, the lisp refere manual recommends passing
  ;; `buffer-size' as COUNT, as this value will always be greater than
  ;; the number of comments.
  ;;
  ;; Note: In addition to skipping comment, this also skips
  ;; whitespace.
  (forward-comment (buffer-size)))


(defun ruby-extra-highlight-match-parameter (&optional limit)
  "Match the next Ruby parameter.

LIMIT is the end of the search, or the end of the buffer if omitted.

Set match data 1 to the parameter and move point to the next parameter."
  (unless limit
    (setq limit (point-max)))
  ;; Here, the point is after the `(' or `|' at the start of the
  ;; parameter list, of after a `,' separating parameters.
  (ruby-extra-highlight-skip-comments-and-whitespace)
  ;; Here, the point is at the beginning of a parameter, before any
  ;; `*' or `&'.
  (if (looking-at "\\(?:[*&]\\s-*\\)*\\_<\\(\\(\\sw\\|\\s_\\)+\\)\\_>")
      ;; Found a parameter. Skip until the next parameter.
      (progn
        (goto-char (match-end 0))
        (while (progn
                 (ruby-extra-highlight-skip-comments-and-whitespace)
                 (and (< (point) limit)
                      (not (memq (following-char) '(?\) ?| ?,)))))
          ;; Note: The default value of a parameter may contain `,':s,
          ;; as in `def test(x = g(1,2), y = ...)'.  Hence, it's not
          ;; sufficient to search for the next comma.
          (condition-case nil
              (forward-sexp)
            (error
             (forward-char))))
        ;; Skip the `,' or the character closing the argument list.
        (forward-char)
        t)
    nil))


(defvar ruby-extra-highlight-keywords
  '(("\\_<def\\_>\\s-+\\_<\\(\\sw\\|\\s_\\|\\.\\)+\\_>=?("
     (ruby-extra-highlight-match-parameter
      ;; Pre-match form.
      (save-excursion
        ;; Limit the search to the closing parenthesis. If none is
        ;; found, return nil to use the end of the line.
        (goto-char (- (match-end 0) 1))
        (ignore-errors
          (forward-sexp)
          (point)))
      ;; Post-match form
      nil
      (1 'font-lock-variable-name-face)))
    ("\\(\\_<do\\_>\\|{\\)\\s-+|\\([^|\n]*\\)\\(|\\|$\\)"
     (ruby-extra-highlight-match-parameter
      ;; Pre-match form.
      (progn
        (goto-char (match-beginning 2))
        (match-end 2))
      ;; Post-match form.
      nil
      (1 'font-lock-variable-name-face))))
  "Font-lock keywords for command `ruby-extra-highlight-mode'.")


;;;###autoload
(define-minor-mode ruby-extra-highlight-mode
  "Minor mode that highlights method and block parameters."
  :group 'ruby-extra-highlight
  (if ruby-extra-highlight-mode
      (progn
        (set (make-local-variable 'font-lock-multiline) t)
        (font-lock-add-keywords nil ruby-extra-highlight-keywords))
    (font-lock-remove-keywords nil ruby-extra-highlight-keywords))
  (if (fboundp 'font-lock-flush)
      (font-lock-flush)
    (when font-lock-mode
      (with-no-warnings
        (font-lock-fontify-buffer)))))

(provide 'ruby-extra-highlight)

;;; ruby-extra-highlight.el ends here
