;;; etherpad.el --- Interface to the Etherpad API -*- coding: utf-8; lexical-binding: t -*-

;; Copyright 2020 FoAM
;;
;; Author: nik gaffney <nik@fo.am>
;; Created: 2020-08-08
;; Version: 0.1
;; Package-Version: 20201017.2006
;; Package-Commit: 36956db9fa65ff88f3213a80b11f1fad0765d972
;; Package-Requires: ((emacs "26.1") (request "0.3") (let-alist "0.0"))
;; Keywords: comm, etherpad, collaborative editing
;; URL: https://github.com/zzkt/ethermacs

;; This file is not part of GNU Emacs.

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

;; Etherpad is a highly customizable Open Source online editor providing
;; collaborative editing in really real-time.
;;
;; This package enables read-write access to pads on an Etherpad server
;; as if they were filelike but is not (yet) suitable for use as a
;; collaborative Etherpad client.
;;
;;  details -> https://etherpad.org/doc/v1.8.5/#index_http_api


;;  known bugs, limitations, shortcomings, etc
;;  - doesn't do realtime editing
;;  - the server and api key could be buffer local to enable editing on more than one server
;;  - doesn't automate API interface generation from openapi.json
;;  - not much in the way of error checking or recovery
;;  - etc


;;; Code:

(require 'request)
(require 'let-alist)
(require 'cl-lib)

(defgroup etherpad nil
  "Etherpad edits."
  :prefix "etherpad-"
  :group 'external)

(defcustom etherpad-apikey "request an API key"
    "API key for the etherpad server."
    :type 'string)

(defcustom etherpad-server "https://example.org"
  "URL of the etherpad server."
  :type 'string)

(defcustom etherpad-autosync nil
  "Sync with etherpad server whenever the local buffer changes."
  :type 'boolean)

(defcustom etherpad-idlesync nil
  "Sync with etherpad server whenever auto-save is triggered."
  :type 'boolean)

(defvar etherpad--local-pad-name ""
   "Buffer local pad details.")

(defvar etherpad--local-pad-revision ""
  "Buffer local pad details.")


;; API functions

(defun etherpad-openapi ()
  "Find API details using openAPI endpoint.
Should be available at https://<host>/api/1/openapi.json"
  (interactive)
  (request
    (format "%s/api/1/openapi.json" etherpad-server)
    :sync t
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (message "200: %s" data)))
    :error (cl-function
            (lambda (&rest args &key error-thrown &allow-other-keys)
              (message "etherpad API error: %s" error-thrown)))))


(defun etherpad--api-pad-revision (pad-id)
  "Current revision number for the pad with PAD-ID."
  (catch 'rev
  (request
    (format "%s/api/1/getRevisionsCount?padID=%s&apikey=%s" etherpad-server pad-id etherpad-apikey)
    :sync t
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (let-alist data (throw 'rev .data.revisions))))
    :error (cl-function
            (lambda (&rest args &key error-thrown &allow-other-keys)
              (error "Etherpad API error: %s" error-thrown))))))


(defun etherpad--api-get-text (pad-id)
  "Get the text of a pad with PAD-ID."
  (catch 'text
  (request
    (format "%s/api/1/getText?padID=%s&apikey=%s" etherpad-server pad-id etherpad-apikey)
    :sync t
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (let-alist data (throw 'text .data.text))))
    :error (cl-function
            (lambda (&rest args &key error-thrown &allow-other-keys)
              (error "Etherpad API error: %s" error-thrown))))))


(defun etherpad--api-set-text (pad-id text)
  "Overwrite the contents of the pad PAD-ID with some TEXT."
  (request
    (format "%s/api/1/setText" etherpad-server)
    :type: "POST"
    :data `(("apikey" . ,etherpad-apikey) ("padID" . ,pad-id) ("text" . ,text))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (message "written to %s: %s\ndata: %s\n" pad-id text data)))
    :error (cl-function
            (lambda (&rest args &key error-thrown &allow-other-keys)
              (error "Etherpad API error: %s" error-thrown)))))



;;;###autoload
(defun etherpad-edit (&optional pad-id)
  "Edit a pad with the given PAD-ID."
  (interactive "sName of the pad to edit: ")
  ;; note: check if pad-id exists and/or create new pad as required
  (let* ((pad-remote-revision (etherpad--api-pad-revision pad-id))
         (pad-buffer (get-buffer-create (format "%s:%s at %s" pad-id pad-remote-revision etherpad-server)))
         (pad-text (etherpad--api-get-text pad-id)))
    (with-current-buffer pad-buffer
      (setq-local etherpad--local-pad-name pad-id
                  etherpad--local-pad-revision (etherpad--api-pad-revision pad-id))
      (goto-char (point-min))
      (erase-buffer)
      (insert pad-text)
      (message "opening pad: %s rev: %s" etherpad--local-pad-name etherpad--local-pad-revision)
      (goto-char (point-max))
      (display-buffer pad-buffer)
      (make-local-variable 'etherpad-autosync)
      (when etherpad-autosync (etherpad-autosync-enable))
      (when etherpad-idlesync (etherpad-idlesync-enable)))
    (set-buffer pad-buffer)))


(defun etherpad-update (&optional pad-id)
  "Update current buffer with text from a remote pad (PAD-ID)."
  (interactive "sName of the pad to sync from: ")
  (when (not pad-id) (setq pad-id etherpad--local-pad-name))
  (message "pad-id: %s etherpad--local-pad-name: %s (buffer local)" pad-id etherpad--local-pad-name)
  ;; note: check if pad-id exists and/or create new pad as required
  (let* ((pad-remote-revision (etherpad--api-pad-revision pad-id))
         (pad-buffer (current-buffer))
         (pad-text (etherpad--api-get-text pad-id)))
    (with-current-buffer pad-buffer
      (setq-local etherpad--local-pad-name pad-id
                  etherpad--local-pad-revision pad-remote-revision)
      (rename-buffer (format "%s:%s at %s" etherpad--local-pad-name etherpad--local-pad-revision etherpad-server))
      (goto-char (point-min))
      (erase-buffer)
      (insert pad-text)
      (message "synced from pad: %s rev: %s" etherpad--local-pad-name etherpad--local-pad-revision)
      (goto-char (point-max))
      (display-buffer pad-buffer)
      pad-buffer)))


;;;###autoload
(defun etherpad-save ()
  "Write a buffer to an etherpad.
'etherpad--local-pad-name' and 'etherpad--local-pad-revision' are buffer local"
  (interactive)
  ;; show diffs, merge, update, etc+
  ;; and save...
  (message "preparing to write %s revision %s (from '%s')"  etherpad--local-pad-name (1+ etherpad--local-pad-revision) (current-buffer))
  ;; check for version drift & update revision
  (let* ((remote-revision (etherpad--api-pad-revision etherpad--local-pad-name))
          (local-revision etherpad--local-pad-revision))
    (if (> remote-revision local-revision)
        (when (y-or-n-p
               (format "Text is out of sync with pad on the server (revision %s > %s) resync? "
                       remote-revision local-revision))
          (etherpad-update etherpad--local-pad-name))
      (progn
        (etherpad--api-set-text etherpad--local-pad-name (buffer-string))
        (message "wrote to pad: %s revision %s" etherpad--local-pad-name (etherpad--api-pad-revision etherpad--local-pad-name))
        (setq etherpad--local-pad-revision (etherpad--api-pad-revision etherpad--local-pad-name))
        (message "new revision? %s" etherpad--local-pad-revision)
        (rename-buffer (format "%s:%s at %s" etherpad--local-pad-name etherpad--local-pad-revision etherpad-server))
        (message "pad has been synced (at revision %s)" etherpad--local-pad-revision)))))


(defun etherpad-before-change-function (_begin _end)
"Function to run before etherpad update (buffer BEGIN and END).
should be specific to minor mode and buffer local."
  (let* ((remote-revision (etherpad--api-pad-revision etherpad--local-pad-name))
         (local-revision etherpad--local-pad-revision))
    (when (> remote-revision local-revision)
      (etherpad-update))))

(defun etherpad-after-change-function (_begin _end _length)
  "Function to run after buuffer has changed (buffer BEGIN, END & LENGTH).
should be specific to minor mode and buffer local."
  (etherpad-save))

(defun etherpad-autosync-toggle ()
  "Toggle autosync."
  (interactive)
  (if etherpad-autosync
      (progn (setq etherpad-autosync nil)
             (etherpad-autosync-disable))
    (progn (setq etherpad-autosync t)
           (etherpad-autosync-enable))))

(defun etherpad-autosync-enable ()
  "Enable autosync."
  (interactive)
  (message "enabled autosync with etherpad server.")
  (make-local-variable 'after-change-functions)
  (make-local-variable 'before-change-functions)
  (add-hook 'after-change-functions #'etherpad-after-change-function)
  (add-hook 'before-change-functions #'etherpad-before-change-function))

(defun etherpad-autosync-disable ()
  "Disable autosync."
  (interactive)
  (message "disabled autosync with etherpad server.")
  (remove-hook 'after-change-functions #'etherpad-after-change-function)
  (remove-hook 'before-change-functions #'etherpad-before-change-function))

(defun etherpad-idlesync-enable ()
  "Sync pad whenever auto-save would."
  (interactive)
  (make-local-variable 'auto-save-hook)
  (make-local-variable 'auto-save-mode)
  (auto-save-mode t)
  (add-hook 'auto-save-hook #'etherpad-save))


(defun etherpad-idlesync-disable ()
  "Disable idle syncing."
  (interactive)
  (remove-hook 'auto-save-hook #'etherpad-save))


(provide 'etherpad)
;;; etherpad.el ends here
