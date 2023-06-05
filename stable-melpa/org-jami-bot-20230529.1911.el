;;; org-jami-bot.el --- Capture GNU Jami messages as notes and todos in Org mode -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 Hanno Perrey
;;
;; Author: Hanno Perrey <http://gitlab.com/hperrey>
;; Maintainer: Hanno Perrey <hanno@hoowl.se>
;; Created: April 16, 2023
;; Modified: May 29, 2023
;; Version: 0.0.2
;; Package-Version: 20230529.1911
;; Package-Commit: 99358b11e4be25299b62aa676365bc41cb9beb8b
;; Keywords: comm, outlines, org-capture, jami
;; Homepage: https://gitlab.com/hperrey/org-jami-bot
;; Package-Requires: ((emacs "28.1") (jami-bot "0.0.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;    This program is free software: you can redistribute it and/or modify
;;    it under the terms of the GNU General Public License as published by
;;    the Free Software Foundation, either version 3 of the License, or
;;    (at your option) any later version.
;;
;;    This program is distributed in the hope that it will be useful,
;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;    GNU General Public License for more details.
;;
;;    You should have received a copy of the GNU General Public License
;;    along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; `org-jami-bot' builds upon `jami-bot' and extends it with Org mode capture
;; functionality for text messages and images. It allows to schedule agenda
;; items at specific dates, compose multi-measure captures and capture images --
;; all by sending a message via the GNU Jami messenger.
;;
;; `org-jami-bot' provides multi-message capture from within the Jami messenger
;; app -- that is, a capture process that consists of several messages and can
;; include even images and other files. The process is started by sending the
;; command "!start" followed by the title of the capture and finished by sending
;; "!done". Once the multi-message capture session is started, every following
;; message is simply added. This includes images which will be downloaded and
;; stored locally. A reference in the form of a link will be included in the
;; notes.
;;
;; Every command consists of an exclamation mark and a single word, for example:
;; "!help" which shows the available commands or "!today" which captures the
;; remainder of the message as a todo entry scheduled today. Everything else is
;; treated as a normal message (and captured verbatim).
;;
;; Files sent separately as a single message are captured as links to the
;; locally downloaded file and tagged as =FILE=. In principle, further automatic
;; processing (e.g. OCR) could easily be integrated. Any received file will also
;; be added to the variable =org-stored-links= and can then be easily inserted
;; as link in any Org mode document using =C-c C-l=.
;;
;; To get started with `org-jami-bot':
;;  - install jamid, the GNU Jami daemon
;;  - set up a Jami account
;;  - configure a key to be used for org-capture templates:
;;    (setq org-jami-bot-capture-key "J")
;;  - set up `org-jami-bot' using default values:
;;    (org-jami-bot-default-setup)
;;  - register `jami-bot' to react to received messages:
;;    (jami-bot-register)
;;

;;; Code:

(require 'jami-bot)
(require 'org)
(require 'org-capture)

(defvar org-jami-bot-capture-key "J"
  "Key for the `org-capture' template to call for Jami messages.")

(defun org-jami-bot--capture-plain-messsage (account conversation msg)
  "Capture body in MSG and replies to original message.

CONVERSATION and ACCOUNT specify the corresponding ids that the
message belongs to."
  (let* ((buf (format "*jami-capture-%s-%s*" account conversation))
         (continue (get-buffer buf))
         (body (cadr (assoc-string "body" msg)))
         (lines (string-lines body))
         ;; use inactive timestamps
         (timefmt (concat "[" (substring (cdr org-time-stamp-formats) 1 -1) "]")))
    (with-current-buffer (get-buffer-create buf)
      (insert (if continue
                  ;; multi message capture
                  (concat body "\n")
                ;; single message capture
                (format "* %s\n:PROPERTIES:\n:CREATED: %s\n:END:\n%s"
                        (car lines) (format-time-string timefmt) (string-join (cdr lines) "\n"))))
      (jami-bot-reply-to-message
       account
       conversation
       msg
       (if continue
           "message added. Finish capture with \"!done\""
         (if (and (org-capture-string
                   (buffer-string)
                   org-jami-bot-capture-key)
                  (kill-buffer buf))
             "captured!"
           "error during org-capture :("))))))

(defun org-jami-bot--command-function-start (account conversation msg)
  "Initiate a multi-message capture.

It starts with body in MSG by creating a capture buffer for
CONVERSATION and ACCOUNT.

Further plain text messages processed by
`org-jami-bot--capture-plain-messsage' or files received by
`org-jami-bot--capture-file' will be added to this capture
buffer. The actual capture needs to happen through a separate
function, e.g. `org-jami-bot--command-function-done'. Return a
reply string informing correspondent about how to finish capture
by sending '!done'."
  (let* ((buf (format "*jami-capture-%s-%s*" account conversation))
         (body (cadr (assoc-string "body" msg)))
         (lines (string-lines body))
         ;; use inactive timestamps
         (timefmt (concat "[" (substring (cdr org-time-stamp-formats) 1 -1) "]")))
    (with-current-buffer (get-buffer-create buf)
      (insert (if (string-empty-p buf)
                  (format "* Multi-message note capture %s\n:PROPERTIES:\n:CREATED: %s\n:END:\n"
                          (format-time-string timefmt) (format-time-string timefmt))
                (format "* %s\n:PROPERTIES:\n:CREATED: %s\n:END:\n%s"
                        (car lines) (format-time-string timefmt) (string-join (cdr lines) "\n"))))
      "Multi-message capture started. Finish capture with \"!done\"")))

(defun org-jami-bot--command-function-done (account conversation _msg)
  "Finish multi-message capture and return a confirmation string.

        Requires a capture buffer set up for CONVERSATION and
        ACCOUNT, for example through
        `org-jami-bot--command-function-start'."
  (let* ((buf (format "*jami-capture-%s-%s*" account conversation))
         (continue (get-buffer buf)))
    (if continue
        (with-current-buffer (get-buffer-create buf)
          (if (and (org-capture-string
                    (buffer-string)
                    org-jami-bot-capture-key)
                   (kill-buffer buf))
              "capture finished!"
            "error during org-capture :("))
      "No capture to finish. Start multi-message capture with \"!start\"")))

(defun org-jami-bot--capture-file (account conversation msg dlname)
  "Capture downloaded file and reply to original message.

DLNAME specifies local file name downloaded from MSG in
CONVERSATION for jami ACCOUNT."
  (let* ((buf (format "*jami-capture-%s-%s*" account conversation))
         (continue (get-buffer buf))
         (displayname (cadr (assoc-string "displayName" msg)))
         ;; use inactive timestamps
         (timefmt (concat "[" (substring (cdr org-time-stamp-formats) 1 -1) "]")))
    (with-current-buffer (get-buffer-create buf)
      (let ((link
             ;; link to downloaded file
             (concat "file:"
                     (condition-case nil
                         ;; try to create a link relative to the target capture file
                         (file-relative-name dlname
                                             (file-name-directory
                                              (org-capture-expand-file
                                               (cadr (nth 3 (assoc
                                                             org-jami-bot-capture-key
                                                             org-capture-templates))))))
                       ;; if this fails, use the absolute path instead
                       (error dlname)))))
        (insert (if continue
                    ;; multi message capture
                    (concat
                     "#+ATTR_ORG: :width 400\n"
                     (org-link-make-string link) "\n")
                  ;; single message capture
                  (format "* FILE %s :FILE:\n:PROPERTIES:\n:CREATED: %s\n:END:\n\n#+ATTR_ORG: :width 400\n%s\n"
                          (org-link-make-string link displayname)
                          (format-time-string timefmt)
                          (org-link-make-string link)))))
      ;; store link for easy linking
      (push (list dlname displayname) org-stored-links)
      (jami-bot-reply-to-message
       account
       conversation
       msg
       (if continue
           "file added. Finish capture with \"!done\""
         (if (and (org-capture-string
                   (buffer-string)
                   org-jami-bot-capture-key)
                  (kill-buffer buf))
             "captured!"
           "error during org-capture :("))))))

(defun org-jami-bot--command-function-today (_account _conversation msg)
  "Capture body of message as todo entry scheduled today.

 Returns a reply string as confirmation. MSG is the full message
 in CONVERSATION id for ACCOUNT id."
  (let* ((body (cadr (assoc-string "body" msg)))
         (lines (string-lines body))
         ;; use inactive timestamps
         (timefmt (concat "[" (substring (cdr org-time-stamp-formats) 1 -1) "]")))

          (if (org-capture-string
               (format "* TODO %s\nSCHEDULED: %s\n:PROPERTIES:\n:CREATED: %s\n:END:\n%s"
                       (car lines)
                       (format-time-string (car org-time-stamp-formats))
                       (format-time-string timefmt)
                       (string-join (cdr lines) "\n"))
            org-jami-bot-capture-key)
           "captured and scheduled!"
        "error during org-capture :(")))

(defun org-jami-bot--command-function-schedule (_account _conversation msg)
  "Capture body as todo entry and schedule it on the date given after the command.

The entry will be scheduled according to the first line of the
MSG body immediately following the command string. The date will
be parsed through `org-read-date' and supports the same
string-to-date conversations. Returns a reply string as
confirmation. ACCOUNT and CONVERSATION are not used."
  (let* ((body (cadr (assoc-string "body" msg)))
         (lines (string-lines body))
         (swhen (org-read-date nil nil (car lines)))
         ;; inactive timestamp
         (timefmt (concat "[" (substring (cdr org-time-stamp-formats) 1 -1) "]")))
    (if (org-capture-string
         (format "* TODO %s\nSCHEDULED: %s\n:PROPERTIES:\n:CREATED: %s\n:END:\n%s"
                 (cadr lines)
                 swhen
                 (format-time-string timefmt)
                 (string-join (cdr lines) "\n"))
            org-jami-bot-capture-key)
           (format "captured and scheduled on %s!" swhen)
        "error during org-capture :(")))

(defun org-jami-bot-default-setup ()
  "Set up `org-jami-bot' with default values.

        Create a capture template, extend `jami-bot' commands via
        `jami-bot-command-function-alist' and add hooks to
        `jami-bot'."
  (if (assoc org-jami-bot-capture-key org-capture-templates)
      (message "Capture template referred to by \"%s\" key already defined!"
               org-jami-bot-capture-key)
    (add-to-list 'org-capture-templates
                 `(,org-jami-bot-capture-key "Jami message"
                   entry (file org-default-notes-file)
                   "%i" :immediate-finish t)))

  (dolist (cmd
           '(("!today" . org-jami-bot--command-function-today)
             ("!schedule" . org-jami-bot--command-function-schedule)
             ("!start" . org-jami-bot--command-function-start)
             ("!done" . org-jami-bot--command-function-done)))
    (add-to-list 'jami-bot-command-function-alist cmd))

  (add-hook 'jami-bot-text-message-functions #'org-jami-bot--capture-plain-messsage)
  (add-hook 'jami-bot-data-transfer-functions #'org-jami-bot--capture-file))

(provide 'org-jami-bot)
;;; org-jami-bot.el ends here
