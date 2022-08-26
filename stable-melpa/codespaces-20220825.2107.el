;;; codespaces.el --- Connect to GitHub Codespaces via TRAMP  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Patrick Thomson and Bas Alberts

;; Author: Patrick Thomson <patrickt@github.com>
;; URL: https://github.com/patrickt/codespaces.el
;; Package-Version: 20220825.2107
;; Package-Commit: c9a42e87dc38aedba6646bf2f4b1b4a6571b3b22
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

(defun codespaces-setup ()
  "Set up the ghcs tramp-method.  Should be called after requiring this package."
  (interactive)
  (unless (executable-find "gh")
    (user-error "Could not find `gh' program in your PATH"))
  (unless (and (fboundp 'json-available-p) (json-available-p))
    (user-error "Emacs JSON support not available; your Emacs is too old"))
  (let ((ghcs (assoc "ghcs" tramp-methods))
        (ghcs-methods '((tramp-login-program "gh")
                        (tramp-login-args (("codespace") ("ssh") ("-c") ("%h")))
                        (tramp-remote-shell "/bin/sh")
                        (tramp-remote-shell-login ("-l"))
                        (tramp-remote-shell-args ("-c")))))
    ;; just for debugging the methods
    (if ghcs (setcdr ghcs ghcs-methods)
      (push (cons "ghcs" ghcs-methods) tramp-methods))))

;;; codespace struct

(cl-defstruct codespaces-space name display-name state repository ref)

(defun codespaces-space-from-hashtable (ht)
  "Create a codespace from the JSON hashtable HT returned from `gh'."
  (make-codespaces-space
   :name (gethash "name" ht)
   :display-name (gethash "displayName" ht)
   :state (gethash "state" ht)
   :repository (gethash "repository" ht)
   :ref (gethash "ref" (gethash "gitStatus" ht))))

(defun codespaces-space-readable-name (cs)
  "Return the display name of CS, or, if that is empty, its machine name."
  (let ((name (codespaces-space-display-name cs)))
    (if (string-empty-p name) (codespaces-space-name cs) name)))

(defun codespaces-space-describe (cs)
  "Format details about codespace CS for display as marginalia."
  (format " | %s | %s | %s"
          (codespaces-space-state cs)
          (codespaces-space-repository cs)
          (codespaces-space-ref cs)))

(defun codespaces-space-available-p (cs)
  "Return t if codespace CS is marked as available."
  (equal "Available" (codespaces-space-state cs)))

;;; Internal methods

(defun codespaces--get-codespaces ()
  "Execute `gh' and parse its results."
  (letrec
      ((gh-invocation "gh codespace list --json name,displayName,repository,state,gitStatus,lastUsedAt")
       (codespace-json (shell-command-to-string gh-invocation)))
    (codespaces--munge (json-parse-string codespace-json))))

(defun codespaces--get-available-codespaces ()
  "Internal: find all available codespaces."
  (letrec ((newtable (make-hash-table :test 'equal))
           ;; This is a terrible implementation but until I switch to using plists it's the best I can do
           (construct (lambda (_ v)
                        (when (codespaces-space-available-p v)
                          (puthash (codespaces-space-readable-name v) v newtable)))))
    (maphash construct (codespaces--get-codespaces))
    newtable))

(defun codespaces--get-unavailable-codespaces ()
  "Internal: find all unavailable codespaces."
  (letrec ((newtable (make-hash-table :test 'equal))
           ;; This is a terrible implementation but until I switch to using plists it's the best I can do
           (construct (lambda (_ v)
                        (unless (codespaces-space-available-p v)
                          (puthash (codespaces-space-readable-name v) v newtable)))))
    (maphash construct (codespaces--get-codespaces))
    newtable))

(defun codespaces--send-start-async (cs)
  "Send an `echo' command to CS over ssh."
  (async-shell-command (format "gh codespace ssh -c %s echo 'Codespace ready.'" (codespaces-space-name cs))))

(defun codespaces--send-start-sync (cs)
  "Send an `echo' command to CS over ssh synchronously."
  (shell-command (format "gh codespace ssh -c %s echo 'Codespace ready.'" (codespaces-space-name cs)) (get-buffer shell-command-buffer-name)))

(defun codespaces--send-stop-async (cs)
  "Tell codespaces CS to stop."
  (shell-command (format "gh codespace stop -c %s" (codespaces-space-name cs))))

(defun codespaces--fold (acc val)
  "Internal: fold function for accumulating JSON results into ACC from VAL."
  (let ((cs (codespaces-space-from-hashtable val)))
    (puthash (codespaces-space-readable-name cs) cs acc)
    acc))

(defun codespaces--munge (json)
  "Internal: accumulate codespace instances from JSON vector."
  (seq-reduce #'codespaces--fold json (make-hash-table :test 'equal)))

(defun codespaces--annotate (s)
  "Annotation function for S invoked by `completing-read'."
  (let ((item (gethash s minibuffer-completion-table)))
    (codespaces-space-describe item)))

(defun codespaces--complete (ht)
  "Invoke `completing-read' over JSON hashtable HT."
  (let
      ((completion-extra-properties '(:annotation-function codespaces--annotate))
       (valid-names ht))
    (completing-read "Select a codespace: " valid-names nil t)))

;;; Public interface

(defun codespaces-stop ()
  "Stop a codespace chosen by `completing-read'."
  (interactive)
  (letrec ((json (codespaces--get-available-codespaces))
           (selected (gethash (codespaces--complete json) json)))
    (codespaces--send-stop-async selected)))

(defun codespaces-start ()
  "Start a codespace chosen by `completing-read'."
  (interactive)
  (letrec ((json (codespaces--get-unavailable-codespaces))
           (selected (gethash (codespaces--complete json) json)))
    (codespaces--send-start-async selected)))

(defalias 'codespaces-activate #'codespaces-start)
(make-obsolete 'codespaces-activate 'codespaces-start nil)

(defun codespaces-connect ()
  "Connect to a codespace chosen by `completing-read'."
  (interactive)
  (letrec ((json (codespaces--get-codespaces))
           (selected (gethash (codespaces--complete json) json)))
    (unless (codespaces-space-available-p selected)
      (message "Activating codespace (this may take some time)...")
      (codespaces--send-start-sync selected))
    (find-file (format "/ghcs:%s:/workspaces" (codespaces-space-name selected)))))

(provide 'codespaces)

;;; codespaces.el ends here
