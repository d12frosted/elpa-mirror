;;; chatwork.el --- ChatWork client for Emacs
;; -*- Mode: Emacs-Lisp -*-

;; Copyright (C) 2014, 2015, 2016, 2017 Masayuki Ataka <masayuki.ataka@gmail.com>

;; Author: Masayuki Ataka <masayuki.ataka@gmail.com>
;; URL: https://github.com/ataka/chatwork
;; Package-Version: 20170511.442
;; Package-Commit: fea231d479f06bf40dbfcf45de143eecc9ed744c
;; Keywords: web
;; Version: 0.2

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, you can either send email to this
;; program's maintainer or write to: The Free Software Foundation,
;; Inc.; 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.

;;; Commentary:

;; chatwork.el provides chatwork-mode for sending messages to ChatWork.

;; Set your ChatWork API token, which you can get from
;; https://www.chatwork.com/service/packages/chatwork/subpackages/api/apply_beta.php
;;
;; Example:
;;
;;  (setq chatwork-token "YOUR CHATWORK API TOKEN")
;;
;; `chatwork' command open a draft buffer for selected room.
;; Write a message, then type `C-cC-c'.

;;; Code:

(require 'url)
(require 'json)

;;; Custom Variables

(defgroup chatwork nil
  "ChatWork configuration."
  :group 'comm)

(defcustom chatwork-token nil
  "ChatWork API Token."
  :type 'string
  :group 'chatwork)

(defcustom chatwork-to-tag-prefix ""
  "Prefix of To tag."
  :type 'string
  :group 'chatwork)

(defcustom chatwork-to-tag-suffix ""
  "Suffix of To tag."
  :type 'string
  :group 'chatwork)

(defcustom chatwork-member-alias-alist nil
  "Alist of members which cons cell is `(\"alias\" . ACCOUNT_ID)'
You can use a list of ACCOUNT_IDs; `(\"alias\" . (ACCUONT_ID ACCOUNT_ID))'

ACCOUNT_ID should be number."
  :type '(alist :key-type (string :tag "Alias")
                :value-type (choice integer (sexp integer)))
  :group 'chatwork)

(defcustom chatwork-member-separator ", "
  "String to separate multiple members
See `chatwork-member-alias-alist'.")

;; System Variables

(defconst chatwork-api-base-url "https://api.chatwork.com/v2"
  "Base URL of ChatWork API.
Refecernce available at http://developer.chatwork.com/ja/endpoints.html")

(defvar chatwork-me-plist nil)
(defvar chatwork-contact-plist nil)
(defvar chatwork-contact-name-alist nil
  "Alist of Contact which cons cell is `(NAME . ACCOUNT_ID)'")
(defvar chatwork-contact-id-alist nil
  "Alist of Contact which cons cell is `(CHATWORK_ID . ACCOUNT_ID)'")
(defvar chatwork-room-plist nil)
(defvar chatwork-room-alist nil
  "Alist of Rooms which cons cell is `(ROOM_NAME . ROOM_ID)'")
(defvar chatwork-room-history nil)

(defvar chatwork-stamp-alist nil
  "Alist of Stamp whic cons cell is `(\"alias\" . \"Stamp strings\")'")
(defvar chatwork-page-delimiter "\014")

;; System Variables for chatwork-mode

(defvar chatwork-buffer-name-format "*chatwork: %s*")
(defvar chatwork-buffer-name nil)
(make-variable-buffer-local 'chatwork-buffer-name)
(defvar chatwork-room-name nil)
(make-variable-buffer-local 'chatwork-room-name)
(defvar chatwork-room-plist nil)
(make-variable-buffer-local 'chatwork-room-plist)
(defvar chatwork-last-buffer nil)
(defvar chatwork-member-plist nil)
(make-variable-buffer-local 'chatwork-member-plist)
(defvar chatwork-member-alist nil)
(make-variable-buffer-local 'chatwork-member-alist)

;;; Connectivity

(defun chatwork-api-url (endpoint)
  "Return URL for ChatWork API with `chatwork-api-base-url' and ENDPOINT"
  (concat chatwork-api-base-url endpoint))

(defmacro chatwork-get (path callback)
  "Send GET request to ChatWork

PATH sould start with \"/\".
CALLBACK sould be a callback function"
  `(let ((url-request-method "GET")
         (url-request-extra-headers `(("X-ChatWorkToken" . ,chatwork-token))))
     (url-retrieve (chatwork-api-url ,path) ,callback nil t)))

(defun chatwork-me ()
  (chatwork-get "/me" 'chatwork-me-callback))

(defun chatwork-me-callback (status)
  (unless (plist-get status :error)
    (let ((json-object-type 'plist))
      (unwind-protect
          (let ((json-data (progn (chatwork-callback-skip-header)
                                  (json-read))))
            (setq chatwork-me-plist json-data))
        (kill-buffer)))))

(defalias 'chatwork-update-rooms 'chatwork-get-rooms)

(defun chatwork-get-rooms ()
  (interactive)
  (chatwork-get "/rooms" 'chatwork-get-rooms-callback))

(defun chatwork-get-rooms-callback (status)
  (unless (plist-get status :error)
    (let ((json-object-type 'plist))
      (unwind-protect
          (let ((json-data (progn (chatwork-callback-skip-header)
                                  (json-read))))
            (setq chatwork-room-plist json-data)
            (setq chatwork-room-alist
                  (mapcar (lambda (room)
                            (let ((room-id   (plist-get room :room_id))
                                  (room-name (plist-get room :name)))
                              (cons room-name room-id)))
                          chatwork-room-plist)))
        (kill-buffer)))))

(defun chatwork-get-members (room-id)
  (interactive "")
  (chatwork-get (format "/rooms/%d/members" room-id) 'chatwork-get-members-callback))

(defun chatwork-get-members-callback (status)
  (unless (plist-get status :error)
    (let ((json-object-type 'plist))
      (unwind-protect
          (let ((json-data (progn (chatwork-callback-skip-header)
                                  (json-read))))
            (with-current-buffer chatwork-last-buffer
              (setq chatwork-member-plist json-data)
              (setq chatwork-room-plist
                    (plist-put chatwork-room-plist :member_name
                               (mapcar (lambda (member)
                                         (let ((account-id (plist-get member :account_id))
                                               (name       (plist-get member :name)))
                                           (cons account-id name)))
                                       chatwork-member-plist)))
              (setq chatwork-member-alist `(
                    ,@(mapcar (lambda (member)
                                (let ((account-id (plist-get member :account_id))
                                      (name       (plist-get member :name)))
                                  (cons name account-id)))
                              chatwork-member-plist)
                    ,@(mapcar (lambda (member)
                                (let ((account-id  (plist-get member :account_id))
                                      (chatwork-id (plist-get member :chatwork_id)))
                                  (cons chatwork-id account-id)))
                              chatwork-member-plist)))))
        (kill-buffer)))))

(defalias 'chatwork-update-contacts 'chatwork-get-contacts)

(defun chatwork-get-contacts ()
  (interactive)
  (chatwork-get "/contacts" 'chatwork-get-contacts-callback))

(defun chatwork-get-contacts-callback (status)
  (unless (plist-get status :error)
    (let ((json-object-type 'plist))
      (unwind-protect
          (let ((json-data (progn (chatwork-callback-skip-header)
                                  (json-read))))
            (setq chatwork-contact-plist json-data)
            (setq chatwork-contact-name-alist
                  (mapcar (lambda (contact)
                            (let ((account-id (plist-get contact :account_id))
                                  (name       (plist-get contact :name)))
                              (cons name account-id)))
                          chatwork-contact-plist)
                  chatwork-contact-id-alist
                  (mapcar (lambda (contact)
                            (let ((account-id  (plist-get contact :account_id))
                                  (chatwork-id (plist-get contact :chatwork_id)))
                              (cons chatwork-id account-id)))
                          chatwork-contact-plist)))
        (kill-buffer)))))

(defun chatwork-find-room-id-by-room-name (&optional room-name)
  (let* ((rooms (progn (chatwork-ensure-room-alist) chatwork-room-alist)))
    (unless room-name
      (setq room-name (let ((completion-ignore-case t)) (completing-read "Room: " rooms nil nil nil 'chatwork-room-history (car chatwork-room-history)))))
    (cdr (assoc room-name rooms))))

;;;###autoload
(defun chatwork-send-message-at-point ()
  "Send message to ChatWork

Call `chatwork-send-message-in-page', if chatwork-mode and mark is not active.
Call `chatwork-send-message-in-region', if mark is active.
Call `chatwork-send-message', if mark is not active and not chatwork-mode."
  (interactive)
  (cond
   ((and (eq major-mode 'chatwork-mode) chatwork-room-name (not mark-active))
    (call-interactively 'chatwork-send-message-in-page))
   (mark-active
    (call-interactively 'chatwork-send-message-in-region))
   (t
    (call-interactively 'chatwork-send-message))))

;;;###autoload
(defun chatwork-send-message (message room-id)
  "Send MESSAGE to ROOM-ID

ROOM-ID is an id number of the room."
  (interactive (list (read-string "Message: ")
                     (chatwork-find-room-id-by-room-name)))
  (chatwork-post-message message room-id))

;;;###autoload
(defun chatwork-send-message-in-region (beg end room-id)
  "Send text in region to ROOM-ID

ROOM-ID is an id number of the room."
  (interactive (let ((room-id (chatwork-find-room-id-by-room-name chatwork-room-name)))
                 (list (region-beginning) (region-end) room-id)))
  (let ((message (buffer-substring-no-properties beg end)))
    (chatwork-post-message message room-id)))

(defun chatwork-send-message-in-page (room-id)
  "Send text in page to ROOM-ID

ROOM-ID is an id number of the room."
  (interactive (let ((room-id (chatwork-find-room-id-by-room-name chatwork-room-name)))
                 (list room-id)))
  (let* ((page-delimiter (concat "^" chatwork-page-delimiter))
     (beg (progn (backward-page) (point)))
         (end (progn (forward-page) (skip-chars-backward chatwork-page-delimiter) (point)))
         (message (buffer-substring-no-properties beg end)))
    (chatwork-post-message message room-id))
  (goto-char (point-max))
  (insert "\n" chatwork-page-delimiter))

(defun chatwork-send-stamp (stamp room-id)
  "Send STAMP to ROOM-ID

STAMP is car of cons cell in `chatwork-stamp-alist'.
ROOM-ID is an ad number of the room."
  (interactive (list (completing-read "Stamp: " chatwork-stamp-alist)
             (chatwork-find-room-id-by-room-name chatwork-room-name)))
  (chatwork-post-message (cdr (assoc stamp chatwork-stamp-alist))
                         room-id))

(defun chatwork-ensure-room-alist ()
  (unless chatwork-room-alist
    (chatwork-update-rooms))
  (while (not chatwork-room-alist)
    (sleep-for 1)))

(defmacro chatwork-post (path data)
  "Send POST request to ChatWork

PATH should start with \"/\".
DATA should be decoded with `html-hexify-string' if they contains multibyte."
  `(let ((url-request-method "POST")
         (url-request-extra-headers `(("Content-Type" . "application/x-www-form-urlencoded")
                                      ("X-ChatWorkToken" . ,chatwork-token)))
         (url-request-data ,data))
     (url-retrieve (chatwork-api-url ,path)
                   'chatwork-post-callback)))

(defun chatwork-post-message (message room-id)
  "Send MESSAGE to ROOM in ChatWork"
  (interactive)
  (chatwork-post (format "/rooms/%d/messages" room-id)
                 (concat "body=" (url-hexify-string message))))

(defun chatwork-post-callback (status)
  (unwind-protect
      (message "done!")
    (kill-buffer)))

(defun chatwork-callback-skip-header ()
  (search-forward "\n\n" nil t))

;;; ChatWork mode

;;;###autoload
(defun chatwork ()
  "Call Chatwork major mode"
  (interactive)
  (unless chatwork-contact-plist
    (chatwork-get-contacts))
  (let* ((room-name (chatwork-select-room))
         (buffer-name (chatwork-buffer room-name)))
    (setq chatwork-last-buffer (pop-to-buffer buffer-name))
    (chatwork-mode)
    (chatwork-get-members (cdr (assoc room-name chatwork-room-alist)))
    (setq chatwork-room-name room-name
          chatwork-buffer-name buffer-name)))

(define-derived-mode chatwork-mode
  text-mode "ChatWork"
  "Major mode for ChatWork.

\\{chatwork-mode-map}"
)

;;
;; key map
;;

(let ((map chatwork-mode-map))
  (define-key map "\C-c\C-c" 'chatwork-send-message-at-point)
  (define-key map "\C-c\C-f" 'chatwork)
  (define-key map "\C-c\C-b" 'chatwork-switch-to-room)
  ;; Tag
  (define-key map "\C-c\C-i\C-t" 'chatwork-insert-tag-to)
  (define-key map "\C-c\C-i\C-i" 'chatwork-insert-tag-info)
  (define-key map "\C-c\C-i\C-c" 'chatwork-insert-tag-code)
  (define-key map "\C-c\C-i\C-h" 'chatwork-insert-tag-hr)
  (define-key map "\C-c\C-i\C-s" 'chatwork-send-stamp)
  (define-key map "`" 'chatwork-electric-backquote)
)

;;
;; Functions for chatwork-mode
;;

(defun chatwork-select-room ()
  (let* ((rooms (progn (chatwork-ensure-room-alist) chatwork-room-alist))
         (room-name (let ((completion-ignore-case t)) (completing-read "Room: " rooms nil nil nil 'chatwork-room-history (car chatwork-room-history)))))
    room-name))

(defun chatwork-buffer (room-name)
  (format chatwork-buffer-name-format room-name))

(defun chatwork-switch-to-room (room-name)
  "Display room ROOM-NAME in the selected window"
  (interactive (list (let ((completion-ignore-case t)
               (active-rooms
                (delq nil (mapcar
                       (lambda (buf)
                     (let ((name (buffer-name buf)))
                       (when (string-match "\\*chatwork: \\(.+\\)\\*" name)
                         (match-string-no-properties 1 name))))
                       (buffer-list)))))
               (completing-read "Room: " active-rooms nil nil nil 'chatwork-room-history (car chatwork-room-history)))))
  (switch-to-buffer (chatwork-buffer room-name)))

(defun chatwork-electric-backquote (arg)
  "Insert a backquote.
Insert code tag if line begin with ```."
  (interactive "*P")
  (self-insert-command (prefix-numeric-value arg))
  (when (looking-back (concat "^" chatwork-page-delimiter "?```"))
    (replace-match "")
    (chatwork-insert-tag-code)))

;;; Tag

;; [To:{account_id}] Name
;; [rp aid={account_id} to={room_id}-{message_id}] Name
;; [qt][qtmeta aid={account_id} time={timestamp}] ... [/qt]
;; [info] ... [/info]
;; [info][title]title[/title] ... [/info]
;; [code] ... [/code]
;; [hr]
;; [picon:{account_id}]
;; [piconname:{account_id}]


(defun chatwork-insert-tag-to (members)
  "Insert ChatWork To tag and its Name

MEMBERS should be a list of account-id numbers or alias string,
which is defined in `chatwork-member-alias-alist'.

If chatwork-mode, non-members in the room are ignored.

For the insert tag format, see custom variables
`chatwork-to-tag-prefix', `chatwork-to-tag-suffix' and
`chatwork-member-separator'."
  (interactive (list (completing-read-multiple "To: " `(,@chatwork-member-alist ,@chatwork-member-alias-alist))))
  (let* ((format-base (format "[To:%%d] %s%%s%s"
                              chatwork-to-tag-prefix
                              chatwork-to-tag-suffix))
         (account-id-list
          (mapcar
           (lambda (member)
             (let ((account  (cdr (assoc member chatwork-member-alist)))
                   (accounts (cdr (assoc member chatwork-member-alias-alist))))
               (cond
                ((numberp account)  account)
                ((numberp accounts) accounts)
                ((listp   accounts)
                 (mapcar (lambda (account-id)
                           (when (or (not (eq major-mode 'chatwork-mode))
                                     (rassoc account-id chatwork-member-alist))
                             account-id))
                         accounts)))))
             members)))
    (insert
     (mapconcat
      (lambda (account-id)
        (format format-base account-id (chatwork-member-name-by-account-id account-id)))
      (delq nil (delete-dups (chatwork-flatten1 account-id-list)))
      chatwork-member-separator) "\n")))

(defun chatwork-flatten1 (sequence)
  (let (acc)
    (dolist (elt (reverse sequence) acc)
      (setq acc (funcall (if (listp elt) #'append #'cons) elt acc)))))

(defun chatwork-member-name-by-account-id (account-id)
  (if (eq major-mode 'chatwork-mode)
      (cdr (assoc account-id (plist-get chatwork-room-plist :member_name)))
    (or chatwork-contact-name-alist (chatwork-get-contacts))
    (or (car (rassoc account-id chatwork-contact-name-alist))
        (progn
          (or chatwork-me-plist (chatwork-me))
          (when (eq account-id (plist-get chatwork-me-plist :account_id))
              (plist-get chatwork-me-plist :name))))))

(defun chatwork-insert-tag-info (arg)
  (interactive "P")
  (let ((title (when arg
                 (read-string "Title: "))))
    (insert "[info]")
    (when title
      (insert (concat "[title]" title "[/title]")))
    (save-excursion
      (insert "[/info]\n"))))

(define-skeleton chatwork-insert-tag-code
  "Insert tag tag."
  > "[code]\n"
  _
  "\n[/code]\n"
)

(defun chatwork-insert-tag-hr ()
  (interactive)
  (insert "[hr]"))

(provide 'chatwork)

;;; chatwork.el ends here
