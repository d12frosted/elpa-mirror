;;; 750words.el --- Emacs integration and Org exporter for 750words.com -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Diego Zamboni

;; Author: Diego Zamboni <https://github.com/zzamboni>
;; Maintainer: Diego Zamboni <diego@zzamboni.org>
;; Created: June 10, 2021
;; Modified: June 10, 2021
;; Version: 0.0.1
;; Package-Version: 20210701.1950
;; Package-Commit: 0fed7621c04debad64ea6455455494d4e6eb03fa
;; Keywords: files, org, writing
;; Homepage: https://github.com/zzamboni/750words-client
;; Package-Requires: ((emacs "24.4"))

;; This file is not part of GNU Emacs.

;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at

;;     https://www.apache.org/licenses/LICENSE-2.0

;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:

;; This library provides functions for posting text from Emacs to the
;; 750words.com website.

;; See https://github.com/zzamboni/750words-client for full usage instructions.

;;; Code:

(require 'auth-source)

(defvar 750words-client-command "750words-client.py %s"

  "Program to call to post text to 750words.com.

It must contain one '%s' representing the file in which the text
will be stored before calling it. If you want to use the
750words-client Docker container, you can set it as follows:

\(setq 750words-client-command \"cat %s | docker run -i -e USER_750WORDS -e PASS_750WORDS zzamboni/750words-client\"\)")

(defun 750words-credentials (&optional create)
  "Fetch/create 750words.com credentials.

Search credentials from 750words.com in the configured
`auth-sources'. For example, if `auth-sources' contains
`~/.authinfo.gpg', you can add a line like this to it:

machine 750words.com login <your@email> password <your-password>

If the CREATE argument is t, the credentials are prompted for and
a function returned to save them.

Returns a list containing the following elements: the
750words.com username, the password, and a function which must be
called to save them. For an example of how to use it, see
`750words-credentials-setenv'."
  (let* ((auth-source-creation-prompts
          '((user  . "750words.com username: ")
            (secret . "750words.com password for %u: ")))
         (found (nth 0 (auth-source-search :max 1
                                           :host "750words.com"
                                           :require '(:user :secret)
                                           :create create))))
    (if found
        (list (plist-get found :user)
              (let ((secret (plist-get found :secret)))
                (if (functionp secret)
                    (funcall secret)
                  secret))
              (plist-get found :save-function))
      nil)))

(defun 750words-credentials-setenv (&optional save)
  "Fetch 750words.com credentials and store them in environment variables.

Call `750words-credentials' to fetch the credentials, and stores
the username and password in the USER_750WORDS and PASS_750WORDS
environment variables, respectively, so that they can be used by
750words-client.

If SAVE is t or if called interactively with a prefix argument,
prompt for the credentials if they are not found, and save them
to the configured auth source."
  (interactive "P")
  (let ((creds (750words-credentials save)))
    (when creds
      (setenv "USER_750WORDS" (nth 0 creds))
      (setenv "PASS_750WORDS" (nth 1 creds))
      (when (functionp (nth 2 creds))
        (funcall (nth 2 creds))))))

(defun 750words-file (fname)
  "Post a file to 750words.com.

Post the contents of FNAME to 750words.com."
  ;; From https://emacs.stackexchange.com/a/42174/11843: Execute the command
  ;; asynchronously, and set up a sentinel to detect when the process ends and
  ;; set up its buffer to special-mode, so that it can be easily dismissed by
  ;; the user by pressing `q'.
  (let* ((output-buffer-name "*750words-client-command*")
         (output-buffer (generate-new-buffer output-buffer-name))
         (cmd (format 750words-client-command fname))
         (proc (progn
                 (async-shell-command cmd output-buffer)
                 (get-buffer-process output-buffer))))
    (if (process-live-p proc)
        (set-process-sentinel
         proc
         (apply-partially #'750words--post-process-fn output-buffer))
      (message "Running '%s' failed." cmd))))

(defun 750words--post-process-fn (output-buffer-name process signal)
  "Switch to output buffer and set to `special-mode' when process exits.

This function gets called when the 750words-client PROCESS
finishes with an exit SIGNAL. Switch to its output buffer as
indicated by OUTPUT-BUFFER-NAME and set it to `special-mode',
which makes it read-only and the user can dismiss it by pressing
`q'."
  (when (memq (process-status process) '(exit signal))
    (switch-to-buffer-other-window output-buffer-name)
    (special-mode)
    (shell-command-sentinel process signal)))

(defun 750words-region (start end)
  "Post the current region to 750words.com.

If run interactively with a region selected, it will post the
content of the region.

When called from LISP, pass START and END arguments to indicate
the part of the buffer to post."
  (interactive "r")
  (let* ((fname (make-temp-file "750words")))
    ;; Write the region to a temporary file
    (write-region start end fname)
    ;; Post the temporary file
    (750words-file fname)))

(defun 750words-buffer ()
  "Post the current buffer to 750words.com.

Posts the entire contents of the current buffer. If you want to
post only a part of it, see `750words-region' or
`750words-region-or-buffer'."
  (interactive)
  (750words-region (point-min) (point-max)))

(defun 750words-region-or-buffer ()
  "Post the current region or the whole buffer to 750words.com.

If a region is selected, post it, otherwise post the whole
buffer."
  (interactive)
  (if (region-active-p)
      (750words-region (point) (mark))
    (750words-buffer)))

(provide '750words)
;;; 750words.el ends here
