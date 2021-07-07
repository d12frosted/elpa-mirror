;;; ceylon-mode.el --- Major mode for editing Ceylon source code

;; Copyright (C) 2015-2017 Lucas Werkmeister

;; Author: Lucas Werkmeister <mail@lucaswerkmeister.de>
;; URL: https://github.com/lucaswerkmeister/ceylon-mode
;; Package-Version: 20180606.1324
;; Package-Commit: 948515672bc596dc118e8e3ede3ede5ec6a3c95a
;; Keywords: languages ceylon
;; Version: 0.2
;; Package-Requires: ((emacs "25"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Features:
;; * syntax highlighting
;; * indentation
;; * compilation
;; * execution
;; * code formatting

;;; Code:

(defgroup ceylon nil
  "Major mode for editing Ceylon source code."

  :group 'languages
  :version "0.2"
  :prefix "ceylon-"
  :link '(url-link :tag "GitHub"
                   "https://github.com/lucaswerkmeister/ceylon-mode"))

(defconst ceylon-font-lock-string
  (list
   ;; highlighting strings with regexes, because Emacs' proper model (syntax table) isn't flexible enough to suppport string templates or verbatim strings
   '("\\(\"\"\"\\(?:[^\"]\\|\"[^\"]\\|\"\"[^\"]\\)*\"\"\"\\)" . font-lock-string-face) ; verbatim string literal
   '("\\(\\(?:\"\\|``\\)\\(?:`\\(?:[^`\"\\]\\|\\\\.\\)\\|[^`\"\\]\\|\\\\.\\)*\\(?:\"\\|``\\)\\)" . font-lock-string-face) ; string literal or string part
   '("\\('\\(?:[^'\\]\\|\\\\.\\)*'\\)" . font-lock-string-face)) ; character literal
  "Syntax highlighting for Ceylon strings.")
;; optimized regular expressions
;; kill old value, copy regexp-opt expression (C-Space, select, M-w), move point to location of old value, C-u M-: C-y
;;(regexp-opt '("assembly" "module" "package" "import"
;;              "alias" "class" "interface" "object" "given" "value" "assign" "void" "function" "new"
;;              "of" "extends" "satisfies" "abstracts"
;;              "in" "out"
;;              "return" "break" "continue" "throw"
;;              "assert" "dynamic"
;;              "if" "else" "switch" "case" "for" "while" "try" "catch" "finally" "then" "let"
;;              "this" "outer" "super"
;;              "is" "exists" "nonempty"
;;              ) 'words)
(defconst ceylon-font-lock-keywords
  (list
   '("\\<\\(a\\(?:bstracts\\|lias\\|ss\\(?:e\\(?:mbly\\|rt\\)\\|ign\\)\\)\\|break\\|c\\(?:a\\(?:se\\|tch\\)\\|lass\\|ontinue\\)\\|dynamic\\|e\\(?:lse\\|x\\(?:\\(?:ist\\|tend\\)s\\)\\)\\|f\\(?:inally\\|or\\|unction\\)\\|given\\|i\\(?:mport\\|nterface\\|[fns]\\)\\|let\\|module\\|n\\(?:ew\\|onempty\\)\\|o\\(?:bject\\|f\\|ut\\(?:er\\)?\\)\\|package\\|return\\|s\\(?:atisfies\\|uper\\|witch\\)\\|t\\(?:h\\(?:en\\|is\\|row\\)\\|ry\\)\\|v\\(?:alue\\|oid\\)\\|while\\)\\>" . font-lock-keyword-face))
  "Syntax highlighting for Ceylon keywords.")
;; (regexp-opt '("shared" "abstract" "formal" "default" "actual" "variable" "late" "native" "deprecated" "final" "sealed" "annotation" "suppressWarnings" "small" "static") 'words)
(defconst ceylon-font-lock-language-annos
  (list
   '("\\<\\(a\\(?:bstract\\|ctual\\|nnotation\\)\\|de\\(?:fault\\|precated\\)\\|f\\(?:\\(?:in\\|orm\\)al\\)\\|late\\|native\\|s\\(?:ealed\\|hared\\|mall\\|tatic\\|uppressWarnings\\)\\|variable\\)\\>" . font-lock-builtin-face))
  "Syntax highlighting for Ceylon language annotations.")
;; (regexp-opt '("doc" "by" "license" "see" "throws" "tagged") 'words)
(defconst ceylon-font-lock-doc-annos
  (list
   '("\\<\\(by\\|doc\\|license\\|see\\|t\\(?:agged\\|hrows\\)\\)\\>" . font-lock-builtin-face))
  "Syntax highlighting for Ceylon doc annotations.")
(defconst ceylon-font-lock-lidentifier
  (list
   '("\\<\\([[:lower:]_][[:alnum:]_]*\\)\\>" . font-lock-variable-name-face)
   '("\\<\\(\\\\i[[:alnum:]_]*\\)\\>" . font-lock-variable-name-face))
  "Syntax highlighting for Ceylon lowercase identifiers.")
(defconst ceylon-font-lock-uidentifier
  (list
   '("\\<\\([[:upper:]][[:alnum:]_]*\\)\\>" . font-lock-type-face)
   '("\\<\\(\\\\I[[:alnum:]_]*\\)\\>" . font-lock-type-face))
  "Syntax highlighting for Ceylon uppercase identifiers.")
(defconst ceylon-font-lock-all
  (append ceylon-font-lock-string ceylon-font-lock-keywords ceylon-font-lock-language-annos ceylon-font-lock-doc-annos ceylon-font-lock-lidentifier ceylon-font-lock-uidentifier)
  "Syntax highlighting for all Ceylon elements.")
(defvar ceylon-font-lock ceylon-font-lock-all ; e. g. set to ceylon-font-lock-keywords to only highlight keywords
  "Syntax highlighting for Ceylon; customizable (highlights all by default).")

(defvar ceylon-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; Comments. See (elisp) Syntax Flags.
    ;; Note: due to limitations of the flag system, /! and #/ are also recognized as line comments.
    (modify-syntax-entry ?/ ". 124" st)
    (modify-syntax-entry ?* ". 23n" st)
    (modify-syntax-entry ?\n ">" st)
    (modify-syntax-entry ?# ". 1" st)
    (modify-syntax-entry ?! ". 2" st)
    ;; Disable string highlighting so that the regexes in ceylon-font-lock-string can match
    (modify-syntax-entry ?\" "." st)
    st)
  "Syntax table for `ceylon-mode'.")

(set-default 'tab-width 4)

(set-default 'comment-start "// ")

(defcustom ceylon-restore-point-on-indent t
  "Whether to restore point after an indentation.

If this variable is non-nil, restore point to its original position,
adjusted for changed indentation, after an indentation operation
completes. This matches the default behavior of most Emacs programming
modes.

If this variable is nil, leave point at the end of indentation."
  :type '(choice (const :tag "restore original point" t)
                 (const :tag "leave point at end of indentation" nil)))

(defun ceylon-indent-line ()
  "Indent current line as Ceylon code."
  (let* ((cur-column (and ceylon-restore-point-on-indent
                          (current-column))))
    (beginning-of-line)

    (if (bobp) ; beginning of buffer?
        (indent-line-to 0)
      (let (cur-indent
            (old-indent (current-indentation)))
        (save-excursion
          (forward-line -1)
          (while (and (looking-at "^[ \t]*$") (not (bobp))) ; skip over blank lines
            (forward-line -1))
          (setq cur-indent (current-indentation))
          (let* ((start (line-beginning-position))
                 (end   (line-end-position))
                 (open-parens    (how-many "(" start end))
                 (close-parens   (how-many ")" start end))
                 (open-braces    (how-many "{" start end))
                 (close-braces   (how-many "}" start end))
                 (open-brackets  (how-many "\\[" start end))
                 (close-brackets (how-many "\\]" start end))
                 (balance (- (+ open-parens open-braces open-brackets)
                             (+ close-parens close-braces close-brackets))))
            (if (looking-at"[ \t]*\\(}\\|)\\|]\\)")
                (setq balance (+ balance 1)))
            (setq cur-indent (+ cur-indent (* balance tab-width)))))
        (if (looking-at "[ \t]*\\(}\\|)\\|]\\)")
            (setq cur-indent (- cur-indent tab-width)))
        (when (>= cur-indent 0)
          (indent-line-to cur-indent)

          (when (and cur-column (> cur-column old-indent))
            (move-to-column (+ cur-column (- cur-indent old-indent)))))))))
;; uncomment this to automatically reindent when a close-brace is typed;
;; however, this also sets the cursor *before* that brace, which is inconvenient,
;; so it's disabled for now.
;;(setq electric-indent-chars
;;  (append electric-indent-chars
;;          '(?})))

(defun ceylon-format-region ()
  "Format the current region with `ceylon format'.

The region must contain code that looks like a compilation unit
so that `ceylon.formatter' can parse it, usually one or more
complete declarations."
  (interactive)
  (let* (;; remember region before we start moving point
         (region-beginning (region-beginning))
         (region-end (region-end))
         ;; remember whether point was at beginning or end of region before formatting
         (point-at-end (eq (point) region-end))
         ;; remember whether region had trailing newline before formatting
         (newline-at-end (progn (goto-char region-end)
                                (eq (point) (line-beginning-position))))
         ;; remember initial indentation of the code (`ceylon format --pipe` always uses initial indentation 0)
         (initial-indentation (progn (goto-char region-beginning)
                                     (current-indentation)))
         ;; remember column of the first line (its initial indentation might be partially within and partially outside of region)
         (first-line-column (current-column))
         ;; declare local variable for use below
         lines)
    ;; pipe region through ceylon.formatter
    (let ((default-directory (or (ceylon-project-directory) ".")))
      (shell-command-on-region region-beginning region-end "ceylon format --pipe" t t (get-buffer-create "*ceylon-format-errors*") t))
    ;; remember updated region
    (setq region-beginning (region-beginning)
          region-end (region-end)
          lines (count-lines region-beginning region-end))
    ;; `ceylon format --pipe` always uses initial indentation 0, indent all lines to remembered initial indentation
    (if (> initial-indentation 0)
        (dotimes (n lines)
          (beginning-of-line)
          (let ((adjustment (if (eq n 0)
                                (- initial-indentation first-line-column) ; part of first line's indentation is outside region and wasn't removed
                              initial-indentation)))
            (indent-to-column adjustment)
            (setq region-end (+ region-end adjustment)))
          (forward-line 1)))
    ;; ceylon.formatter always adds trailing newline, remove if not present before
    (when (not newline-at-end)
      (delete-region (- region-end 1) region-end)
      (setq region-end (- region-end 1)))
    ;; move to region beginning or end, depending on which one was point before formatting
    (goto-char (if point-at-end region-end region-beginning))))

(defun ceylon-format-buffer ()
  "Format the current buffer with `ceylon format'."
  (interactive)
  ;; save point
  (let ((point (point)))
    ;; pipe buffer through ceylon.formatter
    (let ((default-directory (or (ceylon-project-directory) ".")))
      (shell-command-on-region (point-min) (point-max) "ceylon format --pipe" t t (get-buffer-create "*ceylon-format-errors*") t))
    ;; restore point (it won't be in the same logical code position, but it's better than nothing)
    (goto-char point)))

(defun ceylon-format-region-or-buffer ()
  "Format the current region or buffer with `ceylon format'.

Runs `ceylon-format-region' if there is a region
and `ceylon-format-buffer' otherwise."
  (interactive)
  (if (use-region-p)
      (ceylon-format-region)
    (ceylon-format-buffer)))

(defun ceylon-module-descriptor-regexp (regexp &optional path)
  "Run REGEXP on the ‘module.ceylon’ file and return the first match group.

Optional argument PATH describes the location to start the search
for ‘module.ceylon’ at and defaults to the current directory."
  (let ((module-directory (locate-dominating-file (or path ".") "module.ceylon")))
    (when module-directory
      (with-temp-buffer
        (insert-file-contents (concat module-directory "module.ceylon"))
        (when (re-search-forward regexp nil t)
          (match-string 1))))))

(defun ceylon-module-name (&optional path)
  "Determine the Ceylon module name.

Optional argument PATH describes the location to start the search
for ‘module.ceylon’ at and defaults to the current directory."
  (ceylon-module-descriptor-regexp "\\_<module\\_>\\s-*\\(\\(?:\\w\\|\\s_\\)+\\(?:\\.\\(?:\\w\\|\\s_\\)+\\)*\\)" (or path ".")))

(defun ceylon-source-directory (&optional path)
  "Locate the Ceylon source code directory.

Optional argument PATH describes the location to start the search
at and defaults to the current directory."
  (unless path (setq path "."))
  (let ((module-directory (locate-dominating-file path "module.ceylon"))
        (module-name (ceylon-module-name path))
        ;; declare local variables for use below
        module-name-parts source-directory)
    (when (and module-directory module-name)
      (setq module-name-parts (reverse (split-string module-name "\\.")))
      (setq source-directory module-directory)
      (while (and module-name-parts (string-equal
                                     (car module-name-parts)
                                     (file-name-nondirectory (directory-file-name source-directory))))
        (setq module-name-parts (cdr module-name-parts))
        (setq source-directory (file-name-directory (directory-file-name source-directory))))
      ;; if loop didn’t terminate prematurely, directory structure was sound and we can return the result
      (when (not module-name-parts) source-directory))))

(defun ceylon-project-directory (&optional path)
  "Locate the Ceylon main project directory.

Optional argument PATH describes the location to start the search
at and defaults to the current directory."
  ;; locate .ceylon/config file
  (unless path (setq path "."))
  (let* ((ceylon-config-path (concat (file-name-as-directory ".ceylon") "config"))
         (project-directory (locate-dominating-file path ceylon-config-path)))
    (if project-directory
        ;; if it exists, it defines the project directory
        project-directory
      ;; otherwise, assume that source directory is one level below project directory
      (let ((source-directory (ceylon-source-directory path)))
        (when source-directory
          (file-name-directory (directory-file-name source-directory)))))))

(defun ceylon-backends (&optional path)
  "Detect the Ceylon backend(s) of the current module.
Returns a list of backend strings, or nil if the backends could not be determined
(due to error, or because the module is available for all Ceylon backends).

Optional argument PATH describes the location to start the search
for ‘module.ceylon’ at and defaults to the current directory."
  ;; heuristic: native annotation on unindented line
  (let ((native-annotation (ceylon-module-descriptor-regexp "^\\(?:native\\|[a-z].*\\_<native\\)\\s-*(\\s-*\"\\([^)]*\\)\")" (or path "."))))
    (when native-annotation
      (split-string native-annotation "\"[^\"]*\""))))

(defun ceylon-backend-to-command-suffix (backend)
  "Map ‘native’ BACKEND to suffix for ceylon subcommands.
This is only necessary because the the JVM backend’s commands are
called ‘compile’, ‘run’ etc. instead of the more regular
‘compile-jvm’, ‘run-jvm’."
  (if (equal backend "jvm")
      ""
    (concat "-" backend)))

(defcustom ceylon-default-backend "jvm"
  "The default Ceylon backend used if a module has no ‘native’ annotation."
  :type '(choice (const :tag "JVM" "jvm")
                 (const :tag "JavaScript" "js")
                 (const :tag "Dart" "dart")))

(defun ceylon-compile (&optional path)
  "Compile the current Ceylon module.
Compiler output goes to the buffer ‘*compilation*’.
Uses the first backend that the module is meant for (see
‘ceylon-backends’), falling back to ‘ceylon-default-backend’ if no
‘native’ annotations can be found.

Optional argument PATH describes the location to start the search
for the module descriptor and project directories at and defaults
to the current directory."
  (interactive)
  (unless path (setq path "."))
  (let* ((backends (ceylon-backends path))
         (backend (car (append backends (list ceylon-default-backend))))
         (module-name (or (ceylon-module-name path) "default"))
         (default-directory (or (ceylon-project-directory path) "."))
         (source-directory (or (ceylon-source-directory path) "."))
         (compilation-buffer (get-buffer-create "*compilation*")))
    (make-process
     :name "Ceylon compilation"
     :command (list "ceylon" (concat "compile" (ceylon-backend-to-command-suffix backend)) "--source" source-directory module-name)
     :buffer compilation-buffer
     :noquery t)
    (with-current-buffer compilation-buffer
      (compilation-mode))
    (display-buffer compilation-buffer)))

(defun ceylon-run (&optional path)
  "Run the current Ceylon module (compiling it if needed).
Program output goes to the buffer ‘*Ceylon program output*’.
Uses the first backend that the module is meant for (see
‘ceylon-backends’), falling back to ‘ceylon-default-backend’ if no
‘native’ annotations can be found.

Optional argument PATH describes the location to start the search
for the module descriptor and project directories at and defaults
to the current directory."
  (interactive)
  (unless path (setq path "."))
  (let* ((backends (ceylon-backends path))
         (backend (car (append backends (list ceylon-default-backend))))
         (module-name (or (ceylon-module-name path) "default"))
         (default-directory (or (ceylon-project-directory path) "."))
         (source-directory (or (ceylon-source-directory path) "."))
         (run-buffer (get-buffer-create "*Ceylon program output*")))
    (if (and (equal module-name "default") (equal source-directory "."))
        ;; --compile-check doesn’t work in this setup, let’s compile
        ;; unconditionally and quietly because it’s probably cheap
        (call-process "ceylon" nil "*compilation*" nil (concat "compile" (ceylon-backend-to-command-suffix backend)) "--source" source-directory module-name))
    (make-process
     :name "Ceylon run"
     :command (list "ceylon" (concat "run" (ceylon-backend-to-command-suffix backend)) "--compile=check" module-name)
     :buffer run-buffer
     :noquery t)
    (display-buffer run-buffer)))

;;;###autoload (add-to-list 'auto-mode-alist '("\\.ceylon\\'" . ceylon-mode))

;;;###autoload
(define-derived-mode ceylon-mode prog-mode "Ceylon"
  "Major mode for editing Ceylon code.

\\{ceylon-mode-map}"
  (set (make-local-variable 'font-lock-defaults) '(ceylon-font-lock))
  (set (make-local-variable 'indent-line-function) 'ceylon-indent-line))


(define-key ceylon-mode-map "\C-c\C-f" 'ceylon-format-region-or-buffer)
(define-key ceylon-mode-map "\C-c\C-c" 'ceylon-compile)
(define-key ceylon-mode-map "\C-c\C-r" 'ceylon-run)


(provide 'ceylon-mode)

;;; ceylon-mode.el ends here
