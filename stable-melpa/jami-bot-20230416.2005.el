;;; jami-bot.el --- An extendable chat bot for the private messenger GNU Jami -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 Hanno Perrey
;;
;; Author: Hanno Perrey <http://gitlab.com/hperrey>
;; Maintainer: Hanno Perrey <hanno@hoowl.se>
;; Created: April 15, 2023
;; Modified: April 15, 2023
;; Version: 0.0.1
;; Package-Version: 20230416.2005
;; Package-Commit: 21673c5844f9a1ea9ba49f1a68c72b1fe7cb9f91
;; Keywords: comm, jami, messenger, chat bot, dbus
;; Homepage: https://gitlab.com/hperrey/jami-bot
;; Package-Requires: ((emacs "27.1"))
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
;; An extendable chat bot for the distributed, private messenger Jami. It
;; interacts with the locally-installed Jami daemon via D-Bus and reacts to
;; both plain text messages and file transfers sent to local accounts. Further
;; processing of either or both can be configured by adding functions to the
;; abnormal hooks, `jami-bot-text-message-functions' and
;; `jami-bot-data-transfer-functions', respectively.
;;
;; Additionally, the bot allows special actions to be triggered by sending a
;; text message starting with an exclamation mark and a command keyword.
;; Further commands than the ones included can be configured by mapping them to
;; functions through `jami-bot-command-function-alist'.
;;
;; Set up `jami-bot' by executing `jami-bot-register'. This will set up the
;; message handler, `jami-bot--messageReceived-handler', to be called on the
;; `messageReceived' D-Bus signal.
;;
;;; Code:

(require 'dbus)

(defvar jami-bot-account-user-names nil
  "List of account user names that `jami-bot' handles messages for.

        If set to nil then `jami-bot' will react to any message
        send to a local account. The user name is also sometimes
        referred to as address in Jami and should be a 40
        character has such as
        \"badac18e13ec1a6e1266600e457859afebfb9c46\".")

(defvar jami-bot-command-function-alist
  '(("!ping" . jami-bot--command-function-ping)
    ("!help" . jami-bot--command-function-help))
  "Alist mapping command strings in message body to functions to be executed.

Each command needs to start with an exclamation mark '!' and
consist of a single (lowercase) word. The corresponding function needs to accept
the account id, the conversation id and the message alist as
arguments and return a string (that is sent as reply to the original message).")

(defvar jami-bot-text-message-functions nil
  "A list of functions that will be called when processing a plain text message.

Functions must take the ACCOUNT and CONVERSATION ids as well as
the actual MSG as arguments. Their return value will be ignored.")

(defvar jami-bot-download-path "~/jami/"
"Path in which to store files downloaded from conversations.

Will be created if not existing yet.")

(defvar jami-bot-data-transfer-functions nil
  "A list of functions that will be called when processing a data transfer message.

Functions must take the ACCOUNT and CONVERSATION ids as well as
the actual MSG and the local downloaded file name, DLNAME, as
arguments. Their return value will be ignored.")

(defvar jami-bot--jami-local-account-ids nil
  "List of `jami' local accounts user ids and name pairs.

Caches output of dbus-methods 'getAccountList' and
'getAccountDetails'. For internal use in `jami-bot'.")

(defun jami-bot--messageReceived-handler (account conversation msg)
  "Handle messages from Jami's `messageReceived' D-Bus signal.

  ACCOUNT and CONVERSATION are the corresponding ids to which the
  MSG belongs to. The latter contains additional fields such as
  `author' and `body'. The field `type' is used to identify which
  function to call for further processing."
  ;; make sure we are not reacting to messages sent from our own local
  ;; account(s) or accounts we are not to monitor
  (unless jami-bot--jami-local-account-ids
    (jami-bot--refresh-accountid-list))
  (let ((author (cadr (assoc "author" msg)))
        (type (cadr (assoc "type" msg))))
    (when (or
           (and jami-bot-account-user-names
                 ;; account id should match a user name to be monitored
                 (member (car (rassoc account jami-bot--jami-local-account-ids))
                         jami-bot-account-user-names)
                 ;; .. but msg should not be authored by ourselves
                 (not (member author jami-bot-account-user-names)))
            ;; no account filter: check msg not from local account
           (and (not jami-bot-account-user-names)
                (not (assoc author jami-bot--jami-local-account-ids))))
      (message "jami-bot received %s message from %s on account %s." type author account)
      (pcase type
        ("text/plain"
         (jami-bot--process-text-message
          account
          conversation
          msg))
        ("application/data-transfer+json"
         (jami-bot--process-data-transfer
          account
          conversation
          msg))
        ;; ignore merges of the conversation; usually transparent to the user
        ;; anyway
        ("merge" (ignore))
        ;; ignore new members joining
        ("member" (ignore))
        (_
         (jami-bot--process-unknown-type
          account
          conversation
          msg))))))

(defun jami-bot--process-unknown-type (account conversation msg)
"Handle messages of unknown type by sending an error message as reply.

  ACCOUNT and CONVERSATION are the corresponding ids to which the
  MSG belongs to."
  (let ((type (cadr (assoc "type" msg))))
    (message "Error: received message with unkonwn type: %s" type)
    (jami-bot-reply-to-message
     account
     conversation
     msg
     (format "Unknown message type: %s" type))))

(defun jami-bot-select-and-insert-local-account ()
  "Prompt user for a local Jami user account and insert id at position."
  (interactive)
  (jami-bot--refresh-accountid-list)
  (insert (completing-read "Pick a account user name to insert: " jami-bot--jami-local-account-ids)))

(defun jami-bot-register ()
  "Ping the Jami daemon and register `jami-bot' handler for receiving messages."
  (interactive)
  (or (dbus-ping :session "cx.ring.Ring")
      (error "Jami Daemon (jamid) not available through dbus. Please check Jami installation"))
  (dbus-register-signal :session "cx.ring.Ring"
                      "/cx/ring/Ring/ConfigurationManager"
                      "cx.ring.Ring.ConfigurationManager"
                      "messageReceived"
                      #'jami-bot--messageReceived-handler))

(defun jami-bot--process-text-message (account conversation msg)
  "Process plain text messages and parse the message body for commands.

  ACCOUNT and CONVERSATION are the corresponding ids to which the
  message MSG belongs to. Messages containing commands must start
  with an exclamation mark (\"!\") followed by the single-word
  command. Each command is mapped to a function via
  `jami-bot-command-function-alist' which will be executed when
  the command is received.

  If the message does not start with an exclamation mark, the
  abnormal hook `jami-bot-text-message-functions' will be run for
  further processing."
  (let ((body (cadr (assoc-string "body" msg))))
    ;; check for criteria handling first line of body as command
    ;;  - string starts with '!' and is a single word
    (if (string-prefix-p "!" body)
        ;; command in msg body
        (let*
            ((cmd (downcase (substring body 0 (string-match-p "[^[:word:]!]" body))))
             (fcn (cdr (assoc-string cmd jami-bot-command-function-alist))))
          ;; remove the command from the message body
          (setcdr (assoc-string "body" msg)
                  (list (string-trim-left (string-remove-prefix cmd body))))
          (if fcn
            ;; call function and reply with return value
            (jami-bot-reply-to-message
             account
             conversation
             msg
             (funcall fcn account conversation msg))
            ;; no matching command defined:
            ;; report error as reply to msg
            (jami-bot-reply-to-message
             account
             conversation
             msg
             (format "Unknown command: %s" cmd))))
      ;; not a command in msg body: run hook instead
      (run-hook-with-args 'jami-bot-text-message-functions
                          account conversation msg))))

(defun jami-bot--command-function-ping (_account _conversation msg)
  "Return the string 'pong!' followed by the message's body.

Example for a basic jami bot command handling function. Acts on MSG
received via _ACCOUNT in _CONVERSATION. The latter two are unused."
  (let ((body (cadr (assoc-string "body" msg))))
    (format "pong! %s" body)))

(defun jami-bot--command-function-help (_account _conversation _msg)
  "Return a summary of available commands.

Acts on _MSG received via _ACCOUNT in _CONVERSATION, none of
which are used."
  (let (result)
    (dolist (cmd jami-bot-command-function-alist (string-join result "\n"))
      (push (concat "- " (car cmd) " :: "
                    (car (split-string (documentation (cdr cmd)) "\n"))) result))))

(defun jami-bot--process-data-transfer (account conversation msg)
  "Process data transfer from received messages.

  Downloads files to the path given by `jami-bot-download-path'
  and calls the abnormal hook `jami-bot-data-transfer-functions'
  for further processing. ACCOUNT and CONVERSATION are the
  corresponding ids to which the message MSG belongs to."
  (let* ((id (cadr (assoc-string "id" msg)))
         (fileid (cadr (assoc-string "fileId" msg)))
         (filename (cadr (assoc-string "displayName" msg)))
         (dlpath (file-name-as-directory
                  (expand-file-name jami-bot-download-path)))
         (dlname (concat dlpath (format-time-string "%Y%m%d-%H%M") "_" filename)))
    (unless (file-directory-p dlpath) (make-directory dlpath 't))
    (message "jami-bot: downloading file %s" dlname)
    (jami-bot--dbus-cfgmgr-call-method "downloadFile" account conversation id fileid dlname)
    (run-hook-with-args 'jami-bot-data-transfer-functions account conversation msg dlname)))

(defun jami-bot--dbus-cfgmgr-call-method (method &rest args)
  "Call Jami ConfigurationManager dbus METHOD with arguments ARGS."
  (apply #'dbus-call-method `(:session
                    "cx.ring.Ring"
                    "/cx/ring/Ring/ConfigurationManager"
                    "cx.ring.Ring.ConfigurationManager"
                    ,method ,@(when args args))))

(defun jami-bot-send-message (account conversation text &optional reply)
  "Add TEXT to CONVERSATION via ACCOUNT. REPLY specifies a message id."
  (jami-bot--dbus-cfgmgr-call-method "sendMessage"
                                     account
                                     conversation
                                     text
                                     `(,@(if reply reply ""))
                                     :int32 0))

(defun jami-bot-reply-to-message (account conversation msg text)
  "Add TEXT as a reply to MSG in CONVERSATION via ACCOUNT."
  (let ((id (cadr (assoc-string "id" msg))))
    (jami-bot-send-message account conversation text id)))

(defun jami-bot--refresh-accountid-list ()
  "Update cached values of known local account ids.

The values are stored in `jami-bot--jami-local-account-ids'."
  (let ((accounts (jami-bot--dbus-cfgmgr-call-method
                   "getAccountList")))
    (let ((value))
      (dolist (acc accounts)
        (push (cons (cadr (assoc-string
                           "Account.username"
                           (jami-bot--dbus-cfgmgr-call-method
                            "getAccountDetails"
                            acc))) acc)
              value))
      (setq jami-bot--jami-local-account-ids value)))
  jami-bot--jami-local-account-ids)

(provide 'jami-bot)
;;; jami-bot.el ends here
