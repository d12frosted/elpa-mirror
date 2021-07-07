;;; zetz-mode.el --- A major mode for the ZetZ programming language  -*- lexical-binding: t; -*-

;; Copyright (c) 2020 Damon Kwok

;; Authors: Damon Kwok <damon-kwok@outlook.com>
;; Version: 0.0.1
;; Package-Version: 20200823.536
;; Package-Commit: 04da33f4ffa9db5b3556f423276f4fd1db13ec67
;; URL: https://github.com/damon-kwok/zetz-mode
;; Keywords: languages programming
;; Package-Requires: ((emacs "25.1") (dash "2.17.0") (hydra "0.15.0"))

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

;; Description:
;;
;; This is a major mode for the ZetZ programming language
;;
;; For more details, see the project page at
;; https://github.com/damon-kwok/zetz-mode
;;
;; Installation:
;;
;; The simple way is to use package.el:
;;
;;   M-x package-install zetz-mode
;;
;; Or, copy zetz-mode.el to some location in your Emacs load
;; path.  Then add "(require 'zetz-mode)" to your Emacs initialization
;; (.emacs, init.el, or something).
;;
;; Example config:
;;
;;   (require 'zetz-mode)

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'js)
(require 'dash)
(require 'xref)
(require 'hydra)
(require 'imenu)
(require 'easymenu)

(defvar zetz-mode-hook nil)

(defconst zetz-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; fontify " using zetz-keywords

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
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)

    ;; Don't treat underscores as whitespace
    (modify-syntax-entry ?_ "w" table) table))

(defvar zetz-mode-map
  (let ((map (make-keymap)))
    (define-key map "\C-j" 'newline-and-indent) map)
  "Keymap for ZetZ major mode.")

(defconst zetz-keywords
  '("if" "else" "switch" "case" "while" "for" "do" ;
     "default" "sizeof")
  "ZetZ language keywords.")

(defconst zetz-preprocessor-keywords
  '("using"                             ;
     "export" "pub"                     ;
     "inline" "packed")
  "ZetZ declaration keywords.")

(defconst zetz-declaration-keywords
  '("let"                               ;
     "enum" "struct" "theory"           ;
     "symbol"                           ;
     "fn" "macro" "closure")
  "ZetZ declaration keywords.")

(defconst zetz-careful-keywords
  '("new"                                       ;
     "goto" "continue" "break" "return"         ;
     "mut" "mutable" "unsafe"                   ;
     "is" "as" "needs"                          ;
     "test"                                     ;
     "assert" "assert2" "assert3" "assert4"     ;
     "static_attest" "static_assert" "nullterm" ;
     "where" "model"                            ;
     "const" "static" "atomic" "thread_local")
  "ZetZ language careful keywords.")

(defconst zetz-builtin-keywords
  '("u8" "i8" "u16" "i16" "u32" "i32" "u64" "i64"    ;
     "isize" "usize" "int" "uint" "f32" "f64" "bool" ;
     "void" "char" "byte")
  "ZetZ language keywords.")

(defconst zetz-constants '("false" "true" "self")
  "Common constants.")

(defconst zetz-operator-functions '("len" "sizeof" "safe" )
  "ZetZ language operators functions.")

;;; create the regex string for each class of keywords

(defconst zetz-keywords-regexp (regexp-opt zetz-keywords 'words)
  "Regular expression for matching keywords.")

(defconst zetz-declaration-keywords-regexp
  (regexp-opt zetz-declaration-keywords 'words)
  "Regular expression for matching declaration keywords.")

(defconst zetz-preprocessor-keywords-regexp
  (regexp-opt zetz-preprocessor-keywords 'words)
  "Regular expression for matching preprocessor keywords.")

(defconst zetz-careful-keywords-regexp (regexp-opt zetz-careful-keywords 'words)
  "Regular expression for matching careful keywords.")

(defconst zetz-builtin-keywords-regexp (regexp-opt zetz-builtin-keywords 'words)
  "Regular expression for matching builtin type.")

(defconst zetz-constant-regexp (regexp-opt zetz-constants 'words)
  "Regular expression for matching constants.")

(defconst zetz-operator-functions-regexp
  (regexp-opt zetz-operator-functions 'words)
  "Regular expression for matching operator functions.")

(defconst zetz-font-lock-keywords
  `(
     ;; builtin
     (,zetz-builtin-keywords-regexp . font-lock-builtin-face)

     ;; careful
     (,zetz-careful-keywords-regexp . font-lock-warning-face)

     ;; declaration
     (,zetz-declaration-keywords-regexp . font-lock-keyword-face)

     ;; preprocessor
     (,zetz-preprocessor-keywords-regexp . font-lock-preprocessor-face)

     ;; keywords
     (,zetz-keywords-regexp . font-lock-keyword-face) ;;font-lock-keyword-face

     ;; delimiter: modifier
     ("\\(->\\|=>\\|\\.>\\|:>\\|::\\||\\)" 1 'font-lock-keyword-face)

     ;; delimiter: . , ; separate
     ("\\($?[.,;]+\\)" 1 'font-lock-comment-delimiter-face)

     ;; delimiter: operator symbols
     ("\\($?[+-/*//%~=<>]+\\)$?,?" 1 'font-lock-negation-char-face)
     ("\\($?[?^!&]+\\)" 1 'font-lock-warning-face)

     ;; delimiter: = : separate
     ("[^+-/*//%~^!=<>]\\([=:]\\)[^+-/*//%~^!=<>]" 1
       'font-lock-comment-delimiter-face)

     ;; delimiter: brackets
     ("\\(\\[\\|\\]\\|[(){}]\\)" 1 'font-lock-comment-delimiter-face)

     ;; operator methods
     (,zetz-operator-functions-regexp . font-lock-builtin-face)

     ;; C
     ;; ("#\\(?:include\\|if\\|def\\|undef\\|else\\|elif\\|endif\\)" . 'font-lock-builtin-face)
     ("#\\([A-Za-z ]+\\)" . 'font-lock-builtin-face)

     ;; method definitions
     ;; ("\\(?:fn\\)\s+\\($?[a-z_][A-Za-z0-9_]*\\)" 1 'font-lock-function-name-face)

     ;; type
     ;; ("\\(?:struct\\|trait\\|type\\)\s+\\($?_?[A-Z][A-Za-z0-9_]*\\)" 1 'font-lock-type-face)
     ("\\([A-Z][A-Za-z0-9_]*\\)" 1 'font-lock-type-face)
     ("\\([A-Za-z0-9_]*_t\\)" 1 'font-lock-type-face)
     ("\\([A-Za-z0-9_]*\\)::" 1 'font-lock-type-face)

     ;; constants references
     (,zetz-constant-regexp . font-lock-constant-face)

     ;; @
     ("@[A-Za-z_]*[A-Z-a-z0-9_]*" . 'font-lock-builtin-face)

     ;; method references
     ("\\([a-z_]$?[a-z0-9_]?+\\)$?[ \t]?(+" 1 'font-lock-function-name-face)

     ;; parameter
     ;; ("\\(?:(\\|,\\)\\([a-z_][a-z0-9_']*\\)\\([^ \t\r\n,:)]*\\)" 1
     ;; 'font-lock-variable-name-face)
     ;; ("\\(?:(\\|,\\)[ \t]+\\([a-z_][a-z0-9_']*\\)\\([^ \t\r\n,:)]*\\)" 1
     ;; 'font-lock-variable-name-face)

     ;; tuple references
     ("[.]$?[ \t]?\\($?_[1-9]$?[0-9]?*\\)" 1 'font-lock-variable-name-face)

     ;; character literals
     ("\\('[\\].'\\)" 1 'font-lock-constant-face)

     ;; numeric literals
     ("[ \t/+-/*//=><([,;]\\([0-9]+[0-9a-zA-Z_]*\\)+" 1
       'font-lock-constant-face)

     ;; variable references
     ("\\([a-z_]+[a-z0-9_']*\\)+" 1 'font-lock-variable-name-face))
  "An alist mapping regexes to font-lock faces.")

(defun zetz-project-root-p (path)
  "Return t if directory `PATH' is the root of the ZetZ project."
  (let* ((files '("zz.toml" "make.bat" "Makefile"            ;
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

(defun zetz-project-root
  (&optional
    path)
  "Return the root of the ZetZ project.
Optional argument PATH: project path."
  (let* ((bufdir (if buffer-file-name   ;
                   (file-name-directory buffer-file-name) default-directory))
          (curdir (if path (file-name-as-directory path) bufdir))
          (parent (file-name-directory (directory-file-name curdir))))
    (if (or (not parent)
          (string= parent curdir)
          (string= parent (file-name-as-directory (getenv "HOME")))
          (string= parent "/")
          (zetz-project-root-p curdir)) ;
      curdir                            ;
      (zetz-project-root parent))))

(defun zetz-project-name ()
  "Return ZetZ project name."
  (file-name-base (directory-file-name (zetz-project-root))))

(defun zetz-project-file-exists-p (filename)
  "Return t if file `FILENAME' exists."
  (file-exists-p (concat (zetz-project-root) filename)))

(defun zetz-run-command (command &optional path)
  "Return `COMMAND' in the root of the ZetZ project.
Optional argument PATH: project path."
  (let ((oldir default-directory))
    (setq default-directory (if path path (zetz-project-root path)))
    (compile command)
    (setq default-directory oldir)))

(defun zetz-project-build ()
  "Build project with veronac."
  (interactive)
  (if (zetz-project-file-exists-p "Makefile")
    (zetz-run-command "make")
    (zetz-run-command "veronac .")))

(defun zetz-project-open ()
  "Open `zz.toml' file."
  (interactive)
  (if (zetz-project-file-exists-p "zz.toml")
    (find-file (concat (zetz-project-root) "zz.toml"))))

(defun zetz-buffer-dirname ()
  "Return current buffer directory file name."
  (directory-file-name (if buffer-file-name (file-name-directory
                                              buffer-file-name)
                         default-directory)))

(defun zetz-project-run ()
  "Run project."
  (interactive)
  (let* ((bin1 (concat (zetz-project-root) "bin/" (zetz-project-name)))
          (bin2 (concat (zetz-project-root) "/" (zetz-project-name)))
          (bin3 (concat (zetz-buffer-dirname) "/" (zetz-project-name))))
    (cond ((file-exists-p bin1)
            (zetz-run-command bin1))
      ((file-exists-p bin2)
        (zetz-run-command bin2))
      ((file-exists-p bin2)
        (zetz-run-command bin3)))))

(easy-menu-define zetz-mode-menu zetz-mode-map ;
  "Menu for ZetZ mode."                        ;
  '("ZetZ"                                     ;
     ["Build" zetz-project-build t]            ;
     ["Run" zetz-project-run t]                ;
     "---"                                     ;
     ("Community"                              ;
       ["Home" (zetz-run-command "xdg-open https://github.com/zetzit/zz") t]
       ["ZetZ Tweets" ;;
         (zetz-run-command "xdg-open https://twitter.com/zetztweets") t])))

(defun zetz-banner-default ()
  "ZetZ banner."
  "
           _
          | |
   _______| |_ ____
  |_  / _ \\ __|_  /
   / /  __/ |_ / /
  /___\\___|\\__/___|
")

(defhydra zetz-hydra-menu
  (:color blue
    :hint none)
  "
%s(zetz-banner-default)
  Project     |  _b_: Build     _r_: Run
  Community   |  _1_: Home      _2_: News
  _q_: Quit"                            ;
  ("b" zetz-project-build "Build")
  ("r" zetz-project-run "Run")
  ("1" (zetz-run-command "xdg-open https://github.com/zetzit/zz") "Home")
  ("2" (zetz-run-command "xdg-open https://twitter.com/zetztweets") "News")
  ("q" nil "Quit"))

(defun zetz-menu ()
  "Open ZetZ hydra menu."
  (interactive)
  (zetz-hydra-menu/body))

(defun zetz-build-tags ()
  "Build tags for current project."
  (interactive)
  (let ((tags-buffer (get-buffer "TAGS"))
         (tags-buffer2 (get-buffer (format "TAGS<%s>" (zetz-project-name)))))
    (if tags-buffer (kill-buffer tags-buffer))
    (if tags-buffer2 (kill-buffer tags-buffer2)))
  (let* ((zetz-path (string-trim (shell-command-to-string "which zz")))
          (zetz-executable              ;
            (string-trim (shell-command-to-string (concat "readlink -f "
                                                    zetz-path))))
          (packages-path                ;
            (expand-file-name (concat (file-name-directory zetz-executable)
                                "../modules")))
          (ctags-params                 ;
            (concat "ctags --languages=-zetz --langdef=zetz --langmap=zetz:.zz "
              "--regex-zetz=/[ \\t]*fn[ \\t]+([a-zA-Z0-9_]+)/\\1/f,fn/ "
              "--regex-zetz=/[ \\t]*macro[ \\t]+([a-zA-Z0-9_]+)/\\1/m,macro/ "
              "--regex-zetz=/[ \\t]*theory[ \\t]+([a-zA-Z0-9_]+)/\\1/h,theory/ "
              "--regex-zetz=/[ \\t]*closure[ \\t]+([a-zA-Z0-9_]+)/\\1/l,closure/ "
              "--regex-zetz=/[ \\t]*symbol[ \\t]+([a-zA-Z0-9_]+)/\\1/y,symbol/ "
              "--regex-zetz=/[ \\t]*struct[ \\t]+([a-zA-Z0-9_]+)/\\1/s,sturct/ "
              "--regex-zetz=/[ \\t]*test[ \\t]+([a-zA-Z0-9_]+)/\\1/t,test/ " ;
              "--regex-zetz=/[ \\t]*enum[ \\t]+([a-zA-Z0-9_]+)/\\1/e,enum/ "
              "--regex-zetz=/[ \\t]*const[ \\t]+([a-zA-Z0-9_]+)[ \\t]+([a-zA-Z0-9_]+)[ \\t]*=/\\2/n,const/ "
              "-e -R . " packages-path)))
    (when (file-exists-p packages-path)
      (let ((oldir default-directory))
        (setq default-directory (zetz-project-root))
        (message "ctags:%s" (shell-command-to-string ctags-params))
        (zetz-load-tags)
        (setq default-directory oldir)))))

(defun zetz-load-tags
  (&optional
    build)
  "Visit tags table.
Optional argument BUILD If the tags file does not exist, execute the build."
  (interactive)
  (let* ((tags-file (concat (zetz-project-root) "TAGS")))
    (if (file-exists-p tags-file)
      (progn (visit-tags-table (concat (zetz-project-root) "TAGS")))
      (if build (zetz-build-tags)))))

(defun zetz-after-save-hook ()
  "After save hook."
  (when (eq major-mode 'zetz-mode)
    (shell-command (concat  "zz fmt " (buffer-file-name)))
    (revert-buffer
      :ignore-auto
      :noconfirm)
    (if (not (executable-find "ctags"))
      (message "Could not locate executable '%s'" "ctags")
      (zetz-build-tags))))

;;;###autoload
(define-derived-mode zetz-mode prog-mode
  "ZetZ"
  "Major mode for editing ZetZ files."
  :syntax-table zetz-mode-syntax-table
  ;; (setq-local bidi-paragraph-direction 'left-to-right)
  (setq-local require-final-newline mode-require-final-newline)
  (setq-local parse-sexp-ignore-comments t)
  (setq-local comment-start "/*")
  (setq-local comment-end "*/")
  (setq-local comment-start-skip "\\(//+\\|/\\*+\\)\\s *")
  ;;
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 4)
  (setq-local buffer-file-coding-system 'utf-8-unix)
  ;;
  (setq-local electric-indent-chars (append "{}():;," electric-indent-chars))
  (setq-local indent-line-function #'js-indent-line)
  (setq-local js-indent-level tab-width)
  ;;
  ;; (setq-local font-lock-defaults        ;
  ;; '(zetz-font-lock-keywords ;
  ;; nil nil nil nil         ;
  ;; (font-lock-syntactic-face-function . zetz-mode-syntactic-face-function)))
  (setq-local font-lock-defaults '(zetz-font-lock-keywords))
  (font-lock-ensure)
  ;;
  ;; (setq-local syntax-propertize-function zetz-syntax-propertize-function)
  ;;
  (setq-local imenu-generic-expression ;;
    '(("TODO" ".*TODO:[ \t]*\\(.*\\)$" 1)
       ("fn" "[ \t]*fn[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("macro" "[ \t]*macro[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("theory" "[ \t]*theory[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("closure" "[ \t]*closure[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("symbol" "[ \t]*symbol[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("struct" "[ \t]*struct[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("test" "[ \t]*test[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("enum" "[ \t]*enum[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("const" "[ \t]*const[ \t]+\\(.+\\)[ \t]*=" 1)
       ("export" "[ \t]*export[ \t]+\\(.*\\)(" 1)
       ("pub" "[ \t]*pub[ \t]+\\(.*\\)[({]" 1)))
  (imenu-add-to-menubar "Index")
  ;;
  (add-hook 'after-save-hook #'zetz-after-save-hook nil t)
  (zetz-load-tags))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.zz\\'" . zetz-mode))

;;
(provide 'zetz-mode)

;;; zetz-mode.el ends here
