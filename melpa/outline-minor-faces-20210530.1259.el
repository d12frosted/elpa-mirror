;;; outline-minor-faces.el --- Headings faces for outline-minor-mode  -*- lexical-binding: t -*-

;; Copyright (C) 2018-2021  Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/outline-minor-faces
;; Keywords: outlines
;; Package-Version: 20210530.1259
;; Package-Commit: 942bd43ea7099984e9ebccf48db70af345d4b6bf

;; Package-Requires: ((emacs "25.1"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Unlike `outline-mode', `outline-minor-mode' does not change
;; the appearance of headings to look different from comments.

;; This package defines the faces `outline-minor-N', which inherit
;; from the respective `outline-N' faces used in `outline-mode'
;; and arranges for them to be used in `outline-minor-mode'.

;; Usage:

;;   (use-package outline-minor-faces
;;     :after outline
;;     :config (add-hook 'outline-minor-mode-hook
;;                       'outline-minor-faces-add-font-lock-keywords))

;; If you want to only enable these faces in certain major-modes,
;; then add this function to their hooks instead of to the above
;; hook.

;;; Code:

(require 'outline)

(defface outline-minor-0
  `((((class color) (background light))
     ,@(and (>= emacs-major-version 27) '(:extend t))
     :weight bold
     :background "light grey")
    (((class color) (background  dark))
     ,@(and (>= emacs-major-version 27) '(:extend t))
     :weight bold
     :background "grey20"))
  "Face that other `outline-minor-N' faces inherit from."
  :group 'outlines)

(defface outline-minor-1
  '((t (:inherit (outline-minor-0 outline-1))))
  "Level 1 headings in `outline-minor-mode'."
  :group 'outlines)

(defface outline-minor-2
  '((t (:inherit (outline-minor-0 outline-2))))
  "Level 2 headings in `outline-minor-mode'."
  :group 'outlines)

(defface outline-minor-3
  '((t (:inherit (outline-minor-0 outline-3))))
  "Level 3 headings in `outline-minor-mode'."
  :group 'outlines)

(defface outline-minor-4
  '((t (:inherit (outline-minor-0 outline-4))))
  "Level 4 headings in `outline-minor-mode'."
  :group 'outlines)

(defface outline-minor-5
  '((t (:inherit (outline-minor-0 outline-5))))
  "Level 5 headings in `outline-minor-mode'."
  :group 'outlines)

(defface outline-minor-6
  '((t (:inherit (outline-minor-0 outline-6))))
  "Level 6 headings in `outline-minor-mode'."
  :group 'outlines)

(defface outline-minor-7
  '((t (:inherit (outline-minor-0 outline-7))))
  "Level 7 headings in `outline-minor-mode'."
  :group 'outlines)

(defface outline-minor-8
  '((t (:inherit (outline-minor-0 outline-8))))
  "Level 8 headings in `outline-minor-mode'."
  :group 'outlines)

(defvar outline-minor-faces
  [outline-minor-1 outline-minor-2 outline-minor-3 outline-minor-4
   outline-minor-5 outline-minor-6 outline-minor-7 outline-minor-8])

(defvar outline-minor-faces--lisp-modes
  '(lisp-mode
    clojure-mode
    emacs-lisp-mode
    scheme-mode))

(defvar-local outline-minor-faces--top-level nil)

(defvar-local outline-minor-faces-regexp nil
  "Regular expression to match the complete line of a heading.
If this is nil, then a regular expression based on
`outline-regexp' is used.  The value of that variable cannot
be used directly because it is only supposed to match the
beginning of a heading.")

(defun outline-minor-faces--syntactic-matcher (regexp)
  "Return a matcher that matches REGEXP only outside of strings.

Returns REGEXP directly for modes where `font-lock-keywords-only'
is non-nil because Font Lock does not mark strings and comments
for those modes, and the matcher will not know what is/is not a
string."
  (if font-lock-keywords-only
      regexp
    (lambda (limit)
      (and (re-search-forward regexp limit t)
           (not (nth 3 (syntax-ppss (match-beginning 0))))))))

(defvar outline-minor-faces--font-lock-keywords
  '((eval . (list (outline-minor-faces--syntactic-matcher
                   (or outline-minor-faces-regexp
                       (concat
                        "^\\(?:"
                        (cond
                         ((not (apply #'derived-mode-p
                                      outline-minor-faces--lisp-modes))
                          outline-regexp)
                         ((string-suffix-p "\|###autoload\\)\\|(" outline-regexp)
                          (concat (substring outline-regexp 0 -18) "\\)"))
                         ((string-suffix-p "\\|(" outline-regexp)
                          (substring outline-regexp 0 -3))
                         (t outline-regexp))
                        "\\)\\(?:.+\n\\|\n?\\)")))
                  0 '(outline-minor-faces--get-face) t))))

;;;###autoload
(defun outline-minor-faces-add-font-lock-keywords ()
  (ignore-errors
    (font-lock-add-keywords nil outline-minor-faces--font-lock-keywords t)
    (save-restriction
      (widen)
      (font-lock-flush)
      (font-lock-ensure))))

(defun outline-minor-faces--get-face ()
  (save-excursion
    (goto-char (match-beginning 0))
    (let* ((level (outline-minor-faces--level))
           (index (- level (outline-minor-faces--top-level))))
      (when (< index 0)
        (setq outline-minor-faces--top-level nil)
        (setq index (- level (outline-minor-faces--top-level))))
      (aref outline-minor-faces
            (% index (length outline-minor-faces))))))

(defun outline-minor-faces--level ()
  (save-excursion
    (beginning-of-line)
    (and (looking-at outline-regexp)
         (funcall outline-level))))

(defun outline-minor-faces--top-level ()
  (or outline-minor-faces--top-level
      (save-excursion
        (save-restriction
          (widen)
          (goto-char (point-min))
          (let ((min (or (outline-minor-faces--level) 1000)))
            (while (outline-next-heading)
              (setq min (min min (outline-minor-faces--level))))
            (setq outline-minor-faces--top-level min))))))

;;; _
(provide 'outline-minor-faces)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; outline-minor-faces.el ends here
