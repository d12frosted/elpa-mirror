;;; desktop+.el --- Handle special buffers when saving & restoring sessions

;; Copyright (C) 2014-2015 François Févotte
;; Author:  François Févotte <fevotte@gmail.com>
;; URL: https://github.com/ffevotte/desktop-plus
;; Package-Version: 20170107.2132
;; Package-Commit: 88055cee526a000056201898499cebbd35e3ea76
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.4") (dash "2.11.0") (f "0.17.2"))

;; This file is NOT part of Emacs

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

;;     `desktop+' extends `desktop' by providing more features related to
;;     sessions persistance.

;; Centralized directory storing all desktop sessions:
;;
;;     Instead of relying on Emacs' starting directory to choose the session
;;     Emacs restarts, two functions are provided to manipulate sessions by
;;     name.
;;
;;     `desktop+-create': create a new session and give it a name.
;;
;;     `desktop+-load': change the current session; the new session to be loaded
;;          is identified by its name, as given during session creation using
;;          `desktop-create'.
;;
;;     The currently active session is identified in the title bar.  You can
;;     customize `desktop+-frame-title-function' to change the way the active
;;     session is displayed.
;;
;;     All sessions managed this way are stored in the directory given by
;;     `desktop+-base-dir'.

;; Handling of special buffers:
;;
;;     Desktop sessions by default save only buffers associated to "real" files.
;;     Desktop+ extends this by handling also "special buffers", such as those
;;     in `compilation-mode' or `term-mode', or indirect buffers (aka clones).

;;; Code:
(eval-when-compile
  (require 'dash))

(require 'desktop)
(require 'f)

;; * Named sessions

;; ** Customizable options

(defvar desktop+-base-dir "~/.emacs.d/desktops/"
  "Base directory for desktop files.")

(defvar desktop+-frame-title-function 'desktop+--frame-title
  "Function returning the frame title when a desktop session is loaded.

This function must accept the desktop name as a string argument
and return a frame title format suitable for setting
`frame-title-format'")

;; ** Entry points

;;;###autoload
(defun desktop+-create (name)
  "Create a new session, identified by a name.
The session is created in a subdirectory of `desktop+-base-dir'.
It can afterwards be reloaded using `desktop+-load'.

As a special case, if NAME is left blank, the session is
automatically named after the current working directory."
  (interactive "MDesktop name: ")
  (desktop-kill)
  (setq desktop-dirname (desktop+--dirname name))
  (make-directory desktop-dirname 'parents)
  (desktop-save desktop-dirname)
  (desktop+--set-frame-title)
  (desktop-save-mode 1))

;;;###autoload
(defun desktop+-create-auto ()
  "Create a new session, identified by the current working directory.
The session is created in a subdirectory of `desktop+-base-dir'.
It can afterwards be reloaded using `desktop+-load'."
  (interactive)
  (desktop+-create ""))

;;;###autoload
(defun desktop+-load (name)
  "Load a session previously created using `desktop+-create'.
NAME is the name which was given at session creation.  When
called interactively, it is asked in the minibuffer with
auto-completion.

As a special case, if NAME is left blank, the session is
automatically named after the current working directory."
  (interactive
   (list
    (completing-read "Desktop name: "
                     (remove "."
                             (remove ".."
                                     (directory-files desktop+-base-dir))))))
  (desktop-change-dir (desktop+--dirname name))
  (desktop+--set-frame-title)
  (desktop-save-mode 1))

;;;###autoload
(defun desktop+-load-auto ()
  "Load a session previously created using `desktop+-create-auto'.
The session is identified by the current working directory."
  (interactive)
  (desktop+-load ""))

;; ** Inner workings

(defun desktop+--dirname (name)
  "Path to the desktop identified by NAME.
As a special case, if NAME is blank, the directory is identified
by the current working directory.

This path is located under `desktop+-base-dir'."
  (f-join desktop+-base-dir
          (if (string= "" name)
              (replace-regexp-in-string "/" "-" (f-canonical default-directory))
            name)))

(defun desktop+--frame-title (desktop-name)
  "Default frame title function for sessions.

Returns the following frame title format:
  '%b - Emacs [DESKTOP-NAME]'"
  (list (concat "%b - Emacs [" desktop-name "]")))


(defun desktop+--set-frame-title ()
  "Set the frame title to show the currently active session."
  (setq frame-title-format
        (funcall desktop+-frame-title-function
                 (file-name-nondirectory (directory-file-name desktop-dirname)))))


;; * Special buffers

;; ** Customizable options

(defvar desktop+-special-buffer-handlers
  '(term-mode
    compilation-mode
    org-agenda-mode
    indirect-buffer
    Man-mode
    shell-mode)
  "List of special buffers to handle.")

;; ** Entry point

;;;###autoload
(defun desktop+--advice--desktop-save (&rest args)
  "Also save special buffers."
  (desktop+--buffers-save))
;;;###autoload
(advice-add 'desktop-save :before #'desktop+--advice--desktop-save)

;;;###autoload
(defun desktop+--advice--desktop-restore-frameset (&rest args)
  "Restore special buffers."
  (desktop+--buffers-load))
;;;###autoload
(advice-add 'desktop-restore-frameset :before #'desktop+--advice--desktop-restore-frameset)

;; ** Mode-specific handlers for special buffers

(defvar desktop+--special-buffer-handlers-alist nil
  "Alist of handlers for special buffers.")

(defun desktop+-add-handler (name pred save-fn load-fn)
  "Add handlers for special buffers.

NAME is a symbol identifying the handler for later activation or
deactivation.

PRED should be a unary function used as a predicate to determine
whether a buffer should be handled specially.  When called in a
buffer which should be handled, PRED should return non-nil.

SAVE-FN should be a function taking no parameter, returning a
list of all relevant parameters for the current buffer, which is
assumed to be in the given major mode.

LOAD-FN should be a function of the following form:

  (lambda (name &rest args) ...)

allowing to restore a buffer named NAME in major mode MODE,
from information stored in ARGS, as determined by SAVE-FN."
  (declare (indent 1))
  (push (list name pred save-fn load-fn)
        desktop+--special-buffer-handlers-alist))

;; *** Terminals

(defun desktop+--term-mode-hook ()
  (setq desktop-save-buffer #'desktop+--terminal-save-buffer))

(defun desktop+--terminal-save-buffer (dirname)
  "Return relevant parameters for saving a terminal buffer."
  (list :dir     default-directory
        :command (car (last (process-command
                             (get-buffer-process (current-buffer)))))))

(defun desktop+--terminal-restore-buffer (file-name buffer-name misc)
  "Restore a terminal buffer."
  (when (null (get-buffer buffer-name))
    (let ((default-directory (plist-get misc :dir)))
      (with-current-buffer (term (plist-get misc :command))
        (rename-buffer buffer-name)
        (current-buffer)))))

(when (memq 'term-mode desktop+-special-buffer-handlers)
  (add-hook 'term-mode-hook 'desktop+--term-mode-hook)
  (add-to-list 'desktop-buffer-mode-handlers
               '(term-mode . desktop+--terminal-restore-buffer)))

;; *** Compilation buffers

(defun desktop+--compilation-mode-hook ()
  (setq desktop-save-buffer #'desktop+--compilation-save-buffer))

(defun desktop+--compilation-save-buffer (dirname)
  "Return relevant parameters for saving a compilation buffer."
  (list :command compilation-arguments
        :dir     compilation-directory))

(defun desktop+--compilation-restore-buffer (file-name buffer-name misc)
  "Restore a compilation buffer."
  (with-current-buffer (get-buffer-create buffer-name)
    (compilation-mode)
    (set (make-local-variable 'compilation-arguments) (plist-get misc :command))
    (set (make-local-variable 'compilation-directory) (plist-get misc :dir))
    (current-buffer)))

(when (memq 'compilation-mode desktop+-special-buffer-handlers)
  (add-hook 'compilation-mode-hook 'desktop+--compilation-mode-hook)
  (add-to-list 'desktop-buffer-mode-handlers
               '(compilation-mode . desktop+--compilation-restore-buffer)))

;; *** Org Agenda buffers

(defun desktop+--org-agenda-mode-hook ()
  (setq desktop-save-buffer #'desktop+--org-agenda-save-buffer))

(defun desktop+--org-agenda-save-buffer (dirname)
  "Return relevant parameters for saving an org agenda buffer."
  (list :dir  default-directory
        :type org-agenda-type))

(defun desktop+--org-agenda-restore-buffer (file-name buffer-name misc)
  "Restore an org agenda buffer."
  (let ((default-directory (plist-get misc :dir)))
    (save-window-excursion
      (cond
       ((eq (plist-get misc :type) 'todo)
        (org-todo-list))
       ((eq (plist-get misc :type) 'agenda)
        (org-agenda-list))
       (t
        (error "unknown org-agenda-type")))
      (rename-buffer buffer-name)
      (current-buffer))))

(when (memq 'org-agenda-mode desktop+-special-buffer-handlers)
  (add-hook 'org-agenda-mode-hook 'desktop+--org-agenda-mode-hook)
  (add-to-list 'desktop-buffer-mode-handlers
               '(org-agenda-mode . desktop+--org-agenda-restore-buffer)))

;; *** Clones (indirect buffers)

(desktop+-add-handler 'indirect-buffer
  #'buffer-base-buffer

  (lambda ()
    `(:base ,(buffer-name (buffer-base-buffer))))

  (lambda (name &rest args)
    (with-current-buffer (get-buffer (plist-get args :base))
      (clone-indirect-buffer name nil))))

;; *** Man-mode buffers

(defun desktop+--Man-mode-hook ()
  (setq desktop-save-buffer #'desktop+--Man-save-buffer))

(defun desktop+--Man-save-buffer (dirname)
  "Return relevant parameters for saving a `Man-mode' buffer."
  (list :arguments Man-arguments))

(defun desktop+--Man-restore-buffer (file-name buffer-name misc)
  "Restore a `Man-mode' buffer."
  (with-current-buffer (man (plist-get misc :arguments))
    (rename-buffer buffer-name)))

(when (memq 'Man-mode desktop+-special-buffer-handlers)
  (add-hook 'Man-mode-hook 'desktop+--Man-mode-hook)
  (add-to-list 'desktop-buffer-mode-handlers
               '(Man-mode . desktop+--Man-restore-buffer)))

;; *** shell-mode

(defun desktop+--shell-mode-hook ()
  (setq desktop-save-buffer #'desktop+--shell-save-buffer))

(defun desktop+--shell-save-buffer (dirname)
  "Return relevant parameters for saving a `shell-mode' buffer.

Currently, it saves and restores the current working directory.

The text in the buffer, as well as environment variables, shell
variables and other state are lost."
  (list :dir default-directory))

(defun desktop+--shell-restore-buffer (file-name buffer-name misc)
  "Restore a `shell-mode' buffer."
  (let* ((dir (plist-get misc :dir))
         (default-directory (if (file-directory-p dir) dir "/")))
    (with-current-buffer (shell)
      (rename-buffer buffer-name))))

(when (memq 'shell-mode desktop+-special-buffer-handlers)
  (add-hook 'shell-mode-hook 'desktop+--shell-mode-hook)
  (add-to-list 'desktop-buffer-mode-handlers
               '(shell-mode . desktop+--shell-restore-buffer)))

;; ** Inner workings

(defun desktop+--buffers-file ()
  "Name of the file where special buffers configuration will be saved."
  (f-join desktop-dirname ".emacs-buffers"))

(defun desktop+--create-buffer (key name &rest args)
  "Recreate a special buffer from saved parameters.

KEY identifies the special buffer type, as registered in
`desktop+-special-buffer-handlers'.

NAME is the name of the buffer.

ARGS is the relevant buffer parameters, as determined by the
registered save handler.  These parameters will be restored by
calling the load handler."
  (let ((handler (assq key desktop+--special-buffer-handlers-alist)))
    (when handler
      (apply (nth 3 handler) name args))))

(defun desktop+--buffers-save ()
  "Persistently save special buffers.
Information is kept in the file pointed to by `desktop+--buffers-file'."
  (with-temp-buffer
    (mapc (lambda (b)
            (let ((data
                   (with-current-buffer b
                     (let ((handler
                            (--first
                             (and (memq (nth 0 it) desktop+-special-buffer-handlers)
                                  (funcall (nth 1 it)))
                             desktop+--special-buffer-handlers-alist)))
                       (when handler
                         (append `(desktop+--create-buffer
                                   (quote ,(nth 0 handler))
                                   ,(buffer-name))
                                 (funcall (nth 2 handler))))))))
              (if data
                  (pp data (current-buffer)))))
          (buffer-list))
    (write-region nil nil (desktop+--buffers-file) nil 'quiet)))

(defun desktop+--buffers-load ()
  "Load special buffers from the persistent session file.
Information is kept in the file pointed to by
`desktop+-desktop+--buffers-file'."
  (when (file-exists-p (desktop+--buffers-file))
    (load-file (desktop+--buffers-file))))

(provide 'desktop+)

;;; desktop+.el ends here
