;;; counsel-osx-app.el --- launch osx applications via ivy interface
;;
;; Copyright (c) 2016 Boris Buliga
;;
;; Author: Boris Buliga <d12frosted@gmail.com>
;; URL: https://github.com/d12frosted/counsel-osx-app
;; Package-Version: 20160821.809
;; Package-Commit: 5cc93ec684f837dc31ce20e7625407f2c0445691
;; Version: 0.1.0
;; Package-Requires: ((ivy "0.8.0") (emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3
;;
;;; Commentary:
;; This package provides `counsel-osx-app' function which is inspired by
;; `counsel-linux-app'.
;;
;; In order to use `counsel-osx-app' simply call `counsel-osx-app' function.  It
;; will allow you to select an app to launch using ivy completion.  Optionally
;; one can select any file to edit in selected application via ivy actions.
;;
;; By default `counsel-osx-app' searches for applications in "/Applications"
;; directory, but it's configurable via `counsel-osx-app-location' variable.  It can
;; be either string representing root location for all applications or list of
;; such strings.
;;
;; The last configurable thing (but not least) is command for launching
;; application.  Please refer to `counsel-osx-app-launch-cmd' for more information.
;;
;; Although the name of this package is `counsel-osx-app', it's not restricted
;; to OSX only.  One can easily tune it to run under Linux (not sure about
;; Windows).  Just make sure to configure described variables and change
;; implementation of `counsel-osx-app-list' function.  PRs are welcome on making
;; this package cross-platform.
;;
;;; Code:
;;

(require 'ivy)

(defvar counsel-osx-app-location "/Applications"
  "Path (or list of paths) to directories containing applications.")

(defvar counsel-osx-app-pattern "*.app"
  "Pattern for applications in `counsel-osx-app-location'.

Use \"*\" if all files in `counsel-osx-app-location' are considered
applications.")

(defvar counsel-osx-app-launch-cmd
  (lambda (app &optional file)
    (if (bound-and-true-p file)
        (format "open %s -a %s"
                (shell-quote-argument file)
                (shell-quote-argument app))
      (format "open %s" (shell-quote-argument app))))
  "Command for launching application.

Can be either format string or function that accepts path to
application as first argument and filename as optional second
argument and returns command.")

(defun counsel-osx-app-list ()
  "Get the list of applications under `counsel-osx-app-location'."
  (let* ((locs (if (stringp counsel-osx-app-location)
                   `(,counsel-osx-app-location)
                 counsel-osx-app-location))
         (files (mapcar (lambda (path)
                          (file-expand-wildcards
                           (concat path "/" counsel-osx-app-pattern)))
                        locs)))
    (mapcar (lambda (path) (cons (file-name-base path) path))
            (apply #'append files))))

(defun counsel-osx-app-action-default (app)
  "Launch APP using `counsel-osx-app-launch-cmd'."
  (call-process-shell-command
   (cond
    ((stringp counsel-osx-app-launch-cmd)
     (format "%s %s" counsel-osx-app-launch-cmd (shell-quote-argument app)))
    ((functionp counsel-osx-app-launch-cmd)
     (funcall counsel-osx-app-launch-cmd app))
    (t
     (user-error
      "Could not construct cmd from `counsel-osx-app-launch-cmd'")))))

(defun counsel-osx-app-action-file (app)
  "Open file in APP using `counsel-osx-app-launch-cmd'."
  (let* ((short-name (file-name-nondirectory app))
         (file (and short-name
                    (read-file-name
                     (format "Run %s on: " short-name)))))
    (if file
        (call-process-shell-command
         (cond
          ((stringp counsel-osx-app-launch-cmd)
           (format "%s %s %s"
                   counsel-osx-app-launch-cmd
                   (shell-quote-argument app)
                   (shell-quote-argument file)))
          ((functionp counsel-osx-app-launch-cmd)
           (funcall counsel-osx-app-launch-cmd app file))
          (t
           (user-error
            "Could not construct cmd from `counsel-osx-app-launch-cmd'"))))
      (user-error "Cancelled"))))

(defmacro counsel-osx-app--use-cdr (f)
  "Return a function that operates on the cdr of its argument instead."
  `(lambda (cons-cell) (,f (cdr cons-cell))))

(ivy-set-actions
 'counsel-osx-app
 `(("f"
    ,(counsel-osx-app--use-cdr counsel-osx-app-action-file)
    "run on a file")))

;;;###autoload
(defun counsel-osx-app ()
  "Launch an application via ivy interface."
  (interactive)
  (ivy-read "Run application: " (counsel-osx-app-list)
            :action (counsel-osx-app--use-cdr counsel-osx-app-action-default)
            :caller 'counsel-app))

(provide 'counsel-osx-app)

;;; counsel-osx-app.el ends here
