;;; pasp-mode.el ---- A major mode for editing Answer Set Programs. -*- lexical-binding: t -*-

;; Copyright (c) 2017 by Henrik Jürges

;; Author: Henrik Jürges <juerges.henrik@gmail.com>
;; URL: https://github.com/santifa/pasp-mode
;; Package-Version: 20180404.1700
;; Package-Commit: 59385eb0e8ebcfc8c11dd811fb145d4b0fa3cc92
;; Version: 0.1.0
;; Package-requires: ((emacs "24.3"))
;; Keywords: asp, pasp, Answer Set Programs, Potassco Answer Set Programs, Major mode, languages

;; You can redistribute this program and/or modify it under the terms of the GNU
;; General Public License as published by the Free Software Foundation; either
;; version 3 of the License, or (at your option) any later version..

;;; Commentary:

;; A major mode for editing Answer Set Programs, formally Potassco
;; Answer Set Programs (https://potassco.org/).
;; 
;; Answer Set Programs are mainly used to solve complex combinatorial
;; problems by impressive search methods.
;; The modeling language follows a declarative approach with a minimal
;; amount of fixed syntax constructs.

;;; Install

;; Open the file with Emacs and run "M-x eval-buffer"
;; Open an ASP file and run "M-x pasp-mode"

;; To manually load this file within your Emacs config
;; add this file to your load path and place
;; (require 'pasp-mode)
;; in your init file.

;; See "M-x customize-mode pasp-mode" for information
;; about mode configuration.

;;; Features

;; - Syntax highlighting (predicates can be toggled)
;; - Commenting of blocks and standard
;; - Run ASP program from within Emacs and get the compilation output
;; - Auto-load mode when a *.lp file is opened

;;; Todo

;; - Smart indentation based on nesting depth
;; - Refactoring of predicates/variables (complete buffer and #program parts)
;; - Color compilation output
;; - Smart rearrange of compilation output (predicates separated, table...)
;; - yas-snippet for rules; constraints; soft constraints; generation?

;;; Keybindings

;; "C-c C-e" - Call clingo with current buffer and an instance file
;; "C-c C-b" - Call clingo with current buffer

;; Remark

;; I'm not an elisp expert, this is a very basic major mode.
;; It is intended to get my hands dirty with elisp but also
;; to be a help full tool.
;; This mode should provide a basic environment for further
;; integration of Answer Set Programs into Emacs.

;; Ideas, issues and pull requests are highly welcome!

;;; Code:

(require 'compile)

;;; Customization

(defgroup pasp-mode nil
  "Major mode for editing Anwser Set Programs."
  :group 'languages
  :prefix "pasp-")

(defcustom pasp-mode-version "0.2.0"
  "Version of `pasp-mode'."
  :group 'pasp-mode)

(defcustom pasp-indentation 2
  "Level of indentation."
  :type 'integer
  :group 'pasp-mode)

(defcustom pasp-clingo-path (executable-find "clingo")
  "Path to clingo binary used for execution."
  :type 'string
  :group 'pasp-mode)

(defcustom pasp-clingo-options ""
  "Command line options passed to clingo."
  :type 'string
  :group 'pasp-mode
  :safe #'stringp)

(defcustom pasp-pretty-symbols-p t
  "Use Unicode characters where appropriate."
  :type 'boolean
  :group 'pasp-mode)

;;; Pretty Symbols

(defvar pasp-mode-hook
  (lambda ()
    (when pasp-pretty-symbols-p
      (push '(":-" . ?⊢) prettify-symbols-alist)
      (push '(">=" . ?≥) prettify-symbols-alist)
      (push '("<=" . ?≤) prettify-symbols-alist)
      (push '("!=" . ?≠) prettify-symbols-alist)
     (push '("not" . ?¬) prettify-symbols-alist))))

;;; Syntax table

(defvar pasp-mode-syntax-table nil "Syntax table for `pasp-mode`.")
(setq pasp-mode-syntax-table
      (let ((table (make-syntax-table)))
        ;; modify syntax table
        (modify-syntax-entry ?' "w" table)
        (modify-syntax-entry ?% "<" table)
        (modify-syntax-entry ?\n ">" table)
        (modify-syntax-entry ?, "_ p" table)
        table))

;;; Syntax highlighting faces

(defvar pasp-atom-face 'pasp-atom-face)
(defface pasp-atom-face
  '((t (:inherit font-lock-keyword-face :weight normal)))
  "Face for ASP atoms (starting with lower case)."
  :group 'font-lock-highlighting-faces)

(defvar pasp-construct-face 'pasp-construct-face)
(defface pasp-construct-face
  '((default (:inherit font-lock-builtin-face :height 1.1)))
  "Face for ASP base constructs."
  :group 'font-lock-highlighting-faces)

;; Syntax highlighting

(defvar pasp--constructs
  '("\\.\\|:-\\|:\\|_\\|;\\|:~\\|,\\|(\\|)\\|{\\|}\\|[\\|]\\|not " . pasp-construct-face)
   "ASP constructs.")

(defconst pasp--constant
  '("#[[:word:]]+" . font-lock-builtin-face)
  "ASP constants.")

(defconst pasp--variable
  '("_*[[:upper:]][[:word:]_']*" . font-lock-variable-name-face)
  "ASP variable.")

(defconst pasp--variable2
  '("\\_<\\(_*[[:upper:]][[:word:]_']*\\)\\_>" . (1 font-lock-variable-name-face))
  "ASP variable 2.")

(defconst pasp--atom
  '("_*[[:lower:]][[:word:]_']*" . pasp-atom-face)
  "ASP atoms.")

(defvar pasp-highlighting nil
  "Regex list for syntax highlighting.")
(setq pasp-highlighting
      (list
       pasp--constructs
       pasp--constant
       pasp--variable2
       pasp--atom
       pasp--variable))

;;; Compilation

(defvar pasp-error-regexp
  "^[  ]+at \\(?:[^\(\n]+ \(\\)?\\(\\(?:[a-zA-Z]:\\)?[a-zA-Z\.0-9_/\\-]+\\):\\([0-9]+\\):\\([0-9]+\\)\)?"
  "Taken from NodeJS -> only dummy impl.")

(defvar pasp-error-regexp-alist
  `((,pasp-error-regexp 1 2 3))
  "Taken from NodeJs -> only dummy impl.")

(defun pasp-compilation-filter ()
  "Filter clingo output.  (Only dummy impl.)."
  (ansi-color-apply-on-region compilation-filter-start (point-max))
  (save-excursion
    (while (re-search-forward "^[\\[[0-9]+[a-z]" nil t)
      (replace-match ""))))

(define-compilation-mode pasp-compilation-mode "ASP"
  "Major mode for running ASP files."
  (progn
    (set (make-local-variable 'compilation-error-regexp-alist) pasp-error-regexp-alist)
    (add-hook 'compilation-filter-hook 'pasp-compilation-filter nil t)))

(defun pasp-generate-command (encoding &optional instance)
  "Generate Clingo call with some ASP input file.

Argument ENCODING The current buffer which holds the problem encoding.
Optional argument INSTANCE The problem instance which is solved by the encoding.
  If no instance it is assumed to be also in the encoding file."
  (if 'instance
      (concat pasp-clingo-path " " pasp-clingo-options " " encoding " " instance)
    (concat pasp-clingo-path " " pasp-clingo-options " " encoding)))

(defun pasp-run-clingo (encoding &optional instance)
  "Run Clingo with some ASP input files.
Be aware: Partial ASP code may lead to abnormally exits while
the result is sufficient.

Argument ENCODING The current buffer which holds the problem encoding.
Optional argument INSTANCE The problem instance which is solved by the encoding.
  If no instance it is assumed to be also in the encoding file."
  (when (get-buffer "*clingo output*")
    (kill-buffer "*clingo output*"))
  (let ((test-command-to-run (pasp-generate-command encoding instance))
        (compilation-buffer-name-function (lambda (_) "" "*clingo output*")))
    (compile test-command-to-run 'pasp-compilation-mode)))

;;;###autoload
(defun pasp-run-buffer ()
  "Run clingo with the current buffer as input."
  (interactive)
  (pasp-run-clingo (buffer-file-name)))

;; save the last user input
(defvar pasp-last-instance "")

;;;###autoload
(defun pasp-run (instance)
  "Run clingo with the current buffer and some user provided INSTANCE as input."
  (interactive
   (list (read-file-name
          (format "Instance [%s]:" (file-name-nondirectory pasp-last-instance))
          nil pasp-last-instance)))
    (setq-local pasp-last-instance instance)
    (pasp-run-clingo (buffer-file-name) instance))

;;; Utility functions

(defun pasp-reload-mode ()
    "Reload the PASP major mode."
  (interactive)
  (progn
    (unload-feature 'pasp-mode)
    (require 'pasp-mode)
    (pasp-mode)))

;;; File ending

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lp\\'" . pasp-mode))

;;; Define pasp mode

;;;###autoload
(define-derived-mode pasp-mode prog-mode "Potassco ASP"
  "A major mode for editing Answer Set Programs."
  (setq font-lock-defaults '(pasp-highlighting))
  
  ;; define the syntax for un/comment region and dwim
  (setq-local comment-start "%")
  (setq-local comment-end "")
  (setq-local tab-width pasp-indentation))

;;; Keymap

(define-key pasp-mode-map (kbd "C-c C-b") 'pasp-run-buffer)
(define-key pasp-mode-map (kbd "C-c C-e") 'pasp-run)


;; add mode to feature list
(provide 'pasp-mode)

;;; pasp-mode.el ends here
