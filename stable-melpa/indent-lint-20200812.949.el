;;; indent-lint.el --- Async indentation checker  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.1.4
;; Package-Version: 20200812.949
;; Package-Commit: c55f4ded11e8e50a96f43675a071354a8fb501c3
;; Keywords: tools
;; Package-Requires: ((emacs "25.1") (async-await "1.0") (async "1.9.4"))
;; URL: https://github.com/conao3/indent-lint.el

;; This program is free software: you can redistribute it and/or modify
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

;; Indentation checker


;;; Code:

(require 'seq)
(require 'async-await)

(defgroup indent-lint nil
  "Asynchronous indentation checker"
  :prefix "indent-lint-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/indent-lint.el"))

(defcustom indent-lint-before-indent-fn #'ignore
  "The function to eval before indent.
Function will be called with 2 variables; `(,raw-buffer ,indent-buffer)."
  :group 'indent-lint
  :type 'function)

(defcustom indent-lint-popup t
  "If non-nil, popup diff buffer."
  :group 'indent-lint
  :type 'boolean)

(defcustom indent-lint-verbose t
  "If non-nil, output diff verbose."
  :group 'indent-lint
  :type 'boolean)

(defcustom indent-lint-debug nil
  "If non-nil, show debug information."
  :group 'indent-lint-batch
  :type 'number)

(defcustom indent-lint-batch-timeout 10
  "Timeout for `indent-lint-batch' in sec."
  :group 'indent-lint
  :type 'number)


;;; hooks

(defun indent-lint--before-indent-emacs-lisp-mode ()
  "Before-Indent function before indnet buffer at `emacs-lisp-mode'."
  (ignore-errors
    (eval-buffer)))


;;; funcitons

(defun indent-lint--output-debug-info (state err)
  "Output debug info form ERR with STATE."
  (let ((file (locate-user-emacs-file "flycheck-indent.debug")))
    (with-temp-file file
      (erase-buffer)
      (insert (format "Error at %s\n" (format-time-string "%Y-%m-%d %H:%M")))
      (insert (format "Error (%s): %s\n" (pp-to-string state) (pp-to-string err)))
      (insert "\n")
      (insert (with-output-to-string
                (backtrace))))
    (message (format "Indent-lint exit with errors. See %s" file))))

(defun indent-lint--buffer-local-variable (buf)
  "Return buffer-local variable alist in BUF."
  (let ((local (mapcan
                (lambda (elm)
                  (let* ((key (car elm))
                         (value (cdr elm))
                         (keyname (symbol-name key)))
                    (condition-case err
                        (let ((print-level nil)
                              (print-length nil)
                              (print-quoted t)
                              (print-circle t)
                              (print-escape-nonascii t))
                          (read (prin1-to-string value))
                          (if (and
                               (or
                                ;; after-save-hook etc
                                (string-match "hook" keyname)
                                ;; before-change-functions etc
                                (string-match "functions?" keyname))
                               ;; not indent-region-function etc
                               (not (string-match "indent" keyname)))
                              (prog1 nil
                                (when indent-lint-debug
                                  (warn "Filter variable: %s, %s"
                                        key (prin1-to-string value))))
                            (list (cons key value))))
                      (error
                       (prog1 nil
                         (when indent-lint-debug
                           (warn "Could not read: %s, %s" key err)))))))
                (with-current-buffer buf (buffer-local-variables)))))
    (when indent-lint-debug
      (warn (format "Import variables: %s" (prin1-to-string local))))
    local))

(defun indent-lint--promise-indent (buf src-file dest-file)
  "Return promise to save BUF to SRC-FILE and save DEST-FILE indented."
  (with-current-buffer buf
    (let ((mode major-mode)
          (contents (buffer-string)))
      (with-temp-file src-file
        (insert contents))
      (promise-then
       (promise:async-start
        `(lambda ()
           (progn
             (setq user-emacs-directory ,user-emacs-directory)
             (setq package-user-dir ,package-user-dir)
             (package-initialize)
             (with-temp-file ,dest-file
               (insert-file-contents ,src-file)
               (funcall #',mode)
               (dolist (cell ',(indent-lint--buffer-local-variable buf))
                 (condition-case _err
                     (set (car cell) (cdr cell))
                   (setting-constant nil)))
               ,(when-let (fn (symbol-function
                               (intern (format "indent-lint--before-indent-%s" mode))))
                  `(funcall #',fn))
               (indent-region (point-min) (point-max))))))
       (lambda (res)
         (promise-resolve res))
       (lambda (reason)
         (promise-reject `(fail-indent ,reason)))))))

(defun indent-lint--promise-diff (buf src-file dest-file)
  "Return promise to diff SRC-FILE and DEST-FILE named BUF."
  (let ((exitcode (lambda (str)
                    (when (stringp str)
                      (let ((reg "exited abnormally with code \\([[:digit:]]*\\)\n"))
                        (if (string-match reg str)
                            (string-to-number (match-string 1 str))
                          nil))))))
    (promise-then
     (promise:make-process
      shell-file-name
      shell-command-switch
      (mapconcat
       #'shell-quote-argument
       `("diff"
         "--old-line-format"
         ,(if indent-lint-verbose
              (format "%s:%%dn: warning: Indent mismatch\n-%%L" (buffer-name buf))
            (format "%s:%%dn: warning: Indent mismatch\n" (buffer-name buf)))
         "--new-line-format" ,(if indent-lint-verbose "+%L" "")
         "--unchanged-line-format" ""
         ,src-file
         ,dest-file)
       " "))
     (lambda (res)
       (seq-let (stdin stdout) res
         (let ((code 0)
               (output (concat stdin stdout)))
           (promise-resolve `(,code ,output)))))
     (lambda (res)
       (seq-let (msg stdin stdout) res
         (let ((code (funcall exitcode msg))
               (output (concat stdin stdout)))
           (cond
            ((eq code 1)
             (promise-resolve `(,code ,output)))
            ((eq code 2)
             (promise-reject `(fail-diff ,code ,output)))
            (t
             (promise-reject `(fail-diff-unknown ,code ,output))))))))))


;;; main

;;;###autoload
(async-defun indent-lint (&optional buf)
  "Indent BUF in clean Emacs and lint async."
  (interactive)
  (let ((buf* (get-buffer (or buf (current-buffer))))
        (output-buf (generate-new-buffer "*indent-lint*"))
        (src-file   (make-temp-file "emacs-indent-lint"))
        (dest-file  (make-temp-file "emacs-indent-lint")))
    (condition-case err
        (let* ((_res (await (indent-lint--promise-indent buf* src-file dest-file)))
               (res  (await (indent-lint--promise-diff buf* src-file dest-file))))
          (ignore-errors
            (delete-file src-file)
            (delete-file dest-file))
          (with-current-buffer output-buf
            (seq-let (code output) res
              (insert output)
              (insert
               (format "\nDiff finished%s.  %s\n"
                       (cond ((equal 0 code) " (no differences)")
                             ((equal 1 code) " (has differences)")
                             ((equal 2 code) " (diff error)")
                             (t (format "(unknown exit code: %d)" code)))
                       (current-time-string)))
              (special-mode)
              (diff-mode)
              (when indent-lint-popup
                (display-buffer output-buf))
              `(,code ,output-buf))))
      (error
       (pcase err
         (`(error (fail-indent ,reason))
          (warn "Fail indent in clean Emacs
  buffer: %s\n  major-mode: %s\n  src-file: %s\n  dest-file: %s\n  reason: %s"
                (prin1-to-string buf*)
                (with-current-buffer buf* major-mode)
                src-file dest-file
                (prin1-to-string reason))
          `(3 nil))

         (`(error (fail-diff ,code ,output))
          (warn "Fail diff.
  buffer: %s\n  src-file: %s\n  dest-file: %s\n  reason: %s"
                (prin1-to-string buf*)
                src-file dest-file output)
          `(,code ,(with-current-buffer output-buf
                     (insert output)
                     output-buf)))

         (`(error (fail-diff-unknown ,code ,output))
          (warn "Fail diff unknown.
  buffer: %s\n  src-file: %s\n  dest-file: %s\n  reason: %s"
                (prin1-to-string buf*)
                src-file dest-file output)
          `(,code ,(with-current-buffer output-buf
                     (insert output)
                     output-buf))))))))

;;;###autoload
(defun indent-lint-file (filepath)
  "Return promise to run `indent-lint' for FILEPATH."
  (if (not (file-readable-p filepath))
      (promise-reject `(fail-file-readable ,filepath))
    (let ((buf (find-file-noselect filepath)))
      (indent-lint buf))))

(defun indent-lint-batch ()
  "Run `indent-lint--sync' and output diff to standard output.
Use this only with --batch, it won't work interactively.

Status code:
  0 - No indentation errors and no output
  1 - Found indentation errors and diff output
  2 - Diff program exit with errors
  3 - Error when create indent file in clean Emacs
  100 - Timeout while invoke indent-lint

Usage:
  - Import code from file and guess `major-mode' from file extension.
      cask {EMACS} -Q --batch -l indent-lint.el -f indent-lint-batch sample.el

  - Lint multi file is supported.
      cask {EMACS} -Q --batch -l indent-lint.el -f indent-lint-batch sample1.el sample2.el"
  (unless noninteractive
    (error "`indent-lint-batch' can be used only with --batch"))
  (require 'package)
  (let ((indent-lint-verbose nil)
        (indent-lint-popup nil)
        (exitcode 0))
    (dolist (filepath command-line-args-left)
      (let* ((buf (find-file-noselect filepath 'nowarn))
             (res (_value (promise-wait indent-lint-batch-timeout
                            (indent-lint buf)))))
        (seq-let (state value) res
          (cond
           ((eq :fullfilled state)
            (seq-let (code buf) value
              (princ (with-current-buffer buf
                       (let ((inhibit-read-only t))
                         (goto-char (point-max))
                         (delete-region (line-beginning-position -1) (point))
                         (buffer-string))))
              (unless (= code 0)
                (setq exitcode code))))
           ((eq :rejected state)
            (indent-lint--output-debug-info :rejected value)
            (setq exitcode (car value)))
           ((eq :timeouted state)
            (indent-lint--output-debug-info :timeouted value)
            (setq exitcode 100))))))
    (kill-emacs exitcode)))

(provide 'indent-lint)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; indent-lint.el ends here
