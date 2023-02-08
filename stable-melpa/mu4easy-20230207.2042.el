;;; mu4easy.el --- Packages + configs for using mu4e with multiple accounts    -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2023  Daniel Fleischer

;; Author: Daniel Fleischer <danflscr@gmail.com>
;; Keywords: mail
;; Package-Version: 20230207.2042
;; Package-Commit: 34565ddb9fc74675b28ce19694485cf2e91eba20
;; Homepage: https://github.com/danielfleischer/mu4easy
;; Version: 1.0
;; Package-Requires: ((emacs "25.1") (mu4e-column-faces "1.2.1") (mu4e-alert "1.0") (helm-mu "1.0.0") (org-msg "4.0"))

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

;; This package contains a collection of packages and configurations
;; making it easy and fun to use email with Emacs using mu, mu4e, mbsync
;; and other improvements. The setup supports multiple email providers
;; such as Google, Apple, GMX and Proton. In addition to this elisp
;; package, there is an mbsync configuration that needs to be changed
;; and copied manually.

;;; Code:
(require 'smtpmail)
(require 'mu4e)
(require 'mu4e-icalendar)
(require 'mu4e-contrib)
(require 'mu4e-column-faces)
(require 'mu4e-alert)
(require 'helm-mu)
(require 'org-msg)

(defgroup mu4easy nil
  "Easy configuration for mu4e."
  :group 'mail)

(defcustom mu4easy-accounts '("Gmail" "GMX" "Apple" "Proton")
  "List of email accounts names, as defined on disk."
  :type '(repeat string))

(defcustom mu4easy-greeting "Hi%s,\n\n"
  "Email greeting where %s is the first name of 1-2 recipients.
See also `org-msg-greeting-fmt'."
  :type '(string))

(defcustom mu4easy-signature "\n\n*Daniel Fleischer*"
  "Signature; supports org syntax thanks to org-msg."
  :type '(string))

(defcustom mu4easy-download-dir "~/Downloads"
  "Location of downloads dir."
  :type '(directory))

;;; Variables
(defun mu4easy-mail-link-description (msg)
  "Creating a link description to be used with `org-store-link'.
Argument MSG msg at point."
  (let ((subject (or (plist-get msg :subject)
                     "No subject"))
        (date (or (format-time-string mu4e-headers-date-format
                                      (mu4e-msg-field msg :date))
                  "No date"))
        (to-from (mu4e~headers-from-or-to msg)))
    (format "%s: %s (%s)" to-from subject date)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Hooks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mu4easy--org-msg-hook ()
  "Settings for org-msg mode."
  (set-fill-column 120)
  (turn-on-auto-fill)
  (electric-indent-local-mode -1)
  (turn-on-flyspell))

(defun mu4easy--compose-hook ()
  "Settings for mu4e compose mode."
  (set-fill-column 120)
  (turn-on-auto-fill)
  (electric-indent-local-mode -1)
  (turn-on-flyspell))

(defun mu4easy--update-buffer ()
  "Revert buffer when switching to mu4e to update the stats."
  (when (derived-mode-p 'mu4e-main-mode)
    (revert-buffer)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Update specific accounts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mu4easy-update-custom-account ()
  "Run mbsync update for a specific account."
  (interactive)
  (let ((account (completing-read
                  "Select account: "
                  (cons "All" mu4easy-accounts) nil t nil nil "All"))
        (command (format "INSIDE_EMACS=%s mbsync " emacs-version)))
    (pcase account
      ("All" (concat command "-a"))
      (else (concat command else)))))

(defun mu4easy-update-mail-and-index ()
  "Run a mu4e update; if prefix, focus on a specific account."
  (interactive)
  (mu4e-kill-update-mail)
  (if current-prefix-arg
      (let ((mu4e-get-mail-command (mu4easy-update-custom-account)))
        (mu4e-update-mail-and-index nil))
    (mu4e-update-mail-and-index nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Trash without trashed flag
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setf (alist-get 'trash mu4e-marks)
      '(:char ("d" . "▼")
              :prompt "dtrash"
              :dyn-target (lambda (target msg) (mu4e-get-trash-folder msg))
              ;; Here's the main difference to the regular trash mark, no +T
              ;; before -N so the message is not marked as IMAP-deleted:
              :action (lambda (docid msg target)
                        (mu4e--server-move docid (mu4e--mark-check-target target) "+S-u-N"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Consistent Refile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setf (alist-get 'refile mu4e-marks)
      '(:char ("r" . "▶")
              :prompt "refile"
              :dyn-target (lambda (target msg) (mu4e-get-refile-folder msg))
              :action (lambda (docid msg target)
                        (mu4e--server-move docid (mu4e--mark-check-target target) "+S-u-N"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Respond in text-mode if prefix
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sometimes I want to respond in text to HTML messages
;; e.g. when participating in github discussions using email
(defun mu4easy-org-msg-select-format (alternative)
  "Wrapping function to override email format (html/text).
Argument ALTERNATIVE passthrough argument when advising."
  (if current-prefix-arg '(text) alternative))


;; Text Mode Signature
(defun mu4easy-customize-org-msg (orig-fun &rest args)
  "Fix for signature and greeting when email is text.
Argument ORIG-FUN function being advised.
Optional argument ARGS ."
  (let ((res (apply orig-fun args)))
    (when (equal (cadr args) '(text))
      (setf (alist-get 'signature res)
            (replace-regexp-in-string "\\([\*/]\\)" ""
                                      org-msg-signature))
      (setf (alist-get 'greeting-fmt res) ""))
    res))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Macro for Contexts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(cl-defmacro mu4easy-context (&key c-name maildir mail smtp
                                   (smtp-mail mail)
                                   (smtp-port 587)
                                   (smtp-type 'starttls)
                                   (sent-action 'sent)
                                   (name user-full-name)
                                   (sig mu4easy-signature))
  "Main macro for creating email accounts (contexts).
See examples in the README file.

C-NAME context name, used in mu4e UI; first letter is going to be
    used as a shortcut.
MAILDIR mail dir under path/Mail/...
MAIL email address or alias.
SMTP address.
SMTP-MAIL email address for this account (not alias).
SMTP-TYPE default `starttls'.
SMTP-PORT default 587.
SENT-ACTION what to do after sending an email (copy to `sent' or delete);
    see README.
NAME name can be set per account.
SIG signature string; supports org formatting thanks to org-msg."
  (let
      ((inbox  (concat "/" maildir "/Inbox"))
       (sent   (concat "/" maildir "/Sent"))
       (trash  (concat "/" maildir "/Trash"))
       (refile (concat "/" maildir "/Archive"))
       (draft  (concat "/" maildir "/Drafts"))
       (spam   (concat "/" maildir "/Spam")))
    
    `(make-mu4e-context
      :name ,c-name
      :match-func (lambda (msg)
                    (when msg
                      (string-match-p (concat "^/" ,maildir "/")
                                      (mu4e-message-field msg :maildir))))
      :vars '((user-mail-address . ,mail)
              (user-full-name . ,name)
              (mu4e-sent-folder . ,sent)
              (mu4e-drafts-folder . ,draft)
              (mu4e-trash-folder . ,trash)
              (mu4e-refile-folder . ,refile)
              (mu4e-compose-signature . (concat ,sig))
              (mu4e-compose-format-flowed . t)
              (mu4e-sent-messages-behavior . ,sent-action)
              (smtpmail-smtp-user . ,smtp-mail)
              (smtpmail-starttls-credentials . ((,smtp ,smtp-port nil nil)))
              (smtpmail-auth-credentials . '((,smtp ,smtp-port ,smtp-mail nil)))
              (smtpmail-default-smtp-server . ,smtp)
              (smtpmail-smtp-server . ,smtp)
              (smtpmail-stream-type . ,smtp-type)
              (smtpmail-smtp-service . ,smtp-port)
              (smtpmail-debug-info . t)
              (smtpmail-debug-verbose . t)
              (org-msg-signature . ,sig)
              (mu4e-maildir-shortcuts .
                                      ((,inbox   . ?i)
                                       (,sent    . ?s)
                                       (,trash   . ?t)
                                       (,refile  . ?a)
                                       (,draft   . ?d)
                                       (,spam    . ?g)))))))

(defvar mu4easy-today-query "date:today..now AND NOT maildir:/Trash/ AND NOT maildir:/Spam/")
(defvar mu4easy-trash-query "maildir:/Trash/")
(defvar mu4easy-inbox-query "maildir:/Inbox/")
(defvar mu4easy-unread-query "flag:new AND maildir:/Inbox/")

(defcustom mu4easy-bookmarks
  `(( :name  "Unread"
      :query ,mu4easy-unread-query
      :key   ?u)
    ( :name  "Inbox"
      :query ,mu4easy-inbox-query
      :key   ?i)
    ( :name "Today"
      :query ,mu4easy-today-query
      :key   ?t)
    ( :name "Flagged"
      :query "flag:flagged"
      :key   ?f)
    ( :name "Tags"
      :query "tag://"
      :key   ?T)
    ( :name "Trash"
      :query ,mu4easy-trash-query
      :key ?x
      :hide-unread t)
    ( :name "Attachments"
      :query "mime:application/pdf or mime:image/jpg or mime:image/png"
      :key   ?a
      :hide-unread t))
  "Preconfigured bookmarks for easy navigation.
See variable `mu4e-bookmarks'."
  :type '(repeat (plist)))

(defcustom mu4easy-headers
      '((:human-date   . 18)
        (:flags        . 6)
        (:maildir      . 16)
        (:from-or-to   . 22)
        (:mailing-list . 10)
        (:tags         . 10)
        (:subject      . 92))
      "Format of headers.
See variable `mu4e-headers-fields'"
      :type '(repeat (cons symbol integer)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mail Identities
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defcustom mu4easy-contexts
  '((mu4easy-context
     :c-name  "Google"
     :maildir "Gmail"
     :mail    "a@gmail.com"
     :smtp    "smtp.gmail.com"
     :sent-action delete)

    (mu4easy-context
     :c-name  "1-GMX"
     :maildir "GMX"
     :mail    "a@gmx.com"
     :smtp    "mail.gmx.com")

    (mu4easy-context
     :c-name    "2-GMX-alias"
     :maildir   "GMX"
     :mail      "a.alias@gmx.com"
     :smtp      "mail.gmx.com"
     :smtp-mail "a@gmx.com")

    (mu4easy-context
     :c-name  "Apple"
     :maildir "Apple"
     :mail    "a@icloud.com"
     :smtp    "smtp.mail.me.com")

    (mu4easy-context
     :c-name  "3-Apple-alias"
     :maildir "Apple"
     :mail    "a@me.com"
     :smtp    "smtp.mail.me.com"
     :smtp-mail "a@icloud.com")

    (mu4easy-context
     :c-name    "Proton"
     :maildir   "Proton"
     :mail      "a@protonmail.com"
     :smtp      "127.0.0.1"
     :smtp-type ssl
     :smtp-port 999)

    (mu4easy-context
     :c-name    "4-Proton-alias"
     :maildir   "Proton"
     :mail      "a@pm.com"
     :smtp      "127.0.0.1"
     :smtp-mail "a@protonmail.com"
     :smtp-type ssl
     :smtp-port 999))
  
  "Defining accounts and aliases.
After changing it, reload the minor mode.
See `mu4easy-context' for function signature."
  :type '(repeat sexp))

(defun mu4easy--maps ()
  "Define additional mapping for specific modes related to mu4e."
  (define-key mu4e-main-mode-map          (kbd "x")          #'bury-buffer)
  (define-key mu4e-main-mode-map          (kbd "I")          #'mu4e-update-index)
  (define-key mu4e-main-mode-map          (kbd "U")          #'mu4easy-update-mail-and-index)
  (define-key mu4e-view-mode-map          (kbd "<tab>")      #'shr-next-link)
  (define-key mu4e-view-mode-map          (kbd "<backtab>")  #'shr-previous-link)
  (define-key mu4e-search-minor-mode-map  (kbd "s")          #'helm-mu)
  (define-key mu4e-headers-mode-map       (kbd "M")          #'mu4e-headers-mark-all)
  (define-key mu4e-headers-mode-map       (kbd "N")          #'mu4e-headers-mark-all-unread-read))

;;;###autoload
(define-minor-mode mu4easy-mode
  "Toggle mu4easy configuration and keymaps."
  :lighter nil
  :global t
  (cond (mu4easy-mode
         (mu4easy--maps)
         (mu4e-icalendar-setup)
         (mu4e-column-faces-mode)
         (mu4e-alert-enable-notifications)
         (mu4e-alert-enable-mode-line-display)
         (org-msg-mode)
         (add-hook 'org-msg-edit-mode-hook     #'mu4easy--org-msg-hook)
         (add-hook 'mu4e-compose-mode-hook     #'mu4easy--compose-hook)
         (add-hook 'mu4e-context-changed-hook  #'mu4easy--update-buffer)
         (advice-add 'org-msg-composition-parameters :around #'mu4easy-customize-org-msg)
         (advice-add 'org-msg-get-alternatives :filter-return #'mu4easy-org-msg-select-format)
         (add-to-list 'mu4e-view-actions
                      '("Apply Email" . mu4e-action-git-apply-mbox) t)
         (setq mail-user-agent 'mu4e-user-agent)
         (setq mu4e-contexts (mapcar #'eval mu4easy-contexts))
         (setq mu4e-bookmarks mu4easy-bookmarks)
         (setq mu4e-headers-fields mu4easy-headers)
         (setq message-citation-line-function 'message-insert-formatted-citation-line)
         (setq message-kill-buffer-on-exit t)
         (setq message-send-mail-function 'smtpmail-send-it)
         (setq mu4e-attachment-dir (expand-file-name mu4easy-download-dir))
         (setq mu4e-change-filenames-when-moving t)
         (setq mu4e-completing-read-function 'completing-read)
         (setq mu4e-compose-context-policy 'ask)
         (setq mu4e-compose-format-flowed t)
         (setq mu4e-compose-signature-auto-include nil)
         (setq mu4e-confirm-quit nil)
         (setq mu4e-context-policy 'pick-first)
         (setq mu4e-get-mail-command (format "INSIDE_EMACS=%s mbsync -a" emacs-version))
         (setq mu4e-headers-auto-update t)
         (setq mu4e-headers-date-format "%d/%m/%Y %H:%M")
         (setq mu4e-headers-include-related nil)
         (setq mu4e-headers-skip-duplicates t)
         (setq mu4e-index-cleanup t)
         (setq mu4e-index-lazy-check nil)
         (setq mu4e-main-hide-personal-addresses t)
         (setq mu4e-main-buffer-name "*mu4e-main*")
         (setq mu4e-mu-binary (or (executable-find "mu") "/usr/local/bin/mu"))
         (setq mu4e-org-link-desc-func 'mu4easy-mail-link-description)
         (setq mu4e-sent-messages-behavior 'sent)
         (setq mu4e-update-interval 400)
         (setq mu4e-use-fancy-chars t)
         (setq message-citation-line-format "%N [%Y-%m-%d %a %H:%M] wrote:
")
         (setq mu4e-icalendar-trash-after-reply nil)
         (setq mu4e-icalendar-diary-file diary-file)
         (setq helm-mu-append-implicit-wildcard nil)
         (setq helm-mu-gnu-sed-program "gsed")
         (setq org-msg-options "html-postamble:nil H:5 num:nil ^:{} toc:nil author:nil email:nil \\n:t tex:imagemagick")
         (setq org-msg-startup "hidestars indent inlineimages")
         (setq org-msg-default-alternatives '((new           . (text html))
                                              (reply-to-html . (text html))
                                              (reply-to-text . (text))))
         (setq org-msg-signature mu4easy-signature)
         (setq org-msg-greeting-fmt mu4easy-greeting)
         (setq org-msg-posting-style 'top-posting)
         (setq org-msg-greeting-name-limit 2)
         (setq org-msg-convert-citation t))
        (t
         ;; remove all the hooks
         (remove-hook 'org-msg-edit-mode-hook     #'mu4easy--org-msg-hook)
         (remove-hook 'mu4e-compose-mode-hook     #'mu4easy--compose-hook)
         (remove-hook 'mu4e-context-changed-hook  #'mu4easy--update-buffer)
         (advice-remove 'org-msg-composition-parameters #'mu4easy-customize-org-msg)
         (advice-remove 'org-msg-get-alternatives #'mu4easy-org-msg-select-format)
         (mu4e-column-faces-mode -1)
         (mu4e-alert-disable-notifications)
         (mu4e-alert-disable-mode-line-display)
         (org-msg-mode -1)
         (custom-reevaluate-setting 'mail-user-agent)
         (custom-reevaluate-setting 'mu4e-contexts)
         (custom-reevaluate-setting 'mu4e-bookmarks)
         (custom-reevaluate-setting 'mu4e-headers-fields)
         (custom-reevaluate-setting 'message-citation-line-function)
         (custom-reevaluate-setting 'message-kill-buffer-on-exit)
         (custom-reevaluate-setting 'message-send-mail-function)
         (custom-reevaluate-setting 'mu4e-attachment-dir)
         (custom-reevaluate-setting 'mu4e-change-filenames-when-moving)
         (custom-reevaluate-setting 'mu4e-completing-read-function)
         (custom-reevaluate-setting 'mu4e-compose-context-policy)
         (custom-reevaluate-setting 'mu4e-compose-format-flowed)
         (custom-reevaluate-setting 'mu4e-compose-signature-auto-include)
         (custom-reevaluate-setting 'mu4e-confirm-quit)
         (custom-reevaluate-setting 'mu4e-context-policy)
         (custom-reevaluate-setting 'mu4e-get-mail-command)
         (custom-reevaluate-setting 'mu4e-headers-auto-update)
         (custom-reevaluate-setting 'mu4e-headers-date-format)
         (custom-reevaluate-setting 'mu4e-headers-include-related)
         (custom-reevaluate-setting 'mu4e-headers-skip-duplicates)
         (custom-reevaluate-setting 'mu4e-index-cleanup)
         (custom-reevaluate-setting 'mu4e-index-lazy-check)
         (custom-reevaluate-setting 'mu4e-main-hide-personal-addresses)
         (custom-reevaluate-setting 'mu4e-main-buffer-name)
         (custom-reevaluate-setting 'mu4e-mu-binary)
         (custom-reevaluate-setting 'mu4e-org-link-desc-func)
         (custom-reevaluate-setting 'mu4e-sent-messages-behavior)
         (custom-reevaluate-setting 'mu4e-update-interval)
         (custom-reevaluate-setting 'mu4e-use-fancy-chars)
         (custom-reevaluate-setting 'message-citation-line-format)
         (custom-reevaluate-setting 'mu4e-icalendar-trash-after-reply)
         (custom-reevaluate-setting 'mu4e-icalendar-diary-file)
         (custom-reevaluate-setting 'helm-mu-append-implicit-wildcard)
         (custom-reevaluate-setting 'helm-mu-gnu-sed-program)
         (custom-reevaluate-setting 'org-msg-options)
         (custom-reevaluate-setting 'org-msg-startup)
         (custom-reevaluate-setting 'org-msg-default-alternatives)
         (custom-reevaluate-setting 'org-msg-signature)
         (custom-reevaluate-setting 'org-msg-greeting-fmt)
         (custom-reevaluate-setting 'org-msg-posting-style)
         (custom-reevaluate-setting 'org-msg-greeting-name-limit)
         (custom-reevaluate-setting 'org-msg-convert-citation))))

(provide 'mu4easy)
;;; mu4easy.el ends here
