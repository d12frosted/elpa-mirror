;;; chapel-mode.el --- A major mode for the Chapel programming language  -*- lexical-binding: t; -*-

;; Authors: Damon Kwok <damon-kwok@outlook.com>
;; Version: 0.0.1
;; Package-Version: 20210513.457
;; Package-Commit: 39fd24bb7cf44808200354ac0496be4fc4fddd9a
;; URL: https://github.com/damon-kwok/chapel-mode
;; Keywords: chapel chpl programming languages
;; Package-Requires: ((emacs "25.1") (hydra "0.15.0"))

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
;;
;; Description:
;;
;; This is a major mode for the Chapel programming language
;;
;; For more details, see the project page at
;; https://github.com/damon-kwok/chapel-mode
;;
;; Installation:
;;
;; The simple way is to use package.el:
;;
;;   M-x package-install chapel-mode
;;
;; Or, copy chapel-mode.el to some location in your Emacs load
;; path.  Then add "(require 'chapel-mode)" to your Emacs initialization
;; (.emacs, init.el, or something).
;;
;; Example config:
;;
;;   (require 'chapel-mode)

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'js)
(require 'xref)
(require 'hydra)
(require 'imenu)
(require 'easymenu)

(defgroup chapel nil
  "Support for Chapel code."
  :link '(url-link "https://chapel-lang.org/")
  :tag "Chapel"
  :group 'languages)

(defcustom chapel-indent-offset 2
  "Indent Chapel code by this number of spaces."
  :type 'integer
  :safe #'integerp
  :group 'chapel)

(defcustom chapel-format-on-save t
  "Format buffers before saving."
  :type 'boolean
  :safe #'booleanp
  :group 'chapel)

(defcustom chapel-use-ctags t
  "Build TAGS file after saving."
  :type 'boolean
  :safe #'booleanp
  :group 'chapel)

(defcustom chapel-chapel-bin "chpl"
  "Path to chpl executable."
  :type 'string
  :safe #'stringp
  :group 'chapel)

(defvar chapel-mode-hook nil)

(defvar chapel-mode-map
  (let ((map (make-keymap)))
    (substitute-key-definition #'c-electric-paren nil map)
    (substitute-key-definition #'c-electric-brace nil map)
    (define-key map (kbd "C-M-\\") #'chapel-format-buffer)
    (define-key map (kbd "C-c C-f") #'chapel-format-buffer) ;
    map)
  "Keymap for Chapel major mode.")

(defconst chapel-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; fontify " using chapel-keywords

    ;; Operators
    (dolist (i '(?+ ?- ?* ?/ ?% ?& ?| ?= ?! ?< ?>))
      (modify-syntax-entry i "." table))

    ;; / is punctuation, but // is a comment starter
    (modify-syntax-entry ?/ ". 124" table)

    ;; /* */ comments, which can be nested
    (modify-syntax-entry ?* ". 23bn" table)

    ;; \n is a comment ender
    (modify-syntax-entry ?\n ">" table)

    ;; string
    (modify-syntax-entry ?\` "\"" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)

    ;; Don't treat underscores as whitespace
    (modify-syntax-entry ?_ "w" table) table))

(defconst chapel-indent-keywords
  '("catch" "do" "else" "for" "if" "in" "iter" ;
     "lambda" "on" "otherwise" "proc" "select" ;
     "then" "try" "when" "while" "with"        ;
     "config" "prototype" "inline" "override"  ;
     "public" "private"                        ;
     "extern" "export" "local"                 ;
     "let" "var" "const" "param"               ;
     "throws" "ref" "type" "module")
  "Chapel keywords which indicate a new indentation level.")

(defconst chapel-keywords
  '("var" "let"                                                ;
     "in" "inout" "out" "const" "param" "ref" "type" "nothing" ;
     "for" "do"                                                ;
     "if" "then" "else"                                        ;
     "select" "when" "otherwise"                               ;
     "while"                                                   ;
     "proc" "iter" "lambda"                                    ;
     "forwarding" "impl" "except" "only"                       ;
     "with")
  "Chapel language keywords.")

(defconst chapel-declaration-keywords '("module" "record" "class")
  "Chapel declaration keywords.")

(defconst chapel-preprocessor-keywords
  '("config" "prototype" "inline" "override" ;
     "extern" "export" "local"               ;
     "public" "private" "pragma")
  "Chapel preprocessor keywords.")

(defconst chapel-careful-keywords
  '("use" "import" "require"                     ;
     "on"                                        ;
     "sync" "single" "atomic" "serial"           ;
     "lock" "unlock"                             ;
     "begin" "cobegin" "coforall" "forall"       ;
     "break" "continue" "label" "return" "yield" ;
     "new" "delete" "opaque"                     ;
     "owned" "shared" "unmanaged" "borrowed"     ;
     "lifetime" "where"                          ;
     "sparse"                                    ;
     ;; "in" "out" "inout" "ref"                         ;
     "syserr" "halt" "compilerError" "refTo" "borrow" ;
     "defer"                                          ;
     "try" "catch" "throws"                           ;
     "receiver"                                       ;
     "channel" "domain")
  "Chapel language careful keywords.")

(defconst chapel-builtin-keywords
  '("void" "noting"                                               ;
     "enum" "union"                                               ;
     "bool" "int" "uint" "real" "imag" "complex" "string" "range" ;
     "c_int" "c_uint" "c_long" "c_ulong" "c_longlong" "c_ulonglong" "c_char"
     "c_schar" "c_uchar" "c_short" "c_ushort"  ;
     "ssize_t" "size_t"                        ;
     "c_void_ptr" "c_ptr" "c_array" "c_string" ;
     "c_float" "c_double"                      ;
     "c_fn_ptr")
  "Chapel language keywords.")

(defconst chapel-constants
  '("this"                                        ;
     "false" "true"                               ;
     "full" "empty" "noinit"                      ;
     "nil" "none" "gasnet" "ofi" "ugni"           ;
     "indices" "locale" "numLocales" "id" "index" ;
     "numLocales" "LocaleSpace" "Locales"         ;
     "defaultValues")
  "Common constants.")

(defconst chapel-operator-functions
  '("zip" "by" "align"                  ;
     "min" "max" "maxloc" "minloc"      ;
     "reduce" "scan" "dmapped")
  "Chapel language operators functions.")

;; create the regex string for each class of keywords

(defconst chapel-keywords-regexp (regexp-opt chapel-keywords 'words)
  "Regular expression for matching keywords.")

(defconst chapel-declaration-keywords-regexp
  (regexp-opt chapel-declaration-keywords 'words)
  "Regular expression for matching declaration keywords.")

(defconst chapel-preprocessor-keywords-regexp
  (regexp-opt chapel-preprocessor-keywords 'words)
  "Regular expression for matching preprocessor keywords.")

(defconst chapel-careful-keywords-regexp
  (regexp-opt chapel-careful-keywords 'words)
  "Regular expression for matching careful keywords.")

(defconst chapel-builtin-keywords-regexp
  (regexp-opt chapel-builtin-keywords 'words)
  "Regular expression for matching builtin type.")

(defconst chapel-constant-regexp (regexp-opt chapel-constants 'words)
  "Regular expression for matching constants.")

(defconst chapel-operator-functions-regexp
  (regexp-opt chapel-operator-functions 'words)
  "Regular expression for matching operator functions.")

(defconst chapel-font-lock-keywords
  `(
     ;; builtin
     ("\\([A-Za-z$]+\\)\"" 1 'font-lock-builtin-face)
     (,chapel-builtin-keywords-regexp . font-lock-builtin-face)

     ;; careful
     (,chapel-careful-keywords-regexp . font-lock-warning-face)

     ;; declaration
     (,chapel-declaration-keywords-regexp . font-lock-keyword-face)

     ;; preprocessor
     (,chapel-preprocessor-keywords-regexp . font-lock-preprocessor-face)

     ;; keywords
     (,chapel-keywords-regexp . font-lock-keyword-face)

     ;; operator methods
     (,chapel-operator-functions-regexp . font-lock-builtin-face)

     ;; constants references
     (,chapel-constant-regexp . font-lock-constant-face)
     ("[,;( \t]\\([A-Z$]+\\)[ \t]*[,;)]" 1 'font-lock-constant-face)
     ;; ("[=,(][ \t]*\\([A-Z][A-Z_$]+\\)" 1 'font-lock-constant-face)
     ("[=][ \t]*\\([A-Z][A-Z_$]+\\)" 1 'font-lock-constant-face)

     ;; fields
     ("\\.\\([A-Za-z0-9_$]+\\)\\." 1 'font-lock-variable-name-face)
     ("[(][ \t,]*\\([a-zA-Z][A-Za-z0-9_$]*\\)" 1 'font-lock-variable-name-face)

     ;; type declaration
     ("\\(class\\|record\\|type\\|enum\\|union\\|struct|\\|module\\|use\\|require\\|import\\)[ \t]+\\([A-Za-z0-9_$]*\\)"
       2 'font-lock-type-face)
     ("new[ \t]+\\([A-Za-z0-9_]*\\)[ \t]*(" 1 'font-lock-type-face)
     ("\\([a-z][A-Za-z0-9_]*_t\\)[^A-Za-z0-9_]" 1 'font-lock-type-face)
     ("[,([][ \t]*\\([A-Z][A-Za-z0-9_]*\\)" 1 'font-lock-type-face)
     ("\\([A-Z][A-Za-z0-9_]*\\)[ \t]*[,)]]" 1 'font-lock-type-face)
     ("\\([A-Z][A-Za-z0-9_]*\\)\\?" 1 'font-lock-type-face)

     ;; method definitions
     ("\\(proc\\|iter\\)[ \t]+\\([A-Za-z0-9_$]+\\)" 2
       'font-lock-function-name-face)

     ;; variable/params definitions
     ("\\(var\\|const\\|let\\|param\\|type\\)[ \t]+\\([A-Za-z0-9_$]+\\)" 2
       'font-lock-variable-name-face)

     ;; enum definitions
     ("[^A-Za-z_]\\(e[A-Z][A-Za-z0-9_$]*\\)[ \t]*[,]*" 1
       'font-lock-constant-face)

     ;; method references
     ("\\([A-Za-z0-9_$]*\\)[ \t]*(" 1 'font-lock-function-name-face)

     ;; variable values
     ("\\(var\\|const\\|let\\)[ \t]+\\([A-Za-z0-9_]+\\)[ \t]*:[ \t]*\\([a-z_][A-Za-z0-9_$]+\\)"
       3 'font-lock-variable-name-face)

     ;; type references
     ("[ \t,]\\([A-Z][A-Za-z0-9_$]*\\)" 1 'font-lock-type-face)
     ("\\(var\\|const\\|let\\)[ \t]+\\([A-Za-z0-9_]+\\)[ \t]*:[ \t]*\\([A-Z_][A-Za-z0-9_$]+\\)"
       3 'font-lock-type-face)
     ("[^a-z_]\\([A-Z][A-Za-z0-9_$]*\\)\\." 1 'font-lock-type-face)
     (":[ \t]*\\([A-Za-z_][A-Za-z0-9_$]*\\)" 1 'font-lock-type-face)

     ;; numeric literals
     ;; ("[^A-Za-z_]+\\([0-9][A-Za-z0-9_]*\\)" 1 'font-lock-constant-face)
     ("[-+*/=><([{.,;&|%!@#$%^&* \t]+\\([0-9][A-Za-z0-9_-]*\\)" 1
       'font-lock-constant-face)

     ;; variable references
     ;; ("[^0-9A-Z]\\([a-z_][A-Za-z_0-9$]*\\)" 1 'font-lock-variable-name-face)
     ("\\([a-z_][A-Za-z_0-9$]*\\)" 1 'font-lock-variable-name-face)

     ;; delimiter: modifier
     ("\\(!=\\|\\.\\.\\.\\|\\.\\.\\)" 1 'font-lock-warning-face)
     ("\\(->\\|=>\\|\\.>\\|:>\\|:=\\||\\)" 1 'font-lock-keyword-face)

     ;; delimiter: . , ; separate
     ("\\($?[.,;]+\\)" 1 'font-lock-comment-delimiter-face)

     ;; delimiter: operator symbols
     ("\\($?[%~=<>#^&*/+-]+\\)$?,?" 1 'font-lock-negation-char-face)
     ("\\($?[?!]+\\)" 1 'font-lock-warning-face)

     ;; delimiter: = : separate
     ("[^+-/*//%~^!=<>]\\([=:]\\)[^+-/*//%~^!=<>]" 1
       'font-lock-comment-delimiter-face)

     ;; delimiter: brackets
     ("\\(\\[\\|\\]\\|[(){}]\\)" 1 'font-lock-comment-delimiter-face)

     ;; method references
     ("\\([a-z_][A-Za-z0-9_$]+\\)[ \t]*(" 1 'font-lock-function-name-face)

     ;; character literals
     ("\\('[\\].'\\)" 1 'font-lock-constant-face)

     ;; type references
     ("\\([A-Z][A-Za-z0-9_$]*\\)" 1 'font-lock-type-face))
  "An alist mapping regexes to font-lock faces.")

(defun chapel-project-root-p (path)
  "Return t if directory `PATH' is the root of the Chapel project."
  (let* ((files '("Mason.toml" "make.bat" "Makefile"              ;
                   "Dockerfile" ".editorconfig" ".gitignore" ;
                   ".git" ".svn" ".hg" ".bzr"))
          (foundp nil))
    (while (and (> (length files) 0)
             (not foundp))
      (let* ((filename (car files))
              (filepath (concat (file-name-as-directory path) filename)))
        (setq files (cdr files))
        (setq foundp (file-exists-p filepath)))) ;
    foundp))

(defun chapel-project-root
  (&optional
    path)
  "Return the root of the Chapel project.
Optional argument PATH ."
  (let* ((bufdir (if buffer-file-name   ;
                   (file-name-directory buffer-file-name) default-directory))
          (curdir (if path (file-name-as-directory path) bufdir))
          (parent (file-name-directory (directory-file-name curdir))))
    (if (or (not parent)
          (string= parent curdir)
          (string= parent (file-name-as-directory (getenv "HOME")))
          (string= parent "/")
          (chapel-project-root-p curdir)) ;
      curdir                              ;
      (chapel-project-root parent))))

(defun chapel-project-name ()
  "Return Chapel project name."
  (file-name-base (directory-file-name (chapel-project-root))))

(defun chapel-project-file-exists-p (filename)
  "Return t if file `FILENAME' exists."
  (file-exists-p (concat (chapel-project-root) filename)))

(defun chapel-run-command (command &optional path)
  "Return `COMMAND' in the root of the Chapel project.
Optional argument PATH ."
  (let ((oldir default-directory))
    (setq default-directory (if path path (chapel-project-root path)))
    (compile command)
    (setq default-directory oldir)))

(defun chapel-project-build ()
  "Build project with mason."
  (interactive)
  (if (chapel-project-file-exists-p "Makefile")
    (chapel-run-command "make")
    (chapel-run-command "mason build")))

(defun chapel-project-init ()
  "Run corral `init' command."
  (interactive)
  (unless (chapel-project-file-exists-p "Mason.toml")
    (chapel-run-command "mason init -d")))

(defun chapel-project-update ()
  "Run corral `update' command."
  (interactive)
  (if (chapel-project-file-exists-p "Mason.toml")
    (chapel-run-command "mason update")))

(defun chapel-project-open ()
  "Open `Mason.toml' file."
  (interactive)
  (if (chapel-project-file-exists-p "Mason.toml")
    (find-file (concat (chapel-project-root) "Mason.toml"))))

(defun chapel-buffer-dirname ()
  "Return current buffer directory file name."
  (directory-file-name (if buffer-file-name (file-name-directory
                                              buffer-file-name)
                         default-directory)))

(defun chapel-project-run ()
  "Run project."
  (interactive)
  (let* ((bin1 (concat (chapel-project-root) "bin/" (chapel-project-name)))
          (bin2 (concat (chapel-project-root) "/" (chapel-project-name)))
          (bin3 (concat (chapel-buffer-dirname) "/" (chapel-project-name))))
    (cond ((file-exists-p bin1)
            (chapel-run-command bin1))
      ((file-exists-p bin2)
        (chapel-run-command bin2))
      ((file-exists-p bin2)
        (chapel-run-command bin3))
      (t (chapel-run-command "mason run --build --release --force")))))

(easy-menu-define chapel-mode-menu chapel-mode-map ;
  "Menu for Chapel mode."                          ;
  '("Chapel"                                       ;
     ["Build" chapel-project-build t]              ;
     ["Run" chapel-project-run t]                  ;
     ["Init" chapel-project-init t]                ;
     ["Open" chapel-project-open t]                ;
     ["Update" chapel-project-update t]            ;
     ["Format Buffer" chapel-format-buffer t]      ;
     "---"                                         ;
     ("Community"                                  ;
       ["News"                                     ;
         (chapel-run-command "xdg-open https://twitter.com/ChapelLanguage") t]
       ["Quick Reference"               ;
         (chapel-run-command
           "xdg-open https://chapel-lang.org/docs/_downloads/2f38b00b0efce17118144ea97f52adc9/quickReference.pdf") t]
       ["Open an issue"                 ;
         (chapel-run-command
           "xdg-open https://github.com/chapel-lang/chapel/issues") t]
       ["Tutorial"                      ;
         (chapel-run-command "xdg-open https://chapel-lang.org/docs/") t])))

(defun chapel-banner-default ()
  "Chapel banner."
  "
      _                      _
     | |                    | |
  ___| |__   __ _ _ __   ___| |
 / __| '_ \\ / _` | '_ \\ / _ \\ |
| (__| | | | (_| | |_) |  __/ |
 \\___|_| |_|\\__,_| .__/ \\___|_|
                 | |
                 |_|
")

(defhydra chapel-hydra-menu
  (:color blue
    :hint none)
  "
%s(chapel-banner-default)
  Project     |  _i_: Init      _u_: Update     _o_: chpl.json
              |  _b_: Build     _r_: Run
  Community   |  _1_: News      _2_: QuickReference
              |  _3_: OpenIssue _4_: Tutorial
  _q_: Quit"                            ;
  ("b" chapel-project-build "Build")
  ("r" chapel-project-run "Run")
  ("o" chapel-project-open "Open Mason.toml")
  ("i" chapel-project-init "chpl init")
  ("u" chapel-project-update "chpl update")
  ("1" (chapel-run-command "xdg-open https://twitter.com/ChapelLanguage")
    "News")
  ("2" (chapel-run-command
         "xdg-open https://chapel-lang.org/docs/_downloads/2f38b00b0efce17118144ea97f52adc9/quickReference.pdf") "QuickReference")
  ("3" (chapel-run-command
         "xdg-open https://github.com/chapel-lang/chapel/issues")
    "Open an issue")
  ("4" (chapel-run-command "xdg-open https://chapel-lang.org/docs/") "Docs")
  ("q" nil "Quit"))

(defun chapel-menu ()
  "Open chapel hydra menu."
  (interactive)
  (chapel-hydra-menu/body))

(defun chapel-build-tags ()
  "Build tags for current project."
  (interactive)
  (let ((tags-buffer (get-buffer "TAGS"))
         (tags-buffer2 (get-buffer (format "TAGS<%s>" (chapel-project-name)))))
    (if tags-buffer (kill-buffer tags-buffer))
    (if tags-buffer2 (kill-buffer tags-buffer2)))
  (let* ((chapel-path                   ;
           (string-trim (shell-command-to-string (concat "which "
                                                   chapel-chapel-bin))))
          (chapel-executable            ;
            (string-trim (shell-command-to-string (concat "readlink -f "
                                                    chapel-path))))
          (packages-path                ;
            (concat (file-name-directory chapel-executable) "../../modules"))
          (ctags-params                 ;
            (concat
              "ctags --languages=-chapel --langdef=chapel --langmap=chapel:.chpl "
              "--regex-chapel='/[ \\t]*proc[ \\t]+([A-Za-z0-9_]+)/\\1/p,proc/' "
              "--regex-chapel='/[ \\t]*iter[ \\t]+([A-Za-z0-9_]+)/\\1/i,iter/' "
              "--regex-chapel='/^[ \\t]*struct[ \\t]+([A-Za-z0-9_]+)/\\1/s,struct/' "
              "--regex-chapel='/^[ \\t]*record[ \\t]+([A-Za-z0-9_]+)/\\1/r,record/' "
              "--regex-chapel='/^[ \\t]*class[ \\t]+([A-Za-z0-9_]+)/\\1/c,class/' "
              "--regex-chapel='/^[ \\t]*type[ \\t]+([A-Za-z0-9_]+)/\\1/t,type/' "
              "--regex-chapel='/^[ \\t]*enum[ \\t]+([A-Za-z0-9_]+)/\\1/e,enum/' "
              "--regex-chapel='/^[ \\t]*module[ \\t]+([A-Za-z0-9_]+)/\\1/m,module/' " ;
              "-e -R . " packages-path)))
    (when (file-exists-p packages-path)
      (let ((oldir default-directory))
        (setq default-directory (chapel-project-root))
        (message "ctags:%s" (shell-command-to-string ctags-params))
        (chapel-load-tags)
        (setq default-directory oldir)))))

(defun chapel-load-tags
  (&optional
    build)
  "Visit tags table.
Optional argument BUILD ."
  (interactive)
  (let* ((tags-file (concat (chapel-project-root) "TAGS")))
    (if (file-exists-p tags-file)
      (progn (visit-tags-table (concat (chapel-project-root) "TAGS")))
      (if build (chapel-build-tags)))))

(defun chapel-format-buffer ()
  "Format the current buffer."
  (interactive)
  (when (eq major-mode 'chapel-mode)
    (js-mode)
    (setq-local indent-tabs-mode nil)
    (setq-local tab-width chapel-indent-offset)
    ;;
    (setq-local js-indent-level chapel-indent-offset)
    (setq-local js--possibly-braceless-keyword-re ;;
      (js--regexp-opt-symbol chapel-indent-keywords))
    (indent-region (point-min)
      (point-max))
    (chapel-mode)))

(defun chapel-before-save-hook ()
  "Before save hook."
  (when (eq major-mode 'chapel-mode)
    (if chapel-format-on-save (chapel-format-buffer))))

(defun chapel-after-save-hook ()
  "After save hook."
  (when (eq major-mode 'chapel-mode)
    (if (not (executable-find "ctags"))
      (message "Could not locate executable '%s'" "ctags")
      (if chapel-use-ctags (chapel-build-tags)))))

;;;###autoload
(define-derived-mode chapel-mode prog-mode
  "Chapel"
  "Major mode for editing Chapel files."
  :syntax-table chapel-mode-syntax-table
  ;;
  (setq-local require-final-newline mode-require-final-newline)
  (setq-local parse-sexp-ignore-comments t)
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq-local comment-start-skip "\\(//+\\|/\\*+\\)\\s *")
  ;;
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width chapel-indent-offset)
  (setq-local buffer-file-coding-system 'utf-8-unix)
  ;;
  (setq-local electric-indent-chars (append "{}():;," electric-indent-chars))
  (setq-local js-curly-indent-offset 0)
  (setq-local js-square-indent-offset 2)
  (setq-local js-indent-level tab-width)
  (setq-local js--possibly-braceless-keyword-re ;;
    (js--regexp-opt-symbol chapel-indent-keywords))
  (setq-local indent-line-function #'js-indent-line)
  ;;
  (setq-local font-lock-defaults '(chapel-font-lock-keywords))
  (font-lock-flush)
  ;;
  (setq-local imenu-generic-expression ;;
    '(("TODO" ".*TODO:[ \t]*\\(.*\\)$" 1)
       ("proc" "[ \t]*proc[ \t]+\\([A-Za-z0-9_]+\\)" 1)
       ("iter" "[ \t]*iter[ \t]+\\([A-Za-z0-9_]+\\)" 1)
       ("class" "^[ \t]*class[ \t]+\\([A-Za-z0-9_]+\\)" 1)
       ("record" "^[ \t]*interface[ \t]+\\([A-Za-z0-9_]+\\)" 1)
       ("type" "^[ \t]*type[ \t]+\\([A-Za-z0-9_]+\\)$" 1)
       ("enum" "^[ \t]*enum[ \t]+\\([A-Za-z0-9_]+\\)" 1)
       ("import" "^[ \t]*import[ \t]+\\([A-Za-z0-9_]+\\)" 1)
       ("require" "^[ \t]*require[ \t]+\\([A-Za-z0-9_]+\\)" 1)
       ("use" "^[ \t]*use[ \t]+\\([A-Za-z0-9_]+\\)" 1)
       ("module" "^[ \t]*module[ \t]+\\([A-Za-z0-9_]+\\)" 1)))
  (imenu-add-to-menubar "Index")
  ;;
  (add-hook 'before-save-hook #'chapel-before-save-hook nil t)
  (add-hook 'after-save-hook #'chapel-after-save-hook nil t)
  (chapel-load-tags))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.chpl\\'" . chapel-mode))

;;
(provide 'chapel-mode)

;;; chapel-mode.el ends here
