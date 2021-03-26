;;; pikchr-mode.el --- A major mode for the pikchr diagram markup language -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Johann Klähn

;; Author: Johann Klähn <johann@jklaehn.de>
;; URL: https://github.com/kljohann/pikchr-mode
;; Package-Version: 20210324.2125
;; Package-Commit: 5d424c5c97ac854cc44c369e654e4f906fcae3c8
;; Keywords: languages
;; Version: 0
;; Package-Requires: ((emacs "27.1"))

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

;; A major mode for the pikchr (https://pikchr.org/) diagram markup language.

;;; Code:

(require 'ob)
(require 'regexp-opt)
(require 'rng-util)
(require 'rx)

(defgroup pikchr nil
  "Pikchr support for Emacs."
  :group 'languages)

(defcustom pikchr-executable
  (or (executable-find "pikchr")
      "pikchr")
  "Location of the pikchr executable."
  :group 'pikchr
  :type '(file :must-match t)
  :risky t)

(defconst pikchr-preview-buffer-name " *pikchr preview*")

(defun pikchr--face-to-style (face)
  "Derive CSS properties from FACE."
  (format "font-family: %s;"
          (face-attribute face :family)))

(defun pikchr-preview-region (start end)
  "Preview the pikchr diagram in the region between START and END."
  (interactive "r")
  (let ((infile (make-temp-file "pikchr-mode-"))
        (preview-buffer (get-buffer-create pikchr-preview-buffer-name)))
    (unwind-protect
        (progn
          (write-region start end infile nil 'silent)
          (let ((inhibit-read-only t))
            (with-current-buffer preview-buffer
              (erase-buffer)
              (call-process pikchr-executable nil
                            t nil "--svg-only" infile))))
      (delete-file infile))
    (with-current-buffer preview-buffer
      (goto-char (point-min))
      (if (looking-at "<svg")
          (progn
            (forward-symbol 1)
            (let ((inhibit-read-only t))
              (insert
               (format " style=\"%s\""
                       (rng-escape-string
                        (pikchr--face-to-style 'variable-pitch)))))
            (image-mode))
        (delete-trailing-whitespace)
        (pikchr-mode)
        (font-lock-ensure)
        (view-mode)))
    (display-buffer preview-buffer)))

(defun pikchr-preview-dwim ()
  "Preview the pikchr diagram in the current buffer.

Uses the region if it is active.  If a prefix argument is given
instead, the buffer up to and including the current line.
Else, the whole buffer is used."
  (interactive)
  (cond ((use-region-p)
         (pikchr-preview-region (region-beginning) (region-end)))
        (current-prefix-arg
         (pikchr-preview-region (point-min) (line-end-position)))
        (t (pikchr-preview-region (point-min) (point-max)))))

(defmacro pikchr-mode--rx-let (&rest body)
  (declare (indent defun) (debug (body)))
  `(rx-let ((ws* (* space))
            (symb (| word (syntax symbol)))
            (stmt-start (| bol ";"))
            (place-name (: (any "A-Z") (* (any alnum "_"))))
            (place-label (: stmt-start ws* (group place-name) ws* ":"))
            (variable-def
             (&rest extra)
             (: stmt-start ws* (group (any extra "$@") (+ symb))
                ws* (? (any "-+*/")) "="))
            (macro-def (: stmt-start ws* "define" (+ space)
                          (group (any "a-z" "_$@") (+ symb)))))
     ,@body))

(defconst pikchr-mode-font-lock-keywords
  (pikchr-mode--rx-let
    `(
      ;; Ordinals
      (,(rx bow (+ digit) (| "th" "rd" "nd" "st") eow)
       . font-lock-builtin-face)
      ;; Hexadecimal integer constants
      (,(rx bow "0x" (+ digit) eow)
       . font-lock-constant-face)
      ;; Decimal integer or floating point constants
      (,(rx
         bow
         (? (any "+-"))
         (| (: (+ digit) (? "." (* digit)))
            (: "." (+ digit)))
         (? (any "eE")
            (? any "+-")
            (+ digit))
         (? (| "%" "in" "cm" "mm" "pt" "px" "pc"))
         eow)
       . font-lock-constant-face)
      ;; Built-in variables
      (,(regexp-opt
         '("arcrad" "arrowhead" "arrowht" "arrowwid" "bottommargin" "boxht"
           "boxrad" "boxwid" "charht" "charwid" "circlerad" "color" "cylht"
           "cylrad" "cylwid" "dashwid" "dotrad" "ellipseht" "ellipsewid" "fileht"
           "filerad" "filewid" "fill" "fontscale" "layer" "leftmargin" "lineht"
           "linerad" "linewid" "margin" "movewid" "ovalht" "ovalwid" "rightmargin"
           "scale" "textht" "textwid" "thickness" "topmargin") 'symbols)
       . font-lock-builtin-face)
      ;; Variable definitions
      (,(rx (variable-def "a-z"))
       (1 font-lock-variable-name-face))
      ;; Place labels
      (,(rx place-label)
       (1 font-lock-function-name-face))
      ;; Macros
      (,(rx macro-def)
       (1 font-lock-function-name-face))
      ;; Objects
      (,(regexp-opt
         '("arc" "arrow" "box" "circle" "cylinder" "dot" "ellipse" "file" "line"
           "move" "oval" "spline" "text") 'symbols)
       . font-lock-type-face)
      ;; Keywords
      (,(regexp-opt
         '("above" "abs" "aligned" "and" "as" "assert" "at" "behind" "below"
           "between" "big" "bold" "bot" "bottom" "c" "ccw" "center" "chop" "close"
           "color" "cos" "cw" "dashed" "define" "diameter" "dist" "dotted" "down"
           "e" "east" "end" "even" "fill" "first" "fit" "from" "go" "heading"
           "height" "ht" "in" "int" "invis" "invisible" "italic" "last" "left"
           "ljust" "max" "min" "n" "ne" "north" "nw" "of" "previous" "print" "rad"
           "radius" "right" "rjust" "s" "same" "se" "sin" "small" "solid" "south"
           "sqrt" "start" "sw" "t" "the" "then" "thick" "thickness" "thin" "to"
           "top" "until" "up" "vertex" "w" "way" "west" "wid" "width" "with"
           "x" "y" "<-" "->" "<->") 'symbols)
       . font-lock-keyword-face))))

(defconst pikchr-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?$ "_" table)
    (modify-syntax-entry '(?% . ?&) "." table)
    (modify-syntax-entry ?* ". 23b" table)
    (modify-syntax-entry '(?+ . ?.) "." table)
    (modify-syntax-entry ?@ "_" table)
    (modify-syntax-entry ?< "(>" table)
    (modify-syntax-entry ?= "." table)
    (modify-syntax-entry ?> ")<" table)
    (modify-syntax-entry ?/ ". 124" table)
    (modify-syntax-entry ?_ "." table)
    (modify-syntax-entry ?| "." table)
    table)
  "Syntax table for `pikchr-mode'.")

(defconst pikchr-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'pikchr-preview-dwim)
    map)
  "Keymap for `pikchr-mode'.")

;;;###autoload
(define-derived-mode pikchr-mode prog-mode "pikchr mode"
  "Major mode for the pikchr diagram markup language."
  :syntax-table pikchr-mode-syntax-table
  (setq-local comment-use-syntax t)
  (setq-local comment-start "#")
  (setq-local comment-end "")
  (setq font-lock-defaults '(pikchr-mode-font-lock-keywords))
  (setq-local imenu-generic-expression
              (pikchr-mode--rx-let
                `(("Places" ,(rx place-label) 1)
                  ;; Only variable definitions beginning with $ and @.
                  ("Variables" ,(rx (variable-def)) 1)
                  ("Macros" ,(rx macro-def) 1)))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pikchr\\'" . pikchr-mode))

(defvar org-babel-default-header-args:pikchr
  '((:results . "output file") (:exports . "results"))
  "Default arguments to use when evaluating a pikchr source block.")

(defun org-babel-execute:pikchr (body params)
  "Execute a block of pikchr code with org-babel.
This function is called by `org-babel-execute-src-block', which passes
the block contents as BODY and its header argumenst as PARAMS."
  (unless (assq :file params)
    (user-error "Missing :file header argument for pikchr block"))
  (let ((in-file (org-babel-temp-file "pikchr-")))
    (with-temp-file in-file
      (insert body))
    (org-babel-eval
     (concat (org-babel-process-file-name pikchr-executable)
             " --svg-only " (org-babel-process-file-name in-file))
     "")))

(defun org-babel-prep-session:pikchr (_session _params)
  "Return an error because pikchr does not support sessions."
  (user-error "Sessions are not supported by pikchr"))

(provide 'pikchr-mode)
;;; pikchr-mode.el ends here
