;;; flycheck-eldev.el --- Eldev support in Flycheck  -*- lexical-binding: t -*-

;;; Copyright (C) 2020 Paul Pogonyshev

;; Author:     Paul Pogonyshev <pogonyshev@gmail.com>
;; Maintainer: Paul Pogonyshev <pogonyshev@gmail.com>
;; Version:    1.1.1snapshot
;; Package-Version: 20210305.2231
;; Package-Commit: 2ed17db874da51fba3d2991a1e05cf375fca9619
;; Keywords:   tools, convenience
;; Homepage:   https://github.com/flycheck/flycheck-eldev
;; Package-Requires: ((flycheck "32") (dash "2.17") (emacs "24.4"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see https://www.gnu.org/licenses.

;;; Commentary:

;; Add Eldev support to Flycheck.
;;
;; For a project to be detected, it must contain file `Eldev' or
;; `Eldev-local' in its root directory, even if Eldev doesn’t strictly
;; require that.
;;
;; Features:
;;
;; * No additional steps to be performed from the command line, not
;;   even `eldev prepare'.  However, you might need to mark the
;;   project as trusted, use M-x customize-group flycheck-eldev RET.
;;
;; * Project dependencies are seen by Flycheck in Emacs.  Similarly,
;;   if a package is not declared as a dependency of your project,
;;   Flycheck will complain about unimportable features or undeclared
;;   functions.
;;
;; * Everything is done on-the-fly.  As you edit your project’s
;;   dependency list in its main `.el' file, added, removed or
;;   mistyped dependency names immediately become available to
;;   Flycheck (there might be some delays due to network, as Eldev
;;   needs to fetch them first).
;;
;; * Additional test dependencies (see `eldev-add-extra-dependencies')
;;   are seen from the test files, but not from the main files.
;;
;; For the extension to have any effect, you need to install Eldev:
;;
;;     https://github.com/doublep/eldev#installation
;;
;; If Flycheck doesn’t seem to recognize dependencies declared in a
;; project, verify its setup (`C-c !  v').

;;; Code:

(eval-and-compile
  (require 'flycheck)
  (require 'dash))

;; Compatibility.
(eval-and-compile
  (defalias 'flycheck-eldev--format-message
    (if (fboundp 'format-message) #'format-message #'format)))


(defgroup flycheck-eldev nil
  "Eldev support for Flycheck."
  :prefix "flycheck-eldev-"
  :group  'flycheck
  :link   '(url-link :tag "GitHub" "https://github.com/flycheck/flycheck-eldev"))

(defcustom flycheck-eldev-whitelist nil
  "Projects in these directories are trusted and checking is enabled.

Subdirectories are also included.  If a project is both
whitelisted and blacklisted through its parent directories,
closer parent wins (e.g. `~/foo' wins over `~' for a project in
`~/foo/bar').

Both Eldev and Flycheck itself on Elisp files are dangerous when
run on untrusted code, because they can cause evaluation of
arbitrary Elisp expressions.  Eldev — when loading files `Eldev'
and `Eldev-local', Flycheck — when checking via byte-compiling
(see e.g. `eval-when-compile', `eval-and-compile' forms).  For
this reason, `flycheck-eldev' enables checking only in trusted
projects."
  :group 'flycheck-eldev
  :type  '(repeat directory))

(defcustom flycheck-eldev-blacklist nil
  "Projects in these directories are not trusted and never checked.
Subdirectories are also included.

See `flycheck-eldev-whitelist' for more information about safety
concerns when checking Eldev (or any Elisp) projects."
  :group 'flycheck-eldev
  :type  '(repeat directory))

(defcustom flycheck-eldev-unknown-projects 'trust-if-ever-initialized
  "How to handle projects that are neither white- nor blacklisted.

Value must be a symbol: `trust', `dont-trust' or
`trust-if-ever-initialized' (the default).  The last value means
that a project is trusted if Eldev has ever been run in its
directory (at least since the last `eldev clean .eldev').  The
idea is that if you have knowingly run Eldev on the project
before, you have already evaluated security risks and thus trust
the code.

See `flycheck-eldev-whitelist' for more information about safety
concerns when checking Eldev (or any Elisp) projects."
  :group 'flycheck-eldev
  :type  '(choice (const :tag "Trust" trust)
                  (const :tag "Don't trust" dont-trust)
                  (const :tag "Trust if ever initialized" trust-if-ever-initialized)))


(defvar flycheck-eldev-active t
  "Whether Eldev extension to Flycheck is active.")

(defvar flycheck-eldev-general-error
  "Eldev cannot be initialized; check dependency declarations and file `Eldev'"
  "Error shown when Eldev cannot be initialized.")

(defvar flycheck-eldev-project-is-not-trusted-error
  "This project is not trusted and therefore checking is disabled.

Type M-x customize-group flycheck-eldev RET to change this.")

(defvar flycheck-eldev--byte-compilation-start-mark "--8<-- FLYCHECK BYTE-COMPILATION --8<--")

(defvar flycheck-eldev--required-eldev-version "0.5")


(defun flycheck-eldev-find-root (&optional from)
  "Get Eldev project root or nil, if not inside one.
If FROM is nil, search from `default-directory'."
  (-when-let (root (locate-dominating-file
                    (or from default-directory)
                    (lambda (dir) (or (file-exists-p (expand-file-name "Eldev" dir))
                                      (file-exists-p (expand-file-name "Eldev-local" dir))))))
    (expand-file-name root)))

(defun flycheck-eldev-project-trusted-p (project-dir)
  "Determine if the project in given directory can be trusted."
  (car (flycheck-eldev--project-trust project-dir)))

(defun flycheck-eldev--project-trust (project-dir)
  (let ((trusted-dirs   (--filter (file-in-directory-p project-dir it) flycheck-eldev-whitelist))
        (untrusted-dirs (--filter (file-in-directory-p project-dir it) flycheck-eldev-blacklist))
        most-specific)
    (dolist (dir (append trusted-dirs untrusted-dirs nil))
      (unless (and most-specific (file-in-directory-p most-specific dir))
        (setf most-specific dir)))
    (if most-specific
        (let ((trusted (not (member most-specific untrusted-dirs))))
          `(,trusted . ,(flycheck-eldev--format-message (if trusted "`%s' is whitelisted" "`%s' is blacklisted") most-specific)))
      (pcase flycheck-eldev-unknown-projects
        (`trust                     '(t . "trusted by default"))
        (`trust-if-ever-initialized (if (file-exists-p (expand-file-name ".eldev/ever-initialized" project-dir))
                                        '(t . "externally initialized")
                                      '(nil . "apparently never initialized")))
        ;; Handle everything else as `dont-trust'.
        (_                          '(nil . "not trusted by default"))))))


(defun flycheck-eldev--verify (&rest _)
  (or (unless flycheck-eldev-active
        `(,(flycheck-verification-result-new
            :label "status" :message "Deactivated (see `flycheck-eldev-active')" :face '(bold warning))))
      (let* ((root  (flycheck-eldev-find-root))
             (trust (when root (flycheck-eldev--project-trust root))))
        `(,(flycheck-verification-result-new
            :label   "project root"
            :message (if root (abbreviate-file-name (directory-file-name root)) "[not detected]")
            :face    (if root 'success '(bold warning)))
          ,@(when root
              `(,(flycheck-verification-result-new
                  :label   "trusted"
                  :message (format "%s (%s)" (if (car trust) "yes" "no") (cdr trust))
                  :face    (if (car trust) 'success '(bold warning)))))))))

(defun flycheck-eldev--enabled-p (&rest arguments)
  (let ((super (flycheck-checker-get 'emacs-lisp 'enabled)))
    (or (null super) (apply super arguments))))

(defun flycheck-eldev--predicate (&rest arguments)
  (and flycheck-eldev-active
       (flycheck-eldev-find-root)
       (let ((super (flycheck-checker-get 'emacs-lisp 'predicate)))
         (or (null super) (apply super arguments)))))

(defun flycheck-eldev--working-directory (&rest _)
  (flycheck-eldev-find-root))

(defun flycheck-eldev--build-command-line ()
  `("--quiet" "--no-time" "--color=never" "--no-debug" "--no-backtrace-on-abort"
    ,@(if (flycheck-eldev-project-trusted-p default-directory)
          ;; If the standard Emacs Lisp checker provides a command line we don't expect,
          ;; throw it away and replace with one based on Flycheck 32.  Otherwise we
          ;; rewrite the command line provided by the standard checker, so we get any
          ;; future improvements for free.
          (let* ((super         (let ((flycheck-emacs-lisp-load-path           nil)
                                      (flycheck-emacs-lisp-initialize-packages nil))
                                  (flycheck-checker-substituted-arguments 'emacs-lisp)))
                 (head          (-drop-last 2 super))
                 (tail          (-take-last 2 super))
                 (filename      (cadr tail))
                 (real-filename (buffer-file-name))
                 eval-forms)
            (while head
              (when (string= (pop head) "--eval")
                (if (string-match-p (rx "(" (or "setq" "setf") " package-user-dir") (car head))
                    ;; Just discard, Eldev will take care of this.  Binding
                    ;; `flycheck-emacs-lisp-package-user-dir' to nil would not be enough.
                    (pop head)
                  (push (pop head) eval-forms))))
            (unless (and (string= (car tail) "--")
                         (--any (string-match-p (rx "(byte-compile") it) eval-forms)
                         (--any (string-match-p (rx "command-line-args-left") it) eval-forms))
              ;; If the command line is something we don't expect, use a failsafe.
              (setf eval-forms `(,(flycheck-emacs-lisp-bytecomp-config-form) ,flycheck-emacs-lisp-check-form)))
            ;; Explicitly specify various options in case a user has different defaults.
            `("--as-is" "--load-newer"
              ;; Don't load file `Eldev' or `Eldev-local' if we are checking it.
              ,@(cond ((file-equal-p real-filename "Eldev")
                       `("--setup-first" ,(flycheck-sexp-to-string '(setf eldev-skip-project-config t))))
                      ((file-equal-p real-filename "Eldev-local")
                       `("--setup-first" ,(flycheck-sexp-to-string '(setf eldev-skip-local-project-config t)))))
              ;; Ignore the original file for project initialization purposes.  If
              ;; `eldev-project-main-file' is specified, this does nothing.
              "--setup-first"
              ,(flycheck-sexp-to-string
                `(advice-add #'eldev--package-dir-info :around
                             (lambda (original)
                               (eldev-advised
                                (#'insert-file-contents
                                 :around (lambda (original filename &rest arguments)
                                           (unless (file-equal-p filename ,real-filename)
                                             (apply original filename arguments))))
                                (funcall original)))))
              ;; When checking project's main file, use the temporary as the main file
              ;; instead.
              "--setup"
              ,(flycheck-sexp-to-string
                `(when (and eldev-project-main-file (file-equal-p eldev-project-main-file ,real-filename))
                   (setf eldev-project-main-file ,filename)))
              ;; Special handling for test files: load extra dependencies as if testing
              ;; now.  Likewise for loading roots.
              "--setup"
              ,(flycheck-sexp-to-string
                `(when (eldev-filter-files '(,real-filename) eldev-test-fileset)
                   (apply #'eldev-add-extra-dependencies 'exec (cdr (assq 'test eldev--extra-dependencies)))
                   (apply #'eldev-add-loading-roots 'exec (cdr (assq 'test eldev--loading-roots)))))
              "exec" "--load" "--dont-require" "--lexical"
              ,(flycheck-sexp-to-string `(eldev-output ,flycheck-eldev--byte-compilation-start-mark))
              ,(flycheck-sexp-to-string `(setf command-line-args-left (list "--" ,filename)))
              ,@(nreverse eval-forms)))
        `("--setup-first"
          ,(flycheck-sexp-to-string
            `(signal 'eldev-error '(,flycheck-eldev-project-is-not-trusted-error)))))))

(defun flycheck-eldev--parse-errors (output _checker buffer &rest _)
  (or (flycheck-parse-output output 'emacs-lisp buffer)
      ;; Only if there are no errors from Emacs byte-compilation.
      (unless (string-match-p (regexp-quote flycheck-eldev--byte-compilation-start-mark) output)
        (if (flycheck-eldev--eldev-new-enough-p)
            (let ((message (string-trim output)))
              ;; Don't add clarification to a few obvious errors.
              (unless (or (string-match-p (rx bos "Dependency " (1+ any) " is not available") message)
                          (string-match-p (regexp-quote flycheck-eldev-project-is-not-trusted-error) message))
                (setf message (concat message "\n\n" flycheck-eldev-general-error)))
              `(,(flycheck-eldev--create-fake-error buffer message)))
          `(,(flycheck-eldev--create-fake-error buffer (flycheck-eldev--format-message "Eldev %s is required; please run `eldev upgrade-self'"
                                                                                       flycheck-eldev--required-eldev-version)))))))

(defun flycheck-eldev--eldev-new-enough-p ()
  ;; Might want to cache at some point.  On the other hand, it's not clear how to
  ;; invalidate the cache to avoid false errors when Eldev is upgraded.
  (ignore-errors
    (with-temp-buffer
      (and (= (call-process "eldev" nil t nil "--quiet" "--setup-first" (flycheck-sexp-to-string `(setf eldev-skip-project-config t)) "version") 0)
           (version<= flycheck-eldev--required-eldev-version (string-trim (buffer-string)))))))

(defun flycheck-eldev--create-fake-error (buffer message &optional level)
  (flycheck-error-new-at 1 1 (or level 'error) message
                         :end-column (with-current-buffer buffer
                                       (save-excursion
                                         (save-restriction
                                           (widen)
                                           (goto-char 1)
                                           (end-of-line)
                                           (point))))
                         :checker    'elisp-eldev
                         :buffer     buffer))

(defun flycheck-eldev--filter-errors (errors &rest _)
  ;; Don't filter our own errors.
  (if (and errors (eq (flycheck-error-checker (car errors)) 'elisp-eldev))
      errors
    (flycheck-filter-errors errors 'emacs-lisp)))


(defvar flycheck-eldev--original-emacs-lisp-enabled-p nil)

;; Easier to hack than to wait for https://github.com/flycheck/flycheck/pull/1832 to be
;; "reviewed".  Disable `checkdoc' on Eldev files, it makes zero sense there.
(defun flycheck-eldev--emacs-lisp-checkdoc-enabled-p ()
  "Check whether to enable Emacs Lisp Checkdoc in the current buffer."
  (and (funcall flycheck-eldev--original-emacs-lisp-enabled-p)
       ;; These files are valid Lisp, but don't contain "standard" comments.
       (not (member (file-name-base (or (buffer-file-name) "-")) '("Eldev" "Eldev-local")))))


;;;###autoload
(defun flycheck-eldev--initialize ()
  (add-to-list 'flycheck-checkers 'elisp-eldev)
  (flycheck-define-checker elisp-eldev
    "An Emacs Lisp syntax checker for files in Eldev projects.

This is based on the standard built-in Emacs Lisp checker.  This
checker differs in that it uses dependencies declared in Eldev
projects to build `load-path' and initialize the package manager.

See Info Node `(elisp)Byte Compilation'."
    :verify            flycheck-eldev--verify
    :modes             emacs-lisp-mode
    :enabled           flycheck-eldev--enabled-p
    :predicate         flycheck-eldev--predicate
    :working-directory flycheck-eldev--working-directory
    :command           ("eldev" (eval (flycheck-eldev--build-command-line)))
    :error-parser      flycheck-eldev--parse-errors
    :error-filter      flycheck-eldev--filter-errors
    :next-checkers     (emacs-lisp-checkdoc))
  ;; Hack: Eldev is run from the project root, but Emacs reports syntax errors without a
  ;; path.  Therefore, we reset directory from the root to where the file is actually
  ;; contained after the process is started.
  ;;
  ;; See also https://github.com/flycheck/flycheck/issues/1785
  (let ((real-start (flycheck-checker-get 'elisp-eldev 'start)))
    (setf (flycheck-checker-get 'elisp-eldev 'start)
          (lambda (&rest arguments)
            (let ((process (apply real-start arguments)))
              (when (processp process)
                (process-put process 'flycheck-working-directory (file-name-directory (buffer-file-name))))
              process))))
  ;; I don't think we need a separate package just for this, so let's do it here.
  (add-to-list 'auto-mode-alist `(,(rx "/" (or "Eldev" "Eldev-local") eos) . emacs-lisp-mode) t)
  ;; Hack in disabling of `checkdoc' on Eldev files.
  (unless flycheck-eldev--original-emacs-lisp-enabled-p
    (setf flycheck-eldev--original-emacs-lisp-enabled-p        (flycheck-checker-get 'emacs-lisp-checkdoc 'enabled)
          (flycheck-checker-get 'emacs-lisp-checkdoc 'enabled) #'flycheck-eldev--emacs-lisp-checkdoc-enabled-p)))


;;;###autoload
(eval-after-load 'flycheck '(flycheck-eldev--initialize))


(provide 'flycheck-eldev)

;;; flycheck-eldev.el ends here
