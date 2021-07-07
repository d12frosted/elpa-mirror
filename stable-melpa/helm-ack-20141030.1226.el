;;; helm-ack.el --- Ack command with helm interface -*- lexical-binding: t; -*-

;; Copyright (C) 2014 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-helm-ack
;; Package-Version: 20141030.1226
;; Package-Commit: 889bc225318d14c6e3be80e73b1d9d6fb30e48c3
;; Version: 0.13
;; Package-Requires: ((helm "1.0") (cl-lib "0.5"))

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

;;; Code:

(require 'cl-lib)

(require 'helm)

(defgroup helm-ack nil
  "Ack command with helm interface"
  :group 'helm)

(defcustom helm-ack-use-ack-grep nil
  "Use ack-grep command"
  :type 'boolean
  :group 'helm-ack)

(defcustom helm-ack-base-command "ack -H --nocolor --nogroup"
  "Base command of `ack'"
  :type 'string
  :group 'helm-ack)

(defcustom helm-ack-auto-set-filetype t
  "Setting file type automatically"
  :type 'boolean
  :group 'helm-ack)

(defcustom helm-ack-version nil
  "ack version"
  :type 'integer
  :group 'helm-ack)

(defcustom helm-ack-insert-at-point 'word
  "Insert thing at point as search pattern.
   You can set value same as `thing-at-point'"
  :type 'symbol
  :group 'helm-ack)

(defvaralias 'helm-c-ack-use-ack-grep 'helm-ack-use-ack-grep)
(make-obsolete-variable 'helm-c-ack-use-ack-grep 'helm-ack-use-ack-grep "0.10")

(defvaralias 'helm-c-ack-base-command 'helm-ack-base-command)
(make-obsolete-variable 'helm-c-ack-base-command 'helm-ack-base-command "0.10")

(defvaralias 'helm-c-ack-auto-set-filetype 'helm-ack-auto-set-filetype)
(make-obsolete-variable 'helm-c-ack-auto-set-filetype 'helm-ack-auto-set-filetype "0.10")

(defvaralias 'helm-c-ack-version 'helm-ack-version)
(make-obsolete-variable 'helm-c-ack-version 'helm-ack-version "0.10")

(defvaralias 'helm-c-ack-insert-at-point 'helm-ack-insert-at-point)
(make-obsolete-variable 'helm-c-ack-insert-at-point 'helm-ack-insert-at-point "0.10")

(defvar helm-ack--context-stack nil
  "Stack for returning the point before jump")
(defvar helm-ack--last-query)
(defvar helm-ack--base-directory)

(defun helm-ack--mode-to-type (mode)
  (cl-case mode
    (actionscript-mode "ack")
    (ada-mode "ada")
    (asm-mode "asm")
    (batch-mode "batch")
    (c-mode "cc")
    (clojure-mode "clojure")
    (c++-mode "cpp")
    (csharp-mode "csharp")
    (css-mode "css")
    (emacs-lisp-mode "elisp")
    (erlang-mode "erlang")
    ((fortan-mode f90-mode) "fortran")
    (go-mode "go")
    (groovy-mode "groovy")
    (haskell-mode "haskell")
    (html-mode "html")
    (java-mode "java")
    ((javascript-mode js-mode js2-mode) "js")
    (lisp-mode "lisp")
    (lua-mode "lua")
    (makefile-mode "make")
    (objc-mode "objc")
    ((ocaml-mode tuareg-mode) "ocaml")
    ((perl-mode cperl-mode) "perl")
    (php-mode "php")
    (python-mode "python")
    (ruby-mode "ruby")
    (scala-mode "scala")
    (scheme-mode "scheme")
    (shell-script-mode "shell")
    (sql-mode "sql")
    (tcl-mode "tcl")
    ((tex-mode latex-mode yatex-mode) "tex")))

(defsubst helm-ack--all-type-option ()
  (if (= helm-ack-version 1)
      "--all"
    ""))

(defun helm-ack--type-option ()
  (let ((type (helm-ack--mode-to-type major-mode)))
    (if type
        (format "--type=%s" type)
      (helm-ack--all-type-option))))

(defun helm-ack--thing-at-point ()
  (let ((str (thing-at-point helm-ack-insert-at-point)))
    (if (and str (cl-typep str 'string))
        (substring-no-properties str)
      "")))

(defun helm-ack--default-pattern ()
  (if (null helm-ack-insert-at-point)
      ""
    (helm-ack--thing-at-point)))

(defun helm-ack--base-command ()
  (format "%s %s %s"
          (if helm-ack-use-ack-grep
              (replace-regexp-in-string "\\`ack" "ack-grep" helm-ack-base-command)
            helm-ack-base-command)
          (or (and helm-ack-auto-set-filetype (helm-ack--type-option)) "")
          (helm-ack--default-pattern)))

(defun helm-ack--save-current-context ()
  (let ((file (buffer-file-name helm-current-buffer))
        (curpoint (with-current-buffer helm-current-buffer
                    (point))))
    (push `((file  . ,file)
            (buffer . ,helm-current-buffer)
            (point . ,curpoint)) helm-ack--context-stack)))

;;;###autoload
(defun helm-ack-pop-stack ()
  (interactive)
  (let ((context (pop helm-ack--context-stack)))
    (unless context
      (error "Context stack is empty!!"))
    (helm-aif (assoc-default 'file context)
        (find-file it)
      (let ((buf (assoc-default 'buffer context)))
        (unless (buffer-live-p buf)
          (error "the buffer is already killed"))
        (switch-to-buffer buf)))
    (goto-char (assoc-default 'point context))))

(defvar helm-ack--command-stack nil
  "Command history stack for helm-ack")

(defun helm-ack--placeholders ()
  (cond ((buffer-file-name) `(("\\$\\$" . ,(file-name-nondirectory
                                            (buffer-file-name)))))
        (dired-directory `(("\\$\\$" . ,dired-directory)))))

(defun helm-ack--fill-placeholder (cmd)
  (cl-loop with replaced = (copy-sequence cmd)
           for (holder . value) in (helm-ack--placeholders)
           do
           (setq replaced (replace-regexp-in-string holder value replaced))
           finally return replaced))

(defun helm-ack--set-version ()
  (let* ((ack-cmd (if helm-ack-use-ack-grep "ack-grep" "ack"))
         (version-cmd (concat ack-cmd " --version"))
         (check-regexp (concat "^" ack-cmd " \\([0-9]+\\)\.[0-9]+")))
    (with-temp-buffer
      (unless (zerop (process-file-shell-command version-cmd nil t))
        (error "Failed: %s --version" ack-cmd))
      (goto-char (point-min))
      (if (re-search-forward check-regexp nil t)
          (setq helm-ack-version (string-to-number (match-string 1)))
        (error "Failed: ack version not found. Please set explicitly")))))

(defun helm-ack--init ()
  (helm-attrset 'recenter t)
  (helm-attrset 'before-jump-hook 'helm-ack--save-current-context)
  (let ((buf-coding buffer-file-coding-system)
        (filled (with-helm-current-buffer
                  (helm-ack--fill-placeholder helm-ack--last-query))))
    (with-current-buffer (helm-candidate-buffer 'global)
      (let* ((default-directory helm-ack--base-directory)
             (coding-system-for-read buf-coding)
             (coding-system-for-write buf-coding)
             (ret (process-file-shell-command filled nil t)))
        (cond ((= ret 1) (error "no match"))
              ((not (= ret 0)) (error "Failed ack")))))))

(defvar helm-ack--source
  '((name .  "Helm Ack")
    (init . helm-ack--init)
    (candidates-in-buffer)
    (type . file-line)
    (candidate-number-limit . 9999)))

(defun helm-ack--query ()
  (setq helm-ack--last-query
        (read-string "Command: " (helm-ack--base-command)
                     'helm-ack--command-stack)))

;;;###autoload
(defun helm-ack (&optional dir)
  (interactive)
  (unless helm-ack-version
    (helm-ack--set-version))
  (setq helm-ack--base-directory
        (or dir (if current-prefix-arg
                    (read-directory-name "Search Directory: ")
                  default-directory)))
  (helm-ack--query)
  (let ((default-directory helm-ack--base-directory))
    (helm :sources '(helm-ack--source) :buffer "*helm ack*")))

(provide 'helm-ack)

;;; helm-ack.el ends here
