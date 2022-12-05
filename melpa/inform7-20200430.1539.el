;;; inform7.el --- Major mode for working with Inform 7 files

;; Copyright (C) 2020 Ben Moon
;; Author: Ben Moon <software@guiltydolphin.com>
;; URL: https://github.com/GuiltyDolphin/inform7-mode
;; Package-Version: 20200430.1539
;; Package-Commit: a409bbc6f04264f7f00616a995fa6ecf59d33d0d
;; Git-Repository: git://github.com/GuiltyDolphin/inform7-mode.git
;; Created: 2020-04-11
;; Version: 0.1.1
;; Keywords: languages
;; Package-Requires: ((emacs "24.3") (s "1.12.0"))

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

;; inform7-mode provides a major mode for interacting with files
;; written in Inform 7 syntax.
;;
;; For more information see the README.

;;; Code:


;;;;;;;;;;;;;;;;;;;;;
;;;;; Font Lock ;;;;;
;;;;;;;;;;;;;;;;;;;;;


(require 'font-lock)

(defgroup inform7-faces nil
  "Faces used in Inform 7 mode."
  :group 'inform7
  :group 'faces)

(defface inform7-string-face
  '((t . (:inherit font-lock-string-face :weight bold :foreground "#004D99")))
  "Face for Inform 7 strings."
  :group 'inform7-faces)

(defface inform7-substitution-face
  '((t . (:inherit variable-pitch :slant italic :foreground "#3E9EFF")))
  "Face for Inform 7 substitutions embedded in text."
  :group 'inform7-faces)

(defface inform7-rule-name-face
  '((t . (:inherit font-lock-keyword-face)))
  "Face for Inform 7 rule names."
  :group 'inform7-faces)

(defface inform7-heading-volume-face
  '((t . (:inherit inform7-heading-book-face :height 1.4)))
  "Face for Inform 7 volume headings."
  :group 'inform7-faces)

(defface inform7-heading-book-face
  '((t . (:inherit inform7-heading-part-face :height 1.3)))
  "Face for Inform 7 book headings."
  :group 'inform7-faces)

(defface inform7-heading-part-face
  '((t . (:inherit inform7-heading-chapter-face :height 1.2)))
  "Face for Inform 7 part headings."
  :group 'inform7-faces)

(defface inform7-heading-chapter-face
  '((t . (:inherit inform7-heading-section-face :height 1.1)))
  "Face for Inform 7 chapter headings."
  :group 'inform7-faces)

(defface inform7-heading-section-face
  '((t . (:inherit variable-pitch :weight bold)))
  "Face for Inform 7 section headings."
  :group 'inform7-faces)

(defun inform7--make-regex-bol (re)
  "Produce a regular expression for matching RE at the beginning of the line.

Ignores whitespace."
  (format "\\(?:^[[:blank:]]*\\)%s" re))

(defun inform7--make-regex-heading (keyword)
  "Produce a regular expression for matching headings started by the given KEYWORD."
  (inform7--make-regex-bol (format "%s[[:blank:]]+[^[:blank:]].*$" keyword)))

(defconst inform7-regex-heading
  (inform7--make-regex-heading "\\(?:Volume\\|Book\\|Part\\|Chapter\\|Section\\)")
  "Regular expression for an Inform 7 heading.")

(defconst inform7-regex-heading-volume
  (inform7--make-regex-heading "Volume")
  "Regular expression for an Inform 7 volume heading.")

(defconst inform7-regex-heading-book
  (inform7--make-regex-heading "Book")
  "Regular expression for an Inform 7 book heading.")

(defconst inform7-regex-heading-part
  (inform7--make-regex-heading "Part")
  "Regular expression for an Inform 7 part heading.")

(defconst inform7-regex-heading-chapter
  (inform7--make-regex-heading "Chapter")
  "Regular expression for an Inform 7 chapter heading.")

(defconst inform7-regex-heading-section
  (inform7--make-regex-heading "Section")
  "Regular expression for an Inform 7 section heading.")

(defconst inform7-regex-substitution-maybe-open
  "\\[\\(?:[^]]\\|\\n\\)*\\]?+"
  "Regular expression for matching a substitution embedded in an Inform 7 string (which may not be closed).")

(defconst inform7-regex-string-maybe-open
  (format "\"\\(?:%s\\|[^\"]\\|\\n\\)*\"?+" inform7-regex-substitution-maybe-open)
  "Regular expression for matching an Inform 7 string (which may not be closed).")

(defconst inform7-regex-standard-rule
  (inform7--make-regex-bol
   (regexp-opt-group
    '("After"
      "Before"
      "Check"
      "Carry out"
      "Every"
      "Instead of"
      "Report"
      "When") t))
  "Regular expression for matching a standard Inform 7 rule.")

(defun inform7--match-inside (outer matcher facespec)
  "Match inside the match OUTER with MATCHER, fontifying with FACESPEC."
  (let ((preform `(progn
                    (goto-char (match-beginning 0))
                    (match-end 0))))
    `(,outer . '(,matcher ,preform nil (0 ,facespec t)))))

(defvar inform7-font-lock-keywords
  `((,inform7-regex-heading-volume . 'inform7-heading-volume-face)
    (,inform7-regex-heading-book . 'inform7-heading-book-face)
    (,inform7-regex-heading-part . 'inform7-heading-part-face)
    (,inform7-regex-heading-chapter . 'inform7-heading-chapter-face)
    (,inform7-regex-heading-section . 'inform7-heading-section-face)
    ;; standard rules
    (,inform7-regex-standard-rule . 'inform7-rule-name-face)
    ;; strings
    (,inform7-regex-string-maybe-open 0 'inform7-string-face t)
    ;; substitutions
    ,(inform7--match-inside inform7-regex-string-maybe-open inform7-regex-substitution-maybe-open `'inform7-substitution-face))
  "Syntax highlighting for Inform 7 files.")


;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; imenu Support ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;


(require 's)

(defun inform7--normalise-heading-string (heading)
  "Normalise the heading string HEADING.

This does the following: removes extra whitespace."
  (s-collapse-whitespace (s-trim heading)))

(defun inform7-imenu-create-flat-index ()
  "Produce a flat imenu index for the current buffer.
See `imenu-create-index-function' for details."
  (let (index)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward inform7-regex-heading nil t)
        (let ((heading (inform7--normalise-heading-string (match-string-no-properties 0)))
              (pos (match-beginning 0)))
          (setq index (append index (list (cons heading pos)))))))
    index))


;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Indentation ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;


(defun inform7--in-string-p (point)
  "Return non-NIL if POINT is in a string."
  (let ((face (get-text-property point 'face)))
    (memq face '(inform7-substitution-face inform7-string-face))))

(defun inform7--in-comment-p (point)
  "Return non-NIL if POINT is in a comment."
  (let ((face (get-text-property point 'face)))
    (eq face 'font-lock-comment-face)))

(defun inform7--goto-line (line)
  "Move point to the beginning of LINE."
  (save-restriction
    (widen)
    (goto-char (point-min))
    (forward-line (1- line))))

(defun inform7--line-starts-indent (line)
  "Return non-NIL if LINE should cause subsequent lines to indent."
  (save-excursion
    (inform7--goto-line line)
    (looking-at-p "^.*:[[:space:]]*$")))

(defun inform7--line-indentation (line)
  "Return the horizontal indentation for LINE."
  (save-excursion
    (inform7--goto-line line)
    (current-indentation)))

(defun inform7--max-indentation ()
  "The maximum indentation for the current line."
  ;; first line has max indentation 0
  (if (eq (line-number-at-pos) 1) 0
    (let* ((previous-line (save-excursion (forward-line -1) (line-number-at-pos)))
           (prev-indent (inform7--line-indentation previous-line)))
      (if (inform7--line-starts-indent previous-line)
          (+ tab-width prev-indent)
        prev-indent))))

(defun inform7-indent-line ()
  "Indent the current line as Inform 7 code."
  (interactive)
  (if (or (inform7--in-string-p (point)) (inform7--in-comment-p (point)))
      ;; no indentation cycles if in a string or comment
      'noindent
    (indent-to (inform7--max-indentation))))


;;;;;;;;;;;;;;;;;;;;;;
;;;;; Major Mode ;;;;;
;;;;;;;;;;;;;;;;;;;;;;


;;;###autoload
(define-derived-mode inform7-mode text-mode
  "Inform7"
  "Major mode for editing Inform 7 files."

  ;; Comments
  (setq-local comment-start "[")
  (setq-local comment-end "]")
  (setq-local comment-start-skip "\\[[[:space:]]*")
  (setq-local comment-column 0)
  (setq-local comment-auto-fill-only-comments nil)
  (setq-local comment-use-syntax t)

  ;; Identing
  (setq-local tab-width 4)
  (setq-local indent-line-function 'inform7-indent-line)

  ;; Font Lock
  (setq-local font-lock-defaults
              '(inform7-font-lock-keywords
                ;; fontify syntax (not just keywords)
                nil
                ;; ignore case of keywords
                t
                ((?\[ . "< n") ; open block comment
                 (?\] . "> n") ; close block comment
                 (?\" . ".")   ; quote
                 (?\\ . "."))  ; backslashes don't escape
                (font-lock-multiline . t)))

  ;; imenu support
  (setq imenu-create-index-function
        #'inform7-imenu-create-flat-index))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.\\(ni\\|i7\\)\\'" . inform7-mode)) ; Inform 7 source files (aka 'Natural Inform')
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.i7x\\'" . inform7-mode))           ; Inform 7 extension files


(provide 'inform7)
;;; inform7.el ends here
