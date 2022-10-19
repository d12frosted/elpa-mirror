;;; codespaces.el --- Connect to GitHub Codespaces via TRAMP  -*- lexical-binding: t -*-

;; Copyright (C) 2022 Patrick Thomson and Bas Alberts

;; Author: Patrick Thomson <patrickt@github.com>
;; URL: https://github.com/patrickt/codespaces.el
;; Package-Version: 20221018.1831
;; Package-Commit: 8e0843684ea685c2b25b8f5601cf02553bab4b08
;; Version: 0.2
;; Package-Requires: ((emacs "28.1"))
;; Keywords: comm
;; Created: 2022-08-11

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides support for connecting to GitHub Codespaces
;; via TRAMP in Emacs.  It also provides a completing-read interface
;; to select codespaces.

;; This package works by registering a new "ghcs" method in tramp-methods.

;;; Code:

(require 'tramp)

(defgroup codespaces nil
  "Codespaces configuration."
  :group 'tramp
  :prefix "codespaces-")

(defcustom codespaces-default-directory nil
  "The default directory for a codespace.

This will be resolved relative to the connection root.  By default, this will
use the default directory for the codespace (the same as if you ran
`gh cs ssh`) but if you provide a path, relative or absolute, that will be
substituted instead.

When this is nil, the default of '/workspaces/<repo-name>' is used."
  :group 'codespaces
  :type 'string)

(defun codespaces-setup ()
  "Set up the ghcs tramp-method.  Should be called after requiring this package."
  (interactive)
  (unless (executable-find "gh")
    (user-error "Could not find `gh' program in your PATH"))
  (unless (featurep 'json)
    (user-error "Emacs JSON support not available; your Emacs is too old"))
  (let ((ghcs (assoc "ghcs" tramp-methods))
        (ghcs-methods '((tramp-login-program "gh")
                        (tramp-login-args (("codespace") ("ssh") ("-c") ("%h")))
                        (tramp-remote-shell "/bin/sh")
                        (tramp-remote-shell-login ("-l"))
                        (tramp-remote-shell-args ("-c")))))
    ;; just for debugging the methods
    (if ghcs (setcdr ghcs ghcs-methods)
      (push (cons "ghcs" ghcs-methods) tramp-methods)))
  (tramp-set-completion-function "ghcs" '((codespaces-tramp-completion ""))))

;;; codespace struct

(cl-defstruct (codespaces-space (:constructor codespaces-make-space) (:copier nil))
  "Codespace information as fetched from GitHub."
  (name nil :type string)
  (display-name nil :type string)
  (state 'unknown :type symbol)
  (repository nil :type string)
  (ref nil :type string))

(defun codespaces-space-from-hashtable (ht)
  "Create a codespace from the JSON hashtable HT returned from `gh'."
  (cl-check-type ht hash-table)
  (cl-flet ((get (n) (gethash n ht)))
    (codespaces-make-space
     :name (get "name")
     :display-name (get "displayName")
     :state (intern (downcase (get "state")))
     :repository (get "repository")
     :ref (gethash "ref" (get "gitStatus")))))

(defun codespaces-space-readable-name (cs)
  "Return the display name of CS, or, if that is empty, its machine name."
  (cl-check-type cs codespaces-space)
  (let ((name (codespaces-space-display-name cs)))
    (if (string-empty-p name) (codespaces-space-name cs) name)))

(defun codespaces-space-repository-name (cs)
  "Return the repository part of the CS codespace repo, or if empty, its name."
  (cl-check-type cs codespaces-space)
  (car (cdr (split-string (codespaces-space-repository cs) "/"))))

(defun codespaces-space-describe (cs)
  "Format details about codespace CS for display as marginalia."
  (cl-check-type cs codespaces-space)
  (format " | %s | %s | %s"
          (codespaces-space-state cs)
          (codespaces-space-repository cs)
          (codespaces-space-ref cs)))

(defun codespaces-space-available-p (cs)
  "Return t if codespace CS is marked as available."
  (cl-check-type cs codespaces-space)
  (eq 'available (codespaces-space-state cs)))

(defun codespaces-space-shutdown-p (cs)
  "Return t if codespace CS is marked as shutdown."
  (cl-check-type cs codespaces-space)
  (eq 'shutdown (codespaces-space-state cs)))

;;; Internal methods

(defmacro codespaces--locally (&rest body)
  "Ensure BODY is run with a local `default-directory'."
  `(let ((default-directory (if (file-remote-p default-directory) "/" default-directory)))
     ,@body))

(defun codespaces--all-codespaces ()
  "Fetch all user codespaces by executing `gh'."
  (let ((gh-invocation "gh codespace list --json name,displayName,repository,state,gitStatus,lastUsedAt"))
    (codespaces--locally
     (codespaces--build-table (json-parse-string (shell-command-to-string gh-invocation))))))

(defun codespaces--filter-codespaces (pred)
  "Fetch all available codespaces, filtering by PRED."
  (cl-loop with result = (make-hash-table :test 'equal)
           for v being the hash-values of (codespaces--all-codespaces)
           when (funcall pred v)
           do (puthash (codespaces-space-readable-name v) v result)
           finally return result))

(defun codespaces--send-start-async (cs)
  "Send an `echo' command to CS over ssh."
  (codespaces--locally
   (async-shell-command (format "gh codespace ssh -c %s echo 'Codespace ready.'" (codespaces-space-name cs)))))

(defun codespaces--send-start-sync (cs)
  "Send an `echo' command to CS over ssh synchronously."
  (codespaces--locally
   (shell-command
    (format "gh codespace ssh -c %s echo 'Codespace ready.'" (codespaces-space-name cs)) (get-buffer shell-command-buffer-name))))

(defun codespaces--send-stop-sync (cs)
  "Tell codespaces CS to stop."
  (codespaces--locally (shell-command (format "gh codespace stop -c %s" (codespaces-space-name cs)))))

(defun codespaces--build-table (json)
  "Accumulate a JSON vector into a hashtable from names to codespaces."
  (cl-loop with result = (make-hash-table :test 'equal)
           for item across json
           for cs = (codespaces-space-from-hashtable item)
           do (puthash (codespaces-space-readable-name cs) cs result)
           finally return result))

(defun codespaces--annotate (s)
  "Annotation function for S invoked by `completing-read'."
  (let ((item (gethash s minibuffer-completion-table)))
    (codespaces-space-describe item)))

(defun codespaces--complete (ht)
  "Invoke `completing-read' over JSON hashtable HT, returning a codespace."
  (let ((completion-extra-properties '(:annotation-function codespaces--annotate)))
    (gethash (completing-read "Select a codespace: " ht nil t) ht)))

(defun codespaces-tramp-completion (_filename)
  "Provide a set of completion candidates to TRAMP connections."
  (cl-loop for v being the hash-values of (codespaces--all-codespaces)
           collect (list nil (codespaces-space-name v))))

;;; Public interface

(defun codespaces-stop ()
  "Stop a codespace chosen by `completing-read'."
  (interactive)
  (codespaces--send-stop-sync
   (codespaces--complete
    (codespaces--filter-codespaces #'codespaces-space-available-p))))

(defun codespaces-start ()
  "Start a codespace chosen by `completing-read'."
  (interactive)
  (codespaces--send-start-async
   (codespaces--complete
    (codespaces--filter-codespaces #'codespaces-space-shutdown-p))))

(defun codespaces-connect ()
  "Connect to a codespace chosen by `completing-read'."
  (interactive)
  (let ((selected (codespaces--complete (codespaces--all-codespaces))))
    (unless (codespaces-space-available-p selected)
      (message "Activating codespace (this may take some time)...")
      (codespaces--send-start-sync selected))
    (find-file (format "/ghcs:%s:%s"
                       (codespaces-space-name selected)
                       (or codespaces-default-directory
                           (format "/workspaces/%s" (codespaces-space-repository-name selected)))))))

(provide 'codespaces)

;;; codespaces.el ends here
