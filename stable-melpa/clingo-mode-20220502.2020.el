;;; clingo-mode.el --- A major mode for editing Answer Set Programs -*- lexical-binding: t -*-

;; Copyright (c) 2020 by Ivan Uemlianin
;; Copyright (c) 2017 by Henrik Jürges

;; Author: Ivan Uemlianin <ivan@llaisdy.com>
;; URL: https://github.com/llaisdy/clingo-mode
;; Package-Version: 20220502.2020
;; Package-Commit: cf56ce6b5c50506f6cea27e1dde0441dd8d15ee9
;; Version: 0.4.0
;; Author: Henrik Jürges <juerges.henrik@gmail.com>
;; URL: https://github.com/santifa/pasp-mode
;; Version: 0.1.0
;; Package-requires: ((emacs "24.3"))
;; Keywords: asp, clingo, Answer Set Programs, Potassco, Major mode, languages

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

;; A major mode for editing Answer Set Programs, formally Potassco
;; Answer Set Programs (https://potassco.org/).
;;
;; Answer Set Programs are mainly used to solve complex combinatorial
;; problems by impressive search methods.
;; The modeling language follows a declarative approach with a minimal
;; amount of fixed syntax constructs.

;;; Install

;; Open the file with Emacs and run "M-x eval-buffer"
;; Open an ASP file and run "M-x clingo-mode"

;; To manually load this file within your Emacs config
;; add this file to your load path and place
;; (require 'clingo-mode)
;; in your init file.

;; See "M-x customize-mode clingo-mode" for information
;; about mode configuration.

;;; Features

;; - Syntax highlighting (predicates can be toggled)
;; - Commenting of blocks and standard
;; - Run ASP program from within Emacs and get the compilation output
;; - Auto-load mode when a *.lp file is opened

;;; Keybindings

;; "C-c C-e" - Call clingo with current buffer and an instance file
;; "C-c C-b" - Call clingo with current buffer
;; "C-c C-r" - Call clingo with current region
;; "C-c C-c" - Comment region
;; "C-c C-u" - Uncomment region

;; Remark

;; I'm not an elisp expert, this is a very basic major mode.
;; It is intended to get my hands dirty with elisp but also
;; to be a help full tool.
;; This mode should provide a basic environment for further
;; integration of Answer Set Programs into Emacs.

;; Ideas, issues and pull requests are highly welcome!

;;; Todo:

;; - TOP: make clingo-generate-echo safe
;; - Smart indentation based on nesting depth
;; - Refactoring of predicates/variables (complete buffer and #program parts)
;; - Color compilation output
;; - Smart rearrangement of compilation output (predicates separated, table...)
;; - yas-snippet for rules; constraints; soft constraints; generation?
;; - sync as much as possible with vim-syntax-clingo

;;; Code:

(require 'compile)

;;; Customization

(defgroup clingo nil
  "Major mode for editing Answer Set Programs."
  :group 'languages
  :prefix "clingo-")

(defcustom clingo-mode-version "0.4.0"
  "Version of `clingo-mode'."
  :type 'string
  :group 'clingo-mode)

(defcustom clingo-indentation 2
  "Level of indentation."
  :type 'integer
  :group 'clingo-mode)

(defcustom clingo-path (executable-find "clingo")
  "Path to clingo binary used for execution."
  :type 'string
  :group 'clingo-mode)

(defcustom clingo-options ""
  "Command line options passed to clingo."
  :type 'string
  :group 'clingo-mode
  :safe #'stringp)

(defcustom clingo-pretty-symbols-p t
  "Use Unicode characters where appropriate."
  :type 'boolean
  :group 'clingo-mode)

;;; Pretty Symbols

(defvar clingo-mode-hook
  (lambda ()
    (when clingo-pretty-symbols-p
      (push '(":-" . ?⊢) prettify-symbols-alist)
      (push '(">=" . ?≥) prettify-symbols-alist)
      (push '("<=" . ?≤) prettify-symbols-alist)
      (push '("!=" . ?≠) prettify-symbols-alist)
      (push '("not" . ?¬) prettify-symbols-alist))))

;;; Syntax table

(defvar clingo-mode-syntax-table nil "Syntax table for `clingo-mode`.")
(setq clingo-mode-syntax-table
      (let ((table (make-syntax-table)))
        ;; modify syntax table
        (modify-syntax-entry ?' "w" table)
        (modify-syntax-entry ?% "<" table)
        (modify-syntax-entry ?\n ">" table)
        (modify-syntax-entry ?, "_ p" table)
        table))

;;; Syntax highlighting faces

(defvar clingo-atom-face 'clingo-atom-face)
(defface clingo-atom-face
  '((t (:inherit font-lock-keyword-face :weight normal)))
  "Face for ASP atoms (starting with lower case)."
  :group 'font-lock-highlighting-faces)

(defvar clingo-construct-face 'clingo-construct-face)
(defface clingo-construct-face
  '((default (:inherit font-lock-builtin-face :height 1.1)))
  "Face for ASP base constructs."
  :group 'font-lock-highlighting-faces)

;; Syntax highlighting

(defvar clingo--constructs
  '("\\.\\|:-\\|:\\|;\\|:~\\|,\\|(\\|)\\|{\\|}\\|[\\|]\\|not " . clingo-construct-face)
   "ASP constructs.")

(defconst clingo--constant
  '("#[[:word:]]+" . font-lock-builtin-face)
  "ASP constants.")

(defconst clingo--variable
  '("[^[:word:]]\\(_*\\([[:upper:]][[:word:]_']*\\)?\\)" . (1 font-lock-variable-name-face))
  "ASP variable.")

(defconst clingo--variable2
  '("\\_<\\(_*[[:upper:]][[:word:]_']*\\)\\_>" . (1 font-lock-variable-name-face))
  "ASP variable 2.")

(defconst clingo--atom
  '("_*[[:lower:]][[:word:]_']*" . clingo-atom-face)
  "ASP atoms.")

(defvar clingo-highlighting nil
  "Regex list for syntax highlighting.")
(setq clingo-highlighting
      (list
       clingo--constructs
       clingo--constant
       clingo--variable2
       clingo--variable
       clingo--atom))

;;; Compilation

(defvar clingo-error-regexp
  "^[  ]+at \\(?:[^\(\n]+ \(\\)?\\(\\(?:[a-zA-Z]:\\)?[a-zA-Z\.0-9_/\\-]+\\):\\([0-9]+\\):\\([0-9]+\\)\)?"
  "Taken from NodeJS -> only dummy impl.")

(defvar clingo-error-regexp-alist
  `((,clingo-error-regexp 1 2 3))
  "Taken from NodeJs -> only dummy impl.")

(defun clingo-compilation-filter ()
  "Filter clingo output.  (Only dummy impl.)."
  (ansi-color-apply-on-region compilation-filter-start (point-max))
  (save-excursion
    (while (re-search-forward "^[\\[[0-9]+[a-z]" nil t)
      (replace-match ""))))

(define-compilation-mode clingo-compilation-mode "ASP"
  "Major mode for running ASP files."
  (set (make-local-variable 'compilation-error-regexp-alist) clingo-error-regexp-alist)
  (add-hook 'compilation-filter-hook #'clingo-compilation-filter nil t))

(defun clingo-generate-command (encoding options &optional instance)
  "Generate Clingo call with some ASP input file.

Argument ENCODING The current buffer which holds the problem encoding.
Argument OPTIONS Options (possibly empty string) sent to clingo.
Optional argument INSTANCE The problem instance which is solved by the encoding.
  If no instance it is assumed to be also in the encoding file."
  (if 'instance
      (concat clingo-path " " options " " encoding " " instance)
    (concat clingo-path " " options " " encoding)))

(defun clingo-run-clingo (encoding options &optional instance)
  "Run Clingo with some ASP input files.
Be aware: Partial ASP code may lead to abnormal exits
  while the result is sufficient.

Argument ENCODING The current buffer which holds the problem encoding.
Argument OPTIONS Options (possibly empty string) sent to clingo.
Optional argument INSTANCE The problem instance which is solved by the encoding.
  If no instance it is assumed to be also in the encoding file."
  (when (get-buffer "*clingo output*")
    (kill-buffer "*clingo output*"))
  (let ((test-command-to-run (clingo-generate-command encoding options instance))
        (compilation-buffer-name-function (lambda (_) "" "*clingo output*")))
    (compile test-command-to-run 'clingo-compilation-mode)))

(defun clingo-generate-echo (region options &optional instance)
  "Generate Clingo call with region echoed to it.

Argument REGION The selected region which holds the problem encoding.
Argument OPTIONS Options (possibly empty string) sent to clingo.
Optional argument INSTANCE The problem instance which is solved by the encoding.
  If no instance it is assumed to be also in the encoding file."
  (if 'instance
      (concat "echo \"" region "\" | " clingo-path " " options " " instance)
    (concat "echo \"" region "\" | " clingo-path " " options)))

;; (defun clingo-echo-clingo (region-begin region-end options &optional instance)
(defun clingo-echo-clingo (region options &optional instance)
  "Run Clingo on selected region (prompts for options).

Argument REGION The selected region as a string, which has the problem encoding.
Argument OPTIONS Options (possibly empty string) sent to clingo.
Optional argument INSTANCE The problem instance which is solved by the encoding.
  If no instance it is assumed to be also in the encoding file."
  (when (get-buffer "*clingo output*")
    (kill-buffer "*clingo output*"))
  (let ((test-command-to-run (clingo-generate-echo region options instance))
        (compilation-buffer-name-function (lambda (_) "" "*clingo output*")))
    (compile test-command-to-run 'clingo-compilation-mode)))

;; save the last user input
(defvar clingo-last-instance "")
(defvar clingo-last-options "")

;;;###autoload
(defun clingo-run-region (region-beginning region-end options)
  "Run Clingo on selected region (prompts for options).

Argument REGION-BEGINNING point marking beginning of region.
Argument REGION-END point marking end of region.
Argument OPTIONS Options (possibly empty string) sent to clingo."
  (interactive
   (let ((string
          (read-string (format "Options [%s]: " clingo-last-options) nil nil clingo-last-options)))
     (list (region-beginning) (region-end) string)))
  (setq-local clingo-last-options options)
  (clingo-echo-clingo
   (buffer-substring-no-properties region-beginning region-end)
   options))

;;;###autoload
(defun clingo-run-buffer (options)
  "Run clingo with the current buffer as input; prompts for OPTIONS."
  (interactive
   (list (read-string (format "Options [%s]: " clingo-last-options) nil nil clingo-last-options)))
  (setq-local clingo-last-options options)
  (clingo-run-clingo (buffer-file-name) options))

;;;###autoload
(defun clingo-run (options instance)
  "Run clingo with the current buffer and some user provided INSTANCE as input; prompts for OPTIONS."
  (interactive
   (list
    (read-string (format "Options [%s]: " clingo-last-options) nil nil clingo-last-options)
    (read-file-name
     (format "Instance [%s]:" (file-name-nondirectory clingo-last-instance))
     nil clingo-last-instance)))
  (setq-local clingo-last-options options)
  (setq-local clingo-last-instance instance)
  (clingo-run-clingo (buffer-file-name) options instance))

;;; Utility functions

(defun clingo--reload-mode ()
    "Reload the CLINGO major mode."
  (unload-feature 'clingo-mode)
  (require 'clingo-mode)
    (clingo-mode))

;;; File ending

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lp\\'" . clingo-mode))

;;; Define clingo mode

;;; Keymap

(defvar
  clingo-mode-map
  (let ((km (make-sparse-keymap)))
    (define-key km (kbd "C-c C-c") 'comment-region)
    (define-key km (kbd "C-c C-u") 'uncomment-region)
    (define-key km (kbd "C-c C-b") 'clingo-run-buffer)
    (define-key km (kbd "C-c C-r") 'clingo-run-region)
    (define-key km (kbd "C-c C-e") 'clingo-run)
    km))

;;;###autoload
(define-derived-mode clingo-mode prolog-mode "Potassco ASP"
  "A major mode for editing Answer Set Programs."
  (setq font-lock-defaults '(clingo-highlighting))

  ;; define the syntax for un/comment region and dwim
  (setq-local comment-start "%")
  (setq-local comment-end "")
  (setq-local tab-width clingo-indentation))

;; add mode to feature list
(provide 'clingo-mode)

;;; clingo-mode.el ends here
