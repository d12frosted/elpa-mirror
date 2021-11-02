;;; modern-sh.el --- Minor mode for editing shell script  -*- lexical-binding: t -*-

;; Copyright (c) 2020 Damon Kwok

;; Authors: Damon Kwok <damon-kwok@outlook.com>
;; Version: 0.0.1
;; Package-Version: 20211101.1001
;; Package-Commit: 8ebebe77304aa8170f7af809e7564c79d3bd45da
;; URL: https://github.com/damon-kwok/modern-sh
;; Keywords: languages programming
;; Package-Requires: ((emacs "25.1") (hydra "0.15.0") (eval-in-repl "0.9.7"))

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
;; An Emacs minor mode for editing shell script.
;;
;; For more details, see the project page at
;; https://github.com/damon-kwok/modern-sh
;;
;; Installation:
;;
;; The simple way is to use package.el:
;;
;;   M-x package-install modern-sh

;;; Code:

(require 'cl-lib)
(require 'sh-script)
(require 'xref)
(require 'hydra)
(require 'imenu)
(require 'eval-in-repl-shell)

(defvar modern-sh-mode-hook nil)

(defvar modern-sh-mode-map (let ((map (make-keymap))) map)
  "Keymap for Modern shell minor mode.")

(defconst modern-sh-keywords
  '("if" "else" "elif" "then" "fi"      ;
     "case" "esac" "for" "in"           ;
     "while" "until" "do" "done")
  "Modern shell keywords.")

(defconst modern-sh-declaration-keywords
  '("function" "let" "local" "declare" "typeset" "set")
  "Modern shell declaration keywords.")

(defconst modern-sh-preprocessor-keywords
  '("emacs" "em" "vi" "vim" "nano" "ed" ;
     "sh" "bash" "zsh" "csh" "ksh" "fish" "pwsh")
  "Modern shell preprocessor keywords.")

(defconst modern-sh-careful-keywords
  '("return" "break" "continue"         ;
     "source" "eval" "export"           ;
     "readonly" "alias" "unset" "shift")
  "Modern shell language careful keywords.")

(defconst modern-sh-builtin-keywords
  '("chroot" "passwd" "chmod" "sleep" "read" ;
     "su" "sudo" "exit" "rm" "pushd" "popd"  ;
     "kill" "pkill" "skill" "killall"        ;
     "emerge" "ego" "cave" "freebsd-update"  ;
     "pkg" "apk" "setenv" "pkg_add" "env"    ;
     "apt" "pat-get" "yum" "dnf" "zypper"    ;
     "install" "groupinstall" "resolve" "sync")
  "Modern shell builtin keywords.")

(defconst modern-sh-builtin-params-keywords
  '("install" "groupinstall" "resolve" "sync")
  "Modern shell params keywords.")

(defconst modern-sh-constants '("true" "false" "test" "command")
  "Common constants.")

(defconst modern-sh-operator-functions '()
  "Modern shell language operators functions.")

;;; create the regex string for each class of keywords
(defconst modern-sh-keywords-regexp (regexp-opt modern-sh-keywords 'words)
  "Regular expression for matching keywords.")

(defconst modern-sh-declaration-keywords-regexp
  (regexp-opt modern-sh-declaration-keywords 'words)
  "Regular expression for matching declaration keywords.")

(defconst modern-sh-preprocessor-keywords-regexp
  (regexp-opt modern-sh-preprocessor-keywords 'words)
  "Regular expression for matching preprocessor keywords.")

(defconst modern-sh-careful-keywords-regexp
  (regexp-opt modern-sh-careful-keywords 'words)
  "Regular expression for matching careful keywords.")

(defconst modern-sh-builtin-keywords-regexp
  (regexp-opt modern-sh-builtin-keywords 'words)
  "Regular expression for matching builtin type.")

(defconst modern-sh-builtin-params-keywords-regexp
  (regexp-opt modern-sh-builtin-params-keywords 'words)
  "Regular expression for matching builtin params.")

(defconst modern-sh-constant-regexp (regexp-opt modern-sh-constants 'words)
  "Regular expression for matching constants.")

(defconst modern-sh-operator-functions-regexp
  (regexp-opt modern-sh-operator-functions 'words)
  "Regular expression for matching operator functions.")

(defconst modern-sh-font-lock-keywords
  `(
     ;; source
     ("^[ \t]*\\(\\.\\)[ \t\n]" 1 'font-lock-warning-face)

     ;; careful
     (,modern-sh-careful-keywords-regexp . font-lock-warning-face)

     ;; env variable
     ("[$>&]+\\([A-Za-z0-9_#@-]+\\)" . 'font-lock-warning-face)
     ("[@^]+\\([A-Za-z][A-Za-z0-9_]+\\)" 1 'font-lock-keyword-face)
     ("${\\([A-Za-z0-9_#@-]+\\)" 1 'font-lock-warning-face)

     ;; case options
     ("^[ \t[]*\\([A-Za-z0-9_.=@?#/+-]+\\)[*]*[] \t]*)" 1
       'font-lock-negation-char-face)
     ("[^|]|[ \t]*\\([A-Za-z_.-][A-Za-z0-9_.-]+\\)" 1
       'font-lock-negation-char-face)
     ("\\([A-Za-z_.-][A-Za-z0-9_.-]+\\)[ \t]*|[^|]" 1
       'font-lock-negation-char-face)

     ;; command options
     ("[ \t]\\([+-]+[A-Za-z_][A-Za-z0-9_-]*\\)" 1 'font-lock-builtin-face)

     ;; delimiter: modifier
     ("\\(\\*\\|\\?\\|\\^\\|\\$\\?\\)" 1 'font-lock-warning-face)
     ("\\(++\\|--\\|!=\\)" 1 'font-lock-warning-face)
     ("\\(->\\|=>\\|\\.>\\|=:\\)" 1 'font-lock-keyword-face)

     ;; delimiter: path
     ("\\([:]*[/]+\\)" 1 'font-lock-keyword-face)

     ;; path: protocol
     ("\\([A-Za-z0-9_.-]*\\)://" 1 'font-lock-constant-face)

     ;; path: dirname
     ("[ \t]*\\([.]+\\)[ \t\n]" 1 'font-lock-negation-char-face)
     ("[:]*/\\([A-Za-z0-9_.-]*\\)" 1 'font-lock-negation-char-face)
     ("\\([A-Za-z0-9_.-]*\\)[:]*/" 1 'font-lock-negation-char-face)

     ;; ipv4 & ipv6
     ("\\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\\)" 1 'font-lock-constant-face)
     ("\\([A-Za-z0-9]+:[A-Za-z0-9]+:[A-Za-z0-9]+:[A-Za-z0-9]+:[A-Za-z0-9]+:[A-Za-z0-9]+:[A-Za-z0-9]+:[A-Za-z0-9]+\\)"
       1 'font-lock-constant-face)
     ;; keyword
     (,modern-sh-keywords-regexp . font-lock-keyword-face)

     ;; variable define
     ("\\(:-\\|:\\+\\)" 1 'font-lock-builtin-face)
     ("\\(:-\\|:\\+\\)\\([A-Za-z_][A-Za-z0-9_]*\\)" 2
       'font-lock-variable-name-face)
     ("\\([A-Za-z_][A-Za-z0-9_]*\\)[ \t]*[=[]" 1 'font-lock-variable-name-face)

     ;; builtin
     (,modern-sh-builtin-params-keywords-regexp . font-lock-constant-face)
     (,modern-sh-builtin-keywords-regexp . font-lock-warning-face)

     ;; declaration
     (,modern-sh-declaration-keywords-regexp . font-lock-keyword-face)

     ;; preprocessor
     (,modern-sh-preprocessor-keywords-regexp . font-lock-preprocessor-face)

     ;; operator function
     (,modern-sh-operator-functions-regexp . font-lock-builtin-face)

     ;; constants reference
     (,modern-sh-constant-regexp . font-lock-constant-face)

     ;; function define
     ("\\(function\s+\\)*\\([A-Za-z_-][A-Za-z0-9_-]*\\)[ \t]*(" 2
       'font-lock-function-name-face)

     ;; wrap line
     ;; ("\\(\\\\[ \t]*\n\\)\\(.*[^\\]\\)\\($\\|[ \t]+-\\|[ \t]*\\\\[ \t]*$\\)" 2 'font-lock-variable-name-face)
     ("\\(\\\\[ \t]*\n\\)\\([A-Za-z0-9_ \t+-]+[^\\]\\)" 2
       'font-lock-variable-name-face)
     ("\\(.*\\)[ \t]*\\(\\\\[ \t]*$\\)" 1 'font-lock-variable-name-face)

     ;; command
     ("^[ \t]*\\(sudo[ \t]\\)?\\([A-Za-z_.-][A-Za-z0-9_.-]*[A-Za-z0-9_]\\|[A-Za-z]\\)[ \t]*\\(||\\)?"
       2 'font-lock-function-name-face)
     ("\\(sudo\\)[ \t]+\\([A-Za-z0-9_.-]+\\)" 2 'font-lock-function-name-face)
     ("\\([A-Za-z0-9_.-]+[ \t]*)\\)[ \t]*\\([A-Za-z0-9_.-]+\\)" 2
       'font-lock-function-name-face)

     ;; format
     ("\\(%[A-Za-z0-9]*\\)" 1 'font-lock-preprocessor-face)

     ;; values
     ;; values: easy
     ;; ("[ \t]\\([+-]+[A-Za-z0-9_.-]+\\)[ \t]*[=]*[ \t]*\\(.*[^\\]\\)\\($\\|[ \t]+-\\|[ \t]*\\\\[ \t]*$\\)" 2
     ;; 'font-lock-constant-face)
     ;; values: plus
     ;; ("[ \t]\\([+-]+[A-Za-z0-9_.-]+\\)[ \t]*[=]*[ \t]*\\([A-Za-z0-9][A-Za-z0-9_ \t-]*\\)\\($\\|[ \t]+-\\|[ \t]*\\\\[ \t]*$\\)" 2
     ;; 'font-lock-constant-face)
     ;; values: only =
     ("[ \t]\\([+-]+[A-Za-z0-9_.-]+\\)[ \t]*=[ \t]*\\([A-Za-z0-9][A-Za-z0-9_.-]*\\)"
       2 'font-lock-constant-face)
     ;; values: raw
     ;; ("[ \t]\\([+-]+[A-Za-z0-9_.-]+\\)[ \t]*[=]*[ \t]*\\([A-Za-z0-9][A-Za-z0-9_.-]*\\)" 2
     ;; 'font-lock-constant-face)
     ("[:][ \t]*\\([A-Za-z_]+[A-Za-z0-9_-]*\\)" 1 'font-lock-constant-face)

     ;; variable refs
     ("[-+*/=,:;([{ \t]+\\([A-Za-z_.][A-Za-z0-9_.-]*[A-Za-z0-9_]\\|[A-Za-z]\\)"
       1 'font-lock-variable-name-face)

     ;; wrap symbol
     ;; ("\\([ \t]*\\\\[ \t]*$\\)" 1 'font-lock-warning-face)
     ("[ \t]*\\(\\\\[ \t]*$\\)" 1 'font-lock-warning-face)

     ;; negation-char literals
     ("\\(\\\\[A-Za-z0-9\"'`$@#_=*/+-]*\\)" 1 'font-lock-negation-char-face)

     ;; numeric literals
     ("\\([0-9]+[A-Za-z0-9_]*\\)+" 1 'font-lock-constant-face)

     ;; delimiter: .,:; separate
     ("\\([.,:;]+\\)" 1 'font-lock-comment-delimiter-face)

     ;; delimiter: operator symbols
     ("\\([>=<~|&]+\\)" 1 'font-lock-keyword-face)
     ("\\([$&*`@#?%&!^*/-]+\\)" 1 'font-lock-warning-face)

     ;; delimiter: brackets
     ("\\(\\[\\|\\]\\|[(){}]\\)" 1 'font-lock-comment-delimiter-face))
  "An alist mapping regexes to font-lock faces.")

(defun modern-sh-project-root-p (path)
  "Return t if directory `PATH' is the root of the Modern shell project."
  (let* ((files '( ".projectile" ".git" ".svn" ".hg" ".bzr"  ;
                   "Dockerfile" ".editorconfig" ".gitignore" ;
                   "Makefile" "CMakeLists.txt" "make.bat"))
          (foundp nil))
    (while (and (> (length files) 0)
             (not foundp))
      (let* ((filename (car files))
              (filepath (concat (file-name-as-directory path) filename)))
        (setq files (cdr files))
        (setq foundp (file-exists-p filepath)))) ;
    foundp))

(defun modern-sh-project-root
  (&optional
    path)
  "Return the root of the Modern shell project.
Optional argument PATH: project path."
  (let* ((bufdir (if buffer-file-name   ;
                   (file-name-directory buffer-file-name) default-directory))
          (curdir (if path (file-name-as-directory path) bufdir))
          (parent (file-name-directory (directory-file-name curdir)))
          (parent-basename (file-name-base (directory-file-name parent))))
    (if (or (not parent)
          (string= parent "/")
          (string= parent curdir)
          (string= parent (file-name-as-directory (getenv "HOME")))
          (and (>= (length parent-basename) 10)
            (string= (substring parent-basename 0 10) "smb-share:"))
          (modern-sh-project-root-p curdir)) ;
      curdir                                 ;
      (modern-sh-project-root parent))))

(defun modern-sh-project-name ()
  "Return Modern shell project name."
  (file-name-base (directory-file-name (modern-sh-project-root))))

(defun modern-sh-project-file-exists-p (filename)
  "Return t if file `FILENAME' exists."
  (file-exists-p (concat (modern-sh-project-root) filename)))

(defun modern-sh-run-command (command &optional path)
  "Return `COMMAND' in the root of the Modern shell project.
Optional argument PATH: project path."
  (let ((oldir default-directory))
    (setq default-directory (if path path (modern-sh-project-root path)))
    (compile command)
    (setq default-directory oldir)))

(defun modern-sh-project-build ()
  "Build project."
  (interactive)
  (if (modern-sh-project-file-exists-p "Makefile")
    (modern-sh-run-command "make")))

(defun modern-sh-project-open ()
  "Open `Makefile' file."
  (interactive)
  (if (modern-sh-project-file-exists-p "Makefile")
    (find-file (concat (modern-sh-project-root) "Makefile"))))

(defun modern-sh-buffer-dirname ()
  "Return current buffer directory file name."
  (directory-file-name (if buffer-file-name (file-name-directory
                                              buffer-file-name)
                         default-directory)))

(defun modern-sh-project-run ()
  "Run project."
  (interactive)
  (message "run"))

(defun modern-sh-banner-default ()
  "Modern shell banner."
  "
       _                   _       _
      | |                 (_)     | |
   ___| |__  ___  ___ _ __ _ _ __ | |_
  / __| '_ \\/ __|/ __| '__| | '_ \\| __|
  \\__ \\ | | \\__ \\ (__| |  | | |_) | |_
  |___/_| |_|___/\\___|_|  |_| .__/ \\__|
                            | |
                            |_|
")

(defhydra modern-sh-hydra-menu
  (:color blue
    :hint none)
  "
%s(modern-sh-banner-default)
  Project     |  _b_: Build     _r_: Run
  _q_: Quit"                            ;
  ("b" modern-sh-project-build "Build")
  ("r" modern-sh-project-run "Run")
  ("q" nil "Quit"))

(defun modern-sh-menu ()
  "Open Modern shell hydra menu."
  (interactive)
  (modern-sh-hydra-menu/body))

(defun modern-sh-add-keywords
  (&optional
    mode)
  "Install keywords into major MODE, or into current buffer if nil."
  (font-lock-add-keywords
    mode
    modern-sh-font-lock-keywords))

(defun modern-sh-remove-keywords
  (&optional
    mode)
  "Remove keywords from major MODE, or from current buffer if nil."
  (font-lock-remove-keywords mode modern-sh-font-lock-keywords))

(defun modern-sh-build-tags ()
  "Build tags for current project."
  (interactive)
  (let ((tags-buffer (get-buffer "TAGS"))
         (tags-buffer2 (get-buffer (format "TAGS<%s>"
                                     (modern-sh-project-name)))))
    (if tags-buffer ;;
      (kill-buffer tags-buffer))
    (if tags-buffer2 ;;
      (kill-buffer tags-buffer2)))
  (let* ((oldir default-directory)
          (ctags-params (concat "ctags -e -R . ")))
    (setq default-directory (modern-sh-project-root))
    (message "ctags:%s" (shell-command-to-string ctags-params))
    (modern-sh-load-tags)
    (setq default-directory oldir)))

(defun modern-sh-load-tags
  (&optional
    build)
  "Visit tags table.
Optional argument BUILD If the tags file does not exist, execute the build."
  (interactive)
  (let* ((tags-file (concat (modern-sh-project-root) "TAGS")))
    (if (file-exists-p tags-file)
      (progn (visit-tags-table (concat (modern-sh-project-root) "TAGS")))
      (if build (modern-sh-build-tags)))))

(defun modern-sh-after-save-hook ()
  "After save hook."
  (when (eq major-mode 'sh-mode)
    (modern-sh-format-buffer)
    (if (not (executable-find "ctags"))
      (message "Could not locate executable '%s'" "ctags")
      (modern-sh-build-tags))))

(defun modern-sh-format-buffer ()
  "Format current buffer."
  (interactive)
  (indent-region (point-min)
    (point-max)))

;;;###autoload
(define-minor-mode modern-sh-mode ;;
  "Minor mode for editing shell script."
  :init-value nil
  :lighter " modern-sh"
  :group 'modern-sh
  ;; "declare" "typeset" "set"
  (setq-local imenu-generic-expression  ;
    '(("TODO" ".*TODO:[ \t]*\\(.*\\)$" 1)
       ("function"
         "^\\(function[ \t]*\\)?\\([A-Za-z0-9_-]+\\)[ \t]*\\((.*)\\)[ \t{]*" 2)
       ("variable"
         "^[ \t]*\\(declare\\|typeset\\|set\\)[ \t]+\\([A-Za-z0-9_-]+\\)" 2)
       ("unset" "unset[ \t]+\\([A-Za-z0-9_-]+\\)" 1)
       ("export" "export[ \t]+\\([A-Za-z0-9_-]+\\)[ \t]*=" 1)
       ("readonly" "readonly[ \t]+\\([A-Za-z0-9_-]+\\)[ \t]*=" 1)
       ("eval" "^[ \t]*\\(eval\\|source\\|\\.\\)[ \t]+\\(.*\\)$" 2)
       ("exit" "[ \t]*\\(exit[ \t]+.*\\)$" 1)))
  ;;
  (if modern-sh-mode                    ;
    (progn                              ;
      (modern-sh-add-keywords)
      (imenu-add-to-menubar "Index")
      (substitute-key-definition #'sh-for nil sh-mode-map)
      (define-key sh-mode-map (kbd "C-c C-f") #'modern-sh-format-buffer)
      (define-key sh-mode-map (kbd "C-x C-e") #'eir-eval-in-shell)
      (add-hook 'after-save-hook #'modern-sh-after-save-hook nil t)
      (modern-sh-load-tags))
    (progn                              ;
      (modern-sh-remove-keywords)
      (imenu--cleanup)
      (substitute-key-definition #'modern-sh-format-buffer nil sh-mode-map)
      (substitute-key-definition #'eir-eval-in-shell nil sh-mode-map)
      (define-key sh-mode-map (kbd "C-c C-f") #'sh-for)
      (remove-hook 'after-save-hook #'modern-sh-after-save-hook)))
  ;;
  (font-lock-flush))

(provide 'modern-sh)

;;; modern-sh.el ends here
