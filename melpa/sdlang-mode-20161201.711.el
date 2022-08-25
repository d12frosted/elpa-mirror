;;; sdlang-mode.el --- Major mode for Simple Declarative Language files.

;; Version: 0.1.0
;; Package-Version: 20161201.711
;; Package-Commit: d42a6eedefeb44919fbacf58d302b6df18f05bbc
;; Author: Vladimir Panteleev
;; Url: https://github.com/CyberShadow/sdlang-mode
;; Keywords: languages
;; Package-Requires: ((emacs "24.3"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; A Major Emacs mode for editing Simple Declarative Language files.

;; For more information about SDLang, see:
;; https://sdlang.org/

;;; Code:

(require 'rx)

(defgroup sdlang-mode nil
  "Major mode for editing Simple Declarative Language files."
  :link '(url-link "https://sdlang.org/")
  :group 'languages)

;; (defface sdlang-mode-comment-face
;;   '((t :inherit font-lock-comment-face))
;;   "Font for comments."
;;   :group 'sdlang-mode)

(defface sdlang-mode-tag-face
  '((t :inherit font-lock-keyword-face))
  "Font for tag names."
  :group 'sdlang-mode)

(defface sdlang-mode-namespace-face
  '((t :inherit font-lock-type-face))
  "Font for tag namespaces."
  :group 'sdlang-mode)

(defface sdlang-mode-attribute-face
  '((t :inherit font-lock-variable-name-face))
  "Font for attribute names."
  :group 'sdlang-mode)

(defface sdlang-mode-punctuation-face
  '((t :inherit default))
  "Font for punctuation characters."
  :group 'sdlang-mode)

(defface sdlang-mode-string-face
  '((t :inherit font-lock-string-face))
  "Font for string values."
  :group 'sdlang-mode)

(defface sdlang-mode-number-face
  '((t :inherit default))
  "Font for numeric values."
  :group 'sdlang-mode)

(defface sdlang-mode-boolean-face
  '((t :inherit font-lock-constant-face))
  "Font for boolean/null values."
  :group 'sdlang-mode)

(defface sdlang-mode-date-face
  '((t :inherit sdlang-mode-number-face))
  "Font for numeric values."
  :group 'sdlang-mode)

(defface sdlang-mode-data-face
  '((t :inherit font-lock-string-face))
  "Font for embedded binary data."
  :group 'sdlang-mode)

(defface sdlang-mode-error-face
  '((t :inherit font-lock-warning-face))
  "Font for invalid syntax."
  :group 'sdlang-mode)

(defvar sdlang-mode-font-lock-keywords)
(setq sdlang-mode-font-lock-keywords
  `(
    ;; Binary data
    ("\\["
     (0 'sdlang-mode-punctuation-face)
     ("[a-zA-Z0-9 /+]+"
      (sdlang-mode-end-of-data)
      nil
      (0 'sdlang-mode-data-face))
     ("\\]"
      (sdlang-mode-end-of-data)
      nil
      (0 'sdlang-mode-punctuation-face)
      )
     ("[^]\n +/-9A-[a-z]"
      (sdlang-mode-end-of-data)
      nil
      (0 'sdlang-mode-error-face))
     )

    ;; Comments
    ;; ("\\(?:--\\|//\\|#\\).*$" . 'sdlang-mode-comment-face)

    ;; WYSIWYG strings
    ;; ("`.*`" . 'sdlang-mode-string-face)

    ;; Date/time values
    (,(rx
       bow
       (= 4 (any (?0 . ?9)))
       "/"
       (= 2 (any (?0 . ?9)))
       "/"
       (= 2 (any (?0 . ?9)))
       (zero-or-one
	" "
	(= 2 (any (?0 . ?9)))
	":"
	(= 2 (any (?0 . ?9)))
	(zero-or-one
	 ":"
	 (= 2 (any (?0 . ?9)))
	 (zero-or-one
	  "."
	  (one-or-more (any (?0 . ?9)))))
	(zero-or-one
	 "-"
	 (= 3 (any (?A . ?Z)))))
       eow) . 'sdlang-mode-date-face)

    ;; Time / duration values
    (,(rx
       bow
       (zero-or-one
	(one-or-more (any (?0 . ?9)))
	"d:")
       (= 2 (any (?0 . ?9)))
       ":"
       (= 2 (any (?0 . ?9)))
       (zero-or-one
	":"
	(= 2 (any (?0 . ?9)))
	(zero-or-one
	 "."
	 (one-or-more (any (?0 . ?9)))))
       eow) . 'sdlang-mode-date-face)

    ;; Numeric values
    ("\\<[+-]?[0-9]+\\(?:\\.[0-9]*\\)?\\(?:[eE][+-]?[0-9]+\\)?L?B?D?f?\\>" . 'sdlang-mode-number-face)

    ;; Boolean values
    ("\\<\\(true\\|false\\|on\\|off\\|null\\)\\>" . 'sdlang-mode-boolean-face)

    ;; Attributes
    (,(rx
       bow
       (submatch (one-or-more (syntax word)))
       (submatch "="))
     (1 'sdlang-mode-attribute-face)
     (2 'sdlang-mode-punctuation-face))

    ;; Tags
    (,(rx
       (or
	(submatch ?\;)
	bol)
       (zero-or-more
	(syntax whitespace))
       bow
       (zero-or-one
	(submatch (one-or-more (syntax word)))
	(submatch ":"))
       (submatch (one-or-more (syntax word)))
       eow)
     (1 'sdlang-mode-punctuation-face nil t)
     (2 'sdlang-mode-namespace-face nil t)
     (3 'sdlang-mode-punctuation-face nil t)
     (4 'sdlang-mode-tag-face))

    ;; Punctuation
    (,(rx (any ?{ ?})) . 'sdlang-mode-punctuation-face)
    (,(rx (any ?\\ ?\;) eol) . 'sdlang-mode-punctuation-face)

    ;; Anything else is an error
    ("[^ \n]" . 'sdlang-mode-error-face)
    ))

(defvar sdlang-mode-syntax-table nil "Syntax table for `sdlang-mode'.")

(setq sdlang-mode-syntax-table
      (let ((table (make-syntax-table)))
        ;; (modify-syntax-entry ?\/ ". 14" table) ; /*
        ;; (modify-syntax-entry ?* ". 23" table)  ; */
        (modify-syntax-entry ?\/ ". 124ab" table) ; /* */ and //
        (modify-syntax-entry ?* ". 23" table)  ; /* */
        (modify-syntax-entry ?# "< b" table)   ; #
        (modify-syntax-entry ?- "w 12b" table) ; --
        (modify-syntax-entry ?\n "> b" table)  ; end of // -- #

	(modify-syntax-entry ?` "\"" table)

	;; (modify-syntax-entry ?- "w" table)
	(modify-syntax-entry ?_ "w" table)
	(modify-syntax-entry ?. "w" table)
        table))

(defun sdlang-mode-end-of-data (&rest foo)
  "Return position of the end of data blocks.  FOO is ignored."
  (search-backward "[")
  (save-excursion
    (search-forward "]" nil t)
    (point)))

;;;###autoload
(define-derived-mode sdlang-mode prog-mode "SDLang"
  "Major mode for editing Simple Declarative Language files."

  :group 'sdlang-mode

  ;; Settings
  (setq-local font-lock-multiline t)

  ;; Comments
  (setq-local comment-start "# ")
  (setq-local comment-end   "")

  ;; Syntax
  (setq-local font-lock-defaults '(sdlang-mode-font-lock-keywords
                                   nil nil nil nil))
  ;; Raw string literals
  (setq-local
   syntax-propertize-function
   (syntax-propertize-rules
    ((rx
      "`"
      (minimal-match
       (zero-or-more
	(not (any "`\\"))))
      (minimal-match
       (one-or-more
	(submatch "\\")
	(minimal-match
	 (zero-or-more
	  (not (any "`\\"))))))
      "`")
     (1 ".")))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sdl\\'" . sdlang-mode))

(provide 'sdlang-mode)
;;; sdlang-mode.el ends here
