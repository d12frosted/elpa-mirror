;;; v-mode.el --- A major mode for the V programming language  -*- lexical-binding: t; -*-

;; Copyright (c) 2020 Damon Kwok

;; Authors: Damon Kwok <damon-kwok@outlook.com>
;; Version: 0.0.1
;; URL: https://github.com/damon-kwok/v-mode
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
;;
;; Description:
;;
;; This is a major mode for the V programming language
;;
;; For more details, see the project page at
;; https://github.com/damon-kwok/v-mode
;;
;; Installation:
;;
;; The simple way is to use package.el:
;;
;;   M-x package-install v-mode
;;
;; Or, copy v-mode.el to some location in your Emacs load
;; path.  Then add "(require 'v-mode)" to your Emacs initialization
;; (.emacs, init.el, or something).
;;
;; Example config:
;;
;;   (require 'v-mode)
;;
;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'js)
(require 'dash)
(require 'xref)
(require 'hydra)
(require 'imenu)
(require 'easymenu)

(defvar v-mode-hook nil)

(defconst v-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; fontify " using v-keywords

    ;; Operators
    (dolist (i '(?+ ?- ?* ?/ ?% ?& ?| ?= ?! ?< ?>))
      (modify-syntax-entry i "." table))

    ;; / is punctuation, but // is a comment starter
    (modify-syntax-entry ?/ ". 124" table)

    ;; /* */ comments, which can be nested
    ;; (modify-syntax-entry ?* ". 23bn" table)
    ;; (modify-syntax-entry ?\n ">" table)
       
    ;; uses // for comments
    (modify-syntax-entry ?/  ". 12" table)
    (modify-syntax-entry ?\n ">"    table)

    ;; string
    (modify-syntax-entry ?\` "\"" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)

    ;; Don't treat underscores as whitespace
    (modify-syntax-entry ?_ "w" table) table))

(defun v-comment-or-uncomment-region-or-line ()
  "Comments or uncomments the region or the current line if there's no active region."
  (interactive)
  (let (beg end)
    (if (region-active-p)
      (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)
    (next-line)))

(defvar v-mode-map
  (let ((map (make-keymap)))
    (define-key map "\C-j" 'newline-and-indent)
    (define-key map "\M-;" 'v-comment-or-uncomment-region-or-line)
    ;; (define-key map (kbd "<C-return>") 'yafolding-toggle-element) ;
    map)
  "Keymap for V major mode.")

(defconst v-keywords '("if" "else" "for" "match")
  "V language keywords.")

;;;###autoload
(defgroup v-mode nil
  "Major mode for editing V code."
  :prefix "v-"
  :group 'languages)

(defcustom v-declaration-keywords
                                        ;
  '("type" "interface" "struct" "enum" "fn")
  "V declaration keywords."
  :type '(repeat string)
  :group 'v-mode)

(defcustom v-preprocessor-keywords '("module" "pub" "const")
  "V preprocessor keywords."
  :type '(repeat string)
  :group 'v-mode)

(defcustom v-careful-keywords
  '("import"                            ;
     "break" "continue" "return" "goto" ;
     "defer" "panic" "error"            ;
     "in" "is" "or"                     ;
     "go" "inline" "live"               ;
     "as" "assert"  "unsafe" "mut"      ;
     "__global" "C")
  "V language careful keywords."
  :type '(repeat string)
  :group 'v-mode)

(defcustom v-builtin-keywords
  '("string" "bool"                         ;
     "i8" "i16" "int" "i64" "i128"          ;
     "byte" "u16" "u32" "u64" "u128"        ;
     "rune"                                 ;
     "f32" "f64"                            ;
     "byteptr" "voidptr" "charptr" "size_t" ;
     "any" "any_int" "any_float"            ;
     "it")
  "V language keywords."
  :type '(repeat string)
  :group 'v-mode)

(defcustom v-constants                  ;
  '("false" "true" "none")
  "Common constants."
  :type '(repeat string)
  :group 'v-mode)

(defcustom v-operator-functions '()
  "V language operators functions."
  :type '(repeat string)
  :group 'v-mode)

;; create the regex string for each class of keywords

(defconst v-keywords-regexp (regexp-opt v-keywords 'words)
  "Regular expression for matching keywords.")

(defconst v-declaration-keywords-regexp
                                        ;
  (regexp-opt v-declaration-keywords 'words)
  "Regular expression for matching declaration keywords.")

(defconst v-preprocessor-keywords-regexp
                                        ;
  (regexp-opt v-preprocessor-keywords 'words)
  "Regular expression for matching preprocessor keywords.")

(defconst v-careful-keywords-regexp
                                        ;
  (regexp-opt v-careful-keywords 'words)
  "Regular expression for matching careful keywords.")

(defconst v-builtin-keywords-regexp (regexp-opt v-builtin-keywords 'words)
  "Regular expression for matching builtin type.")

(defconst v-constant-regexp             ;
  (regexp-opt v-constants 'words)
  "Regular expression for matching constants.")

(defconst v-operator-functions-regexp
                                        ;
  (regexp-opt v-operator-functions 'words)
  "Regular expression for matching operator functions.")

(defvar v-font-lock-keywords
  `(
     ;; builtin
     (,v-builtin-keywords-regexp . font-lock-builtin-face)

     ;; careful
     (,v-careful-keywords-regexp . font-lock-warning-face)

     ;; @ # $
     ;; ("#\\(?:include\\|flag\\)" . 'font-lock-builtin-face)
     ("[@#$][A-Za-z_]*[A-Z-a-z0-9_]*" . 'font-lock-warning-face)

     ;; declaration
     (,v-declaration-keywords-regexp . font-lock-keyword-face)

     ;; preprocessor
     (,v-preprocessor-keywords-regexp . font-lock-preprocessor-face)

     ;; delimiter: modifier
     ("\\(->\\|=>\\|\\.>\\|:>\\|:=\\|\\.\\.\\||\\)" 1 'font-lock-keyword-face)

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

     ;; numeric literals
     ;; ("[^A-Za-z_]\\([0-9][A-Za-z0-9_]*\\)" 1 'font-lock-constant-face)
     ("[ \t/+-/*//=><([{,;&|%]\\([0-9][A-Za-z0-9_]*\\)" 1
       'font-lock-constant-face)

     ;; operator methods
     (,v-operator-functions-regexp . font-lock-builtin-face)

     ;; method definitions
     ("\\(?:fn\\)\s+\\($?[a-z_][A-Za-z0-9_]*\\)" 1
       'font-lock-function-name-face)

     ;; type
     ("\\([A-Z][A-Za-z0-9_]*\\)" 1 'font-lock-type-face)

     ;; constants references
     (,v-constant-regexp . font-lock-constant-face)

     ;; method references
     ("\\([a-z_]$?[a-z0-9_]?+\\)$?[ \t]?(+" 1 'font-lock-function-name-face)

     ;; parameter
     ("\\(?:(\\|,\\)\\([a-z_][a-z0-9_']*\\)\\([^ \t\r\n,:)]*\\)" 1
       'font-lock-variable-name-face)
     ("\\(?:(\\|,\\)[ \t]+\\([a-z_][a-z0-9_']*\\)\\([^ \t\r\n,:)]*\\)" 1
       'font-lock-variable-name-face)

     ;; tuple references
     ("[.]$?[ \t]?\\($?_[1-9]$?[0-9]?*\\)" 1 'font-lock-variable-name-face)

     ;; keywords
     (,v-keywords-regexp . font-lock-keyword-face) ;;font-lock-keyword-face

     ;; character literals
     ("\\('[\\].'\\)" 1 'font-lock-constant-face)

     ;; variable references
     ("\\($?_?[a-z]+[a-z_0-9]*\\)" 1 'font-lock-variable-name-face))
  "An alist mapping regexes to font-lock faces.")

(defun v-project-root-p (path)
  "Return t if directory `PATH' is the root of the V project."
  (let* ((files '("v.mod" "make.bat" "Makefile"              ;
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

(defun v-project-root
  (&optional
    path)
  "Return the root of the V project.
Optional argument PATH ."
  (let* ((bufdir (if buffer-file-name   ;
                   (file-name-directory buffer-file-name) default-directory))
          (curdir (if path (file-name-as-directory path) bufdir))
          (parent (file-name-directory (directory-file-name curdir))))
    (if (or (not parent)
          (string= parent curdir)
          (string= parent (file-name-as-directory (getenv "HOME")))
          (string= parent "/")
          (v-project-root-p curdir))    ;
      curdir                            ;
      (v-project-root parent))))

(defun v-project-name ()
  "Return V project name."
  (file-name-base (directory-file-name (v-project-root))))

(defun v-project-file-exists-p (filename)
  "Return t if file `FILENAME' exists."
  (file-exists-p (concat (v-project-root) filename)))

(defun v-run-command (command &optional path)
  "Return `COMMAND' in the root of the V project.
Optional argument PATH ."
  (let ((oldir default-directory))
    (setq default-directory (if path path (v-project-root path)))
    (compile command)
    (setq default-directory oldir)))

(defun v-project-build ()
  "Build project with v."
  (interactive)
  (if (v-project-file-exists-p "Makefile")
    (v-run-command "make")
    (v-run-command "v .")))

(defun v-project-init ()
  "Run v `init' command."
  (interactive)
  (unless (v-project-file-exists-p "v.mod")
    (v-run-command "v init")))

(defun v-project-update ()
  "Run v `update' command."
  (interactive)
  (if (v-project-file-exists-p "v.mod")
    (v-run-command "v update")))

(defun v-project-open ()
  "Open `v.mod' file."
  (interactive)
  (if (v-project-file-exists-p "v.mod")
    (find-file (concat (v-project-root) "v.mod"))))

(defun v-buffer-dirname ()
  "Return current buffer directory file name."
  (directory-file-name (if buffer-file-name (file-name-directory
                                              buffer-file-name)
                         default-directory)))

(defun v-project-run ()
  "Run project."
  (interactive)
  (let* ((bin1 (concat (v-project-root) "bin/" (v-project-name)))
          (bin2 (concat (v-project-root) "/" (v-project-name)))
          (bin3 (concat (v-buffer-dirname) "/" (v-project-name))))
    (cond ((file-exists-p bin1)
            (v-run-command bin1))
      ((file-exists-p bin2)
        (v-run-command bin2))
      ((file-exists-p bin2)
        (v-run-command bin3)))))

(easy-menu-define v-mode-menu v-mode-map ;
  "Menu for V mode."                     ;
  '("V"                                  ;
     ["Build" v-project-build t]         ;
     ["Run" v-project-run t]             ;
     ["Init" v-project-init t]           ;
     ["Open" v-project-open t]           ;
     ["Update" v-project-update t]       ;
     "---"                               ;
     ("Community"                        ;
       ["News" (v-run-command "xdg-open https://twitter.com/v_language") t]
       ["Discord" (v-run-command "xdg-open https://discord.gg/vlang") t]
       ["Open an issue" (v-run-command
                          "xdg-open https://github.com/vlang/v/issues") t]
       ["Tutorial" (v-run-command
                     "xdg-open https://github.com/vlang/v/blob/master/doc/docs.md") t]
       ["Awesome-V" ("xdg-open https://github.com/vlang/awesome-v") t]
       ["Contribute" (v-run-command
                       "xdg-open https://github.com/vlang/v/blob/master/CONTRIBUTING.md") t]
       ["Supporter" (v-run-command "xdg-open https://patreon.com/vlang") t])))

(defun v-banner-default ()
  "V banner."
  "
  __   __
  \\ \\ / /
   \\ V /
    \\_/
")

(defhydra v-hydra-menu
  (:color blue
    :hint none)
  "
%s(v-banner-default)
  Project     |  _i_: Init      _u_: Update     _o_: v.mod
              |  _b_: Build     _r_: Run
  Community   |  _1_: News      _2_: Discord    _3_: OpenIssue
              |  _4_: Tutorial  _5_: Awesome-V  _6_: Sponsors  _0_: Contribute
  _q_: Quit"                            ;
  ("b" v-project-build "Build")
  ("r" v-project-run "Run")
  ("o" v-project-open "Open v.mod")
  ("i" v-project-init "v init")
  ("u" v-project-update "v udate")
  ("1" (v-run-command "xdg-open https://twitter.com/v_language") "News")
  ("2" (v-run-command "xdg-open https://discord.gg/vlang") "Discord")
  ("3" (v-run-command "xdg-open https://github.com/vlang/v/issues")
    "Open an issue")
  ("4" (v-run-command
         "xdg-open https://github.com/vlang/v/blob/master/doc/docs.md") "Docs")
  ("5" (v-run-command "xdg-open https://github.com/vlang/awesome-v")
    "Awesome-V")
  ("6" (v-run-command "xdg-open https://patreon.com/vlang") "Supporter")
  ("0" (v-run-command
         "xdg-open https://github.com/vlang/v/blob/master/CONTRIBUTING.md")
    "Contribute")
  ("q" nil "Quit"))

(defun v-menu ()
  "Open v hydra menu."
  (interactive)
  (v-hydra-menu/body))

(defun v-build-tags ()
  "Build tags for current project."
  (interactive)
  (let ((tags-buffer (get-buffer "TAGS"))
         (tags-buffer2 (get-buffer (format "TAGS<%s>" (v-project-name)))))
    (if tags-buffer (kill-buffer tags-buffer))
    (if tags-buffer2 (kill-buffer tags-buffer2)))
  (let* ((v-path (string-trim (shell-command-to-string "which v")))
          (v-executable                 ;
            (string-trim (shell-command-to-string (concat "readlink -f "
                                                    v-path))))
          (packages-path                ;
            (concat (file-name-directory v-executable) "vlib"))
          (ctags-params                 ;
            (concat  "ctags --langdef=v --langmap=v:.v "
              "--regex-v='/[ \\t]*fn[ \\t]+(.*)[ \\t]+(.*)/\\2/f,function/' "
              "--regex-v='/[ \\t]*struct[ \\t]+([a-zA-Z0-9_]+)/\\1/s,struct/' "
              "--regex-v='/[ \\t]*interface[ \\t]+([a-zA-Z0-9_]+)/\\1/i,interface/' "
              "--regex-v='/[ \\t]*type[ \\t]+([a-zA-Z0-9_]+)/\\1/t,type/' "
              "--regex-v='/[ \\t]*enum[ \\t]+([a-zA-Z0-9_]+)/\\1/e,enum/' "
              "--regex-v='/[ \\t]*module[ \\t]+([a-zA-Z0-9_]+)/\\1/m,module/' "
                                        ;
              "-e -R . " packages-path)))
    (when (file-exists-p packages-path)
      (let ((oldir default-directory))
        (setq default-directory (v-project-root))
        (message "ctags:%s" (shell-command-to-string ctags-params))
        (v-load-tags)
        (setq default-directory oldir)))))

(defun v-load-tags
  (&optional
    build)
  "Visit tags table.
Optional argument BUILD ."
  (interactive)
  (let* ((tags-file (concat (v-project-root) "TAGS")))
    (if (file-exists-p tags-file)
      (progn (visit-tags-table (concat (v-project-root) "TAGS")))
      (if build (v-build-tags)))))

(defun v-format-buffer ()
  "Format the current buffer using the 'v fmt -w'."
  (interactive)
  (when (eq major-mode 'v-mode)
    (shell-command (concat  "v fmt -w " (buffer-file-name)))
    (revert-buffer
      :ignore-auto
      :noconfirm)))

(defun v-after-save-hook ()
  "After save hook."
  (when (eq major-mode 'v-mode)
    (v-format-buffer)
    (if (not (executable-find "ctags"))
      (message "Could not locate executable '%s'" "ctags")
      (v-build-tags))))

;;;###autoload
(define-derived-mode v-mode prog-mode
  "V"
  "Major mode for editing V files."
  :syntax-table v-mode-syntax-table
  ;;
  (setq-local require-final-newline mode-require-final-newline)
  (setq-local parse-sexp-ignore-comments t)
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq-local comment-multi-line t)
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
  (setq-local font-lock-defaults '(v-font-lock-keywords))
  (font-lock-flush)
  ;;
  (setq-local imenu-generic-expression ;;
    '(("TODO" ".*TODO:[ \t]*\\(.*\\)$" 1)
       ("fn" "[ \t]*fn[ \t]+(.*)[ \t]+\\(.*\\)[ \t]*(.*)" 1)
       ("struct" "[ \t]*struct[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("interface" "[ \t]*interface[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("type" "[ \t]*type[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("enum" "[ \t]*enum[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("import" "[ \t]*import[ \t]+\\([a-zA-Z0-9_]+\\)" 1)))
  (imenu-add-to-menubar "Index")
  ;;
  (add-hook 'after-save-hook #'v-after-save-hook nil t)
  (v-load-tags))

;;;###autoload
(setq auto-mode-alist
      (cons '("\\(\\.v?v\\|\\.vsh\\)$" . v-mode) auto-mode-alist))

;;
(provide 'v-mode)

;;; v-mode.el ends here
