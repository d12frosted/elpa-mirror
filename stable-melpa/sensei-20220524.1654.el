;;; sensei.el --- A client for sensei  -*- lexical-binding: t; -*-

;; Copyright (c) Arnaud Bailly - 2022
;; Author: Arnaud Bailly <arnaud@pankzsoft.com>
;; Package-Requires: ((emacs "27.1") (projectile "2.5.0") (request "0.3.2"))
;; Package-Version: 20220524.1654
;; Package-Commit: 76e9bee9c9b9d1c99e4504e51c248734274ed6ae
;; Keywords: hypermedia
;; Version: 0.43.1
;; Homepage: https://abailly.github.io/sensei

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;;
;;     * Redistributions of source code must retain the above copyright
;;       notice, this list of conditions and the following disclaimer.
;;
;;     * Redistributions in binary form must reproduce the above
;;       copyright notice, this list of conditions and the following
;;       disclaimer in the documentation and/or other materials provided
;;       with the distribution.
;;
;;     * Neither the name of Author name here nor the names of other
;;       contributors may be used to endorse or promote products derived
;;       from this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; This package provides two basic tools to interact with a remote
;; instance of sensei, a tool for note taking and time management:
;;
;; * The ability to take notes on the fly within a given project's
;;   context.  This opens a temporary buffer whose content will be
;;   sent as-is to sensei with the project's directory and current
;;   timestamp,
;;
;; * Quick recording of current "Flow" according to what flows are
;;   recorded within the current user's profile.
;;
;; Proper operation depends on the existence of ~/.config/sensei/client.json
;; configuration file defining user name and authentication token.

;;; Code:
(require 'url)
(require 'projectile)
(require 'request)
(require 'cl-lib)

(defun sensei-insert-timestamp-iso ()
  "Insert the current timestamp (ISO 8601 format)."
  (format-time-string "%FT%T%z" nil t))

(defun sensei-read-config ()
  "Read sensei 'client.json' file from default XDG location."
  (json-read-file "~/.config/sensei/client.json"))

(defvar sensei-cur-directory
  "Used to set current directory when recording notes.

This variable is updated every time one starts recording a note,
according to what 'projectile-project-root' says for the current
directory.

TODO: Remove this global variable and find a way to pass the
project directory when starting note edition.
")

(defun sensei-send-event-note (directory on-success)
  "Record notes in sensei from the current context.

* DIRECTORY is the directory to record the note for.
* ON-SUCCESS is a function called upon successful submission of note."
  (let* ((config (sensei-read-config))
         (auth-token (cdr (assoc 'authToken config)))
         (api-version (cdr (assoc 'apiVersion config)))
         (username (cdr (assoc 'configUser config)))
         (server-uri (cdr (assoc 'serverUri config))))
    (request (concat server-uri "api/log/" username)
      :method "POST"
      :data (json-encode
             `((("tag" . "Note")
                ("_version" . 9)
                ("noteUser" . ,username)
                ("noteTimestamp" . ,(sensei-insert-timestamp-iso))
                ("noteDir" . ,directory)
                ("noteContent" . ,(buffer-substring-no-properties (point-min) (point-max))))))
      :headers `(("Content-Type" . "application/json")
                 ("X-API-Version" . ,api-version)
                 ("Authorization" . ,(concat "Bearer " auth-token)))
      :parser 'json-read
      :error  (cl-function (lambda (&key error-thrown &allow-other-keys)
                             (message "Got error: %S" error-thrown)))
      :success  (cl-function (lambda (&rest)
                               (message "Successfully recorded note")
                               (eval on-success))))))

(defun sensei-send-event-flow (directory flow-type)
  "Record a change in flow from the current context.

* DIRECTORY is the directory to record the flow for.
* FLOW-TYPE is the type of flow to record, which must be a type supported by the backend as listed by `sensei-list-flows'."
  (let* ((config (sensei-read-config))
         (auth-token (cdr (assoc 'authToken config)))
         (api-version (cdr (assoc 'apiVersion config)))
         (username (cdr (assoc 'configUser config)))
         (server-uri (cdr (assoc 'serverUri config))))
    (request (concat server-uri "api/log/" username)
      :method "POST"
      :data (json-encode
             `((("tag" . "Flow")
                ("_version" . 9)
                ("flowUser" . ,username)
                ("flowTimestamp" . ,(sensei-insert-timestamp-iso))
                ("flowDir" . ,directory)
                ("flowType" . ,flow-type))))
      :headers `(("Content-Type" . "application/json")
                 ("X-API-Version" . ,api-version)
                 ("Authorization" . ,(concat "Bearer " auth-token)))
      :parser 'json-read
      :error  (cl-function (lambda (&key error-thrown &allow-other-keys)
                             (message "Got error: %S" error-thrown)))
      :success  (cl-function (lambda (&rest)
                               (message "Switch to flow %s" flow-type))))))

(defun sensei-list-flows ()
  "List available flow types for the current user."
  (let* ((config (sensei-read-config))
         (auth-token (cdr (assoc 'authToken config)))
         (api-version (cdr (assoc 'apiVersion config)))
         (username (cdr (assoc 'configUser config)))
         (server-uri (cdr (assoc 'serverUri config))))

    (with-temp-buffer
      (setq url-request-extra-headers `(("Content-Type" . "application/json")
                                        ("X-API-Version" . ,api-version)
                                        ("Authorization" . ,(concat "Bearer " auth-token))))
      (url-insert-file-contents (concat server-uri "api/users/" username))
      (let ((flows (cdr (assoc 'userFlowTypes (json-parse-buffer :object-type 'alist)))))
        (cl-map 'list #'car flows)))))

(defun sensei-send-note-and-close ()
  "Record current buffer as note and close it.

The content of the buffer can be formatted using markdown syntax.

DIRECTORY is the project to record note for."
  (interactive)
  (sensei-send-event-note sensei-cur-directory
                          '(kill-buffer (current-buffer))))

(defun sensei-record-note ()
  "Interactive function to record some note."
  (interactive)
  (let ((buffer-name "*sensei-note*")
        (directory (projectile-project-root)))
    (get-buffer-create buffer-name)
    (message "In dir %S" directory)
    (setq sensei-cur-directory directory)
    (switch-to-buffer buffer-name)
    (use-local-map nil)
    (local-set-key
     (kbd "C-c C-c")
     #'sensei-send-note-and-close)))

(defun sensei-record-flow (flow-type)
  "Interactive function to record change in flow.

FLOW-TYPE is a string representation of the flow type that will be
recorded on the server."
  (interactive (list (completing-read
                      "Flow: "
                      (cons 'End (sensei-list-flows))
                      nil t)))
  (let ((directory (projectile-project-root)))
    (setq sensei-cur-directory directory)
    (sensei-send-event-flow directory flow-type)))


(provide 'sensei)
;;; sensei.el ends here
