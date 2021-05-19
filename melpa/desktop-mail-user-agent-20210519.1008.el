;;; desktop-mail-user-agent.el --- Call OS default mail program to compose mail -*- lexical-binding: t -*-

;; Copyright 2021 Lassi Kortela
;; SPDX-License-Identifier: ISC
;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-desktop-mail-user-agent
;; Package-Version: 20210519.1008
;; Package-Commit: caac672ef7e4ddced960fa31cef3a6ba5d7ab451
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.3"))
;; Keywords: mail

;; This file is not part of GNU Emacs.

;;; Commentary:

;; If you're running Emacs as a desktop application on the X Window
;; System, MacOS, or Windows, this package launches the desktop
;; environment's default mail app to write mail messages from Emacs.
;; The `compose-mail' command, and other commands using it indirectly,
;; are affected.

;; To install, call `desktop-mail-user-agent`.  It sets
;; `mail-user-agent' and stores the old `mail-user-agent' to use as a
;; fallback for complex mail-sending tasks that require editing the
;; mail message in an Emacs buffer.

;; Currently this package only concerns sending mail.  Reading mail via
;; `read-mail-command' is not affected.

;;; Code:

(require 'url)

(defgroup desktop-mail-user-agent nil
  "Desktop mail user agent"
  :group 'desktop-mail-user-agent)

(defcustom desktop-mail-user-agent-fallback nil
  "Fallback `mail-user-agent' for fancy mail composing.

When `desktop-mail-user-agent' cannot handle a job, it will
delegate the job to this agent."
  :type 'function
  :group 'desktop-mail-user-agent)

(defvar desktop-mail-user-agent--hook nil
  "Internal variable expected by `define-mail-user-agent'.

Never set this; leave it nil.

The documentation for `define-mail-user-agent' says callers that
use our `mail-user-agent' may install a hook function temporarily
on this hook variable.  The hook is supposed to be triggered when
mail is sent, but since we launch an external mail program, we
can't detect when that happens.

That leaves us with no choice except to raise an error when
another package is trying to use a send hook.  We use this
variable as a tripwire to detect such packages.")

(defun desktop-mail-user-agent--assert-no-hook ()
  "Internal function to check that a hook has not been installed."
  (let ((hook desktop-mail-user-agent--hook))
    (when hook
      (setq desktop-mail-user-agent--hook nil)
      (error "An Emacs package is calling `compose-mail' with a hook.

Unfortunately `desktop-mail-user-agent' is not able to support
hooks.  The maintainer of `desktop-mail-user-agent' may have
advice on how to solve the problem with this particular package.

The hook that the package is trying to use is:
%S" hook))))

(defun desktop-mail-user-agent--build-mailto-uri (to subject)
  "Internal function to build a mailto: URI from TO and SUBJECT.

Either TO or SUBJECT can be nil to omit that part of the URI.  If
both are nil, a blank mailto: is returned, which will open the
mail program with a blank message on some desktop environments.

The mailto: URI syntax is specified in RFC 2368."
  (concat "mailto:"
          (if to (url-hexify-string to) "")
          (if subject (concat "?subject=" (url-hexify-string subject)) "")))

(defun desktop-mail-user-agent-x (to subject)
  "Compose mail using the preferred mail client on the X Window System.

TO and SUBJECT are strings or nil."
  (let ((uri (desktop-mail-user-agent--build-mailto-uri to subject)))
    (when (and (or (getenv "DISPLAY")
                   (getenv "WAYLAND_DISPLAY"))
               (executable-find "xdg-open"))
      (call-process "xdg-open" nil 0 nil uri)
      t)))

(defun desktop-mail-user-agent-mac (to subject)
  "Compose mail using the preferred mail client on macOS.

TO and SUBJECT are strings or nil."
  (let ((uri (desktop-mail-user-agent--build-mailto-uri to subject)))
    (when (and (eq system-type 'darwin) (executable-find "open"))
      (start-process (concat "open " uri) nil "open" uri)
      t)))

(defun desktop-mail-user-agent-windows (to subject)
  "Compose mail using the preferred mail client on Windows.

TO and SUBJECT are strings or nil."
  (let ((uri (desktop-mail-user-agent--build-mailto-uri to subject)))
    (cond ((and (eq system-type 'windows-nt) (fboundp 'w32-shell-execute))
           (funcall (symbol-function 'w32-shell-execute) "open" uri)
           t)
          ((eq system-type 'cygwin)
           (call-process "cygstart" nil nil nil uri)
           t)
          (t nil))))

(defvar desktop-mail-user-agent-functions
  '(desktop-mail-user-agent-x
    desktop-mail-user-agent-mac
    desktop-mail-user-agent-windows)
  "List of desktop MUA launch functions to try until one works.

Each function shall return nil if it does not work in this
environment.  If it does work, it shall try to start the MUA and
return non-nil.")

(defun desktop-mail-user-agent--compose-desktop (to subject)
  "Internal function to compose a message using desktop MUA.

Either TO or SUBJECT or both can be nil."
  (let ((funs desktop-mail-user-agent-functions) (ret nil))
    (while (not ret)
      (unless funs (error "No working MUA"))
      (setq ret (funcall (car funs) to subject))
      (setq funs (cdr funs)))))

(defun desktop-mail-user-agent--compose-fallback
    (to
     subject
     other-headers
     continue
     switch-function
     yank-action
     send-actions
     return-action)
  "Internal function to compose a message using fallback MUA.

The arguments TO, SUBJECT, OTHER-HEADERS, CONTINUE,
SWITCH-FUNCTION, YANK-ACTION, SEND-ACTIONS, RETURN-ACTION are as
for `compose-mail'; nil indicates a missing argument."
  (unless desktop-mail-user-agent-fallback
    (user-error "Set `desktop-mail-user-agent-fallback' for complex jobs"))
  (when (eq desktop-mail-user-agent-fallback 'desktop-mail-user-agent)
    (user-error "Loop in desktop-mail-user-agent-fallback"))
  (funcall (or (get desktop-mail-user-agent-fallback 'composefunc)
               (error "%S does not have a compose function"
                      desktop-mail-user-agent-fallback))
           to
           subject
           other-headers
           continue
           switch-function
           yank-action
           send-actions
           return-action))

(defun desktop-mail-user-agent--compose
    (&optional to
               subject
               other-headers
               continue
               switch-function
               yank-action
               send-actions
               return-action)
  "Internal function expected by `define-mail-user-agent'.

The arguments TO, SUBJECT, OTHER-HEADERS, CONTINUE,
SWITCH-FUNCTION, YANK-ACTION, SEND-ACTIONS, RETURN-ACTION are as
for `compose-mail'; nil indicates a missing argument."
  (desktop-mail-user-agent--assert-no-hook)
  (if (or other-headers
          continue
          switch-function
          ;; `yank-action' can be safely ignored.
          send-actions
          return-action)
      (desktop-mail-user-agent--compose-fallback
       to
       subject
       other-headers
       continue
       switch-function
       yank-action
       send-actions
       return-action)
    (desktop-mail-user-agent--compose-desktop
     to
     subject)))

(defun desktop-mail-user-agent--send ()
  "Internal function expected by `define-mail-user-agent'."
  (error "`desktop-mail-user-agent--send' called"))

(defun desktop-mail-user-agent--abort ()
  "Internal function expected by `define-mail-user-agent'."
  (error "`desktop-mail-user-agent--abort' called"))

;;;###autoload
(defun desktop-mail-user-agent ()
  "Use desktop mail client to send mail."
  (unless desktop-mail-user-agent-fallback
    (setq desktop-mail-user-agent-fallback mail-user-agent))
  (setq mail-user-agent 'desktop-mail-user-agent))

(define-mail-user-agent 'desktop-mail-user-agent
  'desktop-mail-user-agent--compose
  'desktop-mail-user-agent--send
  'desktop-mail-user-agent--abort
  'desktop-mail-user-agent--hook)

(provide 'desktop-mail-user-agent)

;;; desktop-mail-user-agent.el ends here
