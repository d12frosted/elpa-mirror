;;; codespaces.el --- Connect to GitHub Codespaces via TRAMP  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Patrick Thomson and Bas Alberts

;; Author: Patrick Thomson <patrickt@github.com>
;; URL: https://github.com/patrickt/codespaces.el
;; Package-Version: 20220822.1255
;; Package-Commit: e734b427446202cfed473cdb8a1b5b0fe708fab1
;; Version: 0.1
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
;; via TRAMP in Emacs. It also provides a completing-read interface
;; to select codespaces.

;; This package works by registering a new "ghcs" method in tramp-methods.

;;; Code:

(require 'tramp)

(defun codespaces-setup ()
  "Set up the ghcs tramp-method. Should be called after requiring this package."
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

(cl-defstruct codespaces-space name state repository ref)

(defun codespaces-space-from-hashtable (ht)
  "Create a codespace from the JSON hashtable HT returned from `gh'."
  (make-codespaces-space
   :name (gethash "name" ht)
   :state (gethash "state" ht)
   :repository (gethash "repository" ht)
   :ref (gethash "ref" (gethash "gitStatus" ht))))

(defun codespaces-space-describe (cs)
  "Format details about codespace CS for display as marginalia."
  (format " -- %s | %s | %s"
          (codespaces-space-state cs)
          (codespaces-space-repository cs)
          (codespaces-space-ref cs)))

(defun codespaces-space-available-p (cs)
  "Return t if codespace CS is marked as available."
  (equal "Available" (codespaces-space-state cs)))

(defun codespaces--get-codespaces ()
  "Execute `gh' and parse its results."
  (letrec
      ((gh-invocation "gh codespace list --json name,displayName,repository,state,gitStatus,lastUsedAt")
       (codespace-json (shell-command-to-string gh-invocation)))
    (codespaces--munge (json-parse-string codespace-json))))

(defun codespaces--fold (acc val)
  "Internal: fold function for accumulating JSON results into ACC from VAL."
  (let ((cs (codespaces-space-from-hashtable val)))
    (puthash (codespaces-space-name cs) cs acc)
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
    (completing-read "Select a codespace: " valid-names)))

(defun codespaces-connect ()
  "Connect to a codespace chosen by `completing-read'."
  (interactive)
  (letrec ((json (codespaces--get-codespaces))
           (cs (codespaces--complete json))
           (selected (gethash cs json)))
    (unless (codespaces-space-available-p selected)
      (message "Activating codespace (this may take some time)..."))
    (find-file (format "/ghcs:%s:/workspaces" cs))))

(provide 'codespaces)

;;; codespaces.el ends here
