;;; ercn.el --- Flexible ERC notifications

;; Copyright (C) 2012  David Leatherman

;; Author: David Leatherman <leathekd@gmail.com>
;; URL: http://www.github.com/leathekd/ercn
;; Package-Version: 20150523.1503
;; Package-Commit: 79a4df5609046ae2e2e3375998287be6dda80615
;; Version: 1.1.1

;; This file is not part of GNU Emacs.

;;; Commentary:

;; ercn allows for flexible notification rules in ERC. You can
;; configure it to notify for certain classes of users, query buffers,
;; certain buffers, etc. It utilizes functions (and a small bit of
;; copy pasta) from erc-match to get the job done. See the
;; documentation for `ercn-notify-rules' and `ercn-suppress-rules' to
;; set it up.
;;
;; When a notification is needed, ercn calls `ercn-notify-hook' so
;; that any notification mechanism available for your system can be
;; utilized with a little elisp.
;;
;; Installation:
;; =============
;;
;; Via Marmalade (recommended)
;; ---------------------------
;;
;; If you are on Emacs 23, go to marmalade-repo.org and follow the installation
;; instructions there.
;;
;; If you are on Emacs 24, add Marmalade as a package archive source in
;; ~/.emacs.d/init.el:
;;
;;   (require 'package)
;;   (add-to-list 'package-archives
;;       '("marmalade" . "http://marmalade-repo.org/packages/") t)
;;   (package-initialize)
;;
;; Then you can install it:
;;
;;   M-x package-refresh-contents
;;   M-x package-install RET ercn RET
;;
;; Manually (via git)
;; ------------------
;;
;; Download the source or clone the repo and add the following to
;; ~/.emacs.d/init.el:
;;
;;   (add-to-list 'load-path "path/to/ercn")
;;   (require 'ercn)
;;
;; Configuration
;; =============
;;
;; Two variables control whether or not ercn calls `ercn-notify-hook':
;;
;; * `ercn-notify-rules': Rules to determine if the hook should be called. It
;;   defaults to calling the hook whenever a pal speaks, a keyword is mentioned,
;;   your current-nick is mentioned, or a message is sent inside a query buffer.
;;
;; * `ercn-suppress-rules': Rules to determine if the notification should be
;;   suppressed. Takes precedent over `ercn-notify-rules'. The default will
;;   suppress messages from fools, dangerous-hosts, and system messages.
;;
;; Both vars are alists that contain the category of message as the keys and as
;; the value either the symbol ‘all, a list of buffer names in which to
;; notify or suppress, or a function predicate.
;;
;; The supported categories are:
;;
;; * message - category added to all messages
;; * current-nick - messages that mention you
;; * keyword - words in the `erc-keywords' list
;; * pal - nicks in the `erc-pals' list
;; * query-buffer - private messages
;; * fool - nicks in the `erc-fools' list
;; * dangerous-host - hosts in the `erc-dangerous-hosts' list
;; * system - messages sent from the system (join, part, etc.)
;;
;; An example configuration
;; ------------------------
;;
;;   (setq ercn-notify-rules
;;       '((current-nick . all)
;;            (keyword . all)
;;            (pal . ("#emacs"))
;;            (query-buffer . all)))
;;
;;   (defun do-notify (nickname message)
;;       ;; notification code goes here
;;   )
;;
;;   (add-hook 'ercn-notify-hook 'do-notify)
;;
;; In this example, `ercn-notify-hook' will be called whenever anyone
;; mentions my nick or a keyword or when sent from a query buffer, or if a pal
;; speaks in #emacs.
;;
;; To call the hook on all messages
;; --------------------------------
;;
;;   (setq ercn-notify-rules '((message . all))
;;       ercn-suppress-rules nil)
;;
;;   (defun do-notify (nickname message)
;;       ;; notification code goes here
;;   )
;;
;;   (add-hook 'ercn-notify-hook 'do-notify)
;;
;; I wouldn’t recommend it, but it’s your setup.


;; History

;; 1.0.0 - Initial release.  It probably even works.

;; 1.0.1 - save-excursion, to avoid messing with the current line

;; 1.0.2 - fix autoloads

;; 1.1 - Added customize options; renamed `erc-notify' `erc-notify-hook'

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'erc)
(require 'erc-match)
(require 'dash)

(defconst ercn-categories
  '(message
    current-nick
    keyword
    pal
    query-buffer
    fool
    dangerous-host
    system)
  "Notification categories.")

(defgroup ercn nil "Flexible notifications for ERC." :group 'erc)

(defcustom ercn-notify-rules
  '((current-nick . all)
    (keyword . all)
    (pal . all)
    (query-buffer . all))
  "An alist containing the rules for when to notify. The format is the
category followed by either the special symbol 'all, a list of
buffer names in which to notify, or a function predicate. The
predicate will be called with two strings, the nickname of the
sender and the message. If it returns truthy, `ercn-notify-hook'
will be called (unless it is suppressed)."
  :tag "ercn notify rules"
  :group 'ercn
  :type
  '(alist :key-type symbol
     :value-type (choice
                   (const :tag "All" all)
                   (repeat :tag "List of buffer names"
                     (string :tag "Buffer name"))
                   (function :tag "Predicate")))
  :options ercn-categories)

(defcustom ercn-suppress-rules
  '((dangerous-host . all)
    (fool . all)
    (system . all))
  "An alist containing the rules for when to suppress notification.
Suppression takes precedent over notification, so if any suppression
rule matches, the notification hook will not be called.

The format is the category followed by either the special symbol
'all (to suppress everywhere), a list of buffer names in which to
suppress, or a function predicate. The predicate will be called with
two strings, the nickname of the sender and the message. If it
returns truthy, the notification will be suppressed."
  :tag "ercn suppress rules"
  :group 'ercn
  :type
  '(alist :key-type symbol
     :value-type (choice
                   (const :tag "All" all)
                   (repeat :tag "List of buffer names"
                     (string :tag "Buffer name"))
                   (function :tag "Predicate")))
  :options ercn-categories)

(define-obsolete-variable-alias 'ercn-notify 'ercn-notify-hook "1.1")
(defcustom ercn-notify-hook nil
  "Functions run when an ERC message rates notification.

Each hook function must accept two arguments: NICKNAME and MESSAGE."
  :tag "ercn notify hook"
  :group 'ercn
  :type '(repeat function))

(defun ercn-rule-passes-p (rules nick message category)
  "Checks the rules and returns truthy if `ercn-notify-hook' should be called."
  (let ((notify-rule (cdr (assoc category rules))))
    (when notify-rule
      (cond
       ((eq 'all notify-rule) t)
       ((functionp notify-rule) (funcall notify-rule nick message))
       ((listp notify-rule) (member (buffer-name) notify-rule))))))

;;;###autoload
(defun ercn-match ()
  "Extracts information from the buffer and fires `ercn-notify-hook' if needed."
  (save-excursion
    (goto-char (point-min))
    (let* ((vector (erc-get-parsed-vector (point-min)))
           (nickuserhost (erc-get-parsed-vector-nick vector))
           (nickname (and nickuserhost
                          (nth 0 (erc-parse-user nickuserhost))))
           (nick-beg (and nickname
                          (re-search-forward (regexp-quote nickname)
                                             (point-max) t)
                          (match-beginning 0)))
           (nick-end (if nick-beg
                         (progn (goto-char (match-end 0))
                                (search-forward " " nil t 1)
                                (point))
                       (point-min)))
           (message (replace-regexp-in-string
                     "\n" " " (buffer-substring nick-end (point-max))))
           (categories
            (delq nil
                    (list 'message
                          (when (null nickname) 'system)
                          (when (erc-query-buffer-p) 'query-buffer)
                          (when (or (erc-match-fool-p nickuserhost message)
                                    (erc-match-directed-at-fool-p message)) 'fool)
                          (when (erc-match-dangerous-host-p nickuserhost message)
                            'dangerous-host)
                          (when (erc-match-current-nick-p nickuserhost message)
                            'current-nick)
                          (when (erc-match-keyword-p nickuserhost message)
                            'keyword)
                          (when (erc-match-pal-p nickuserhost message) 'pal))))
           (notify-passes
            (-keep
              (-partial #'ercn-rule-passes-p
                ercn-notify-rules nickname message)
              categories))
           (suppress-passes
            (-keep
              (-partial #'ercn-rule-passes-p
                ercn-suppress-rules nickname message)
              categories)))
      (when (and notify-passes
                 (null suppress-passes))
        (run-hook-with-args 'ercn-notify-hook nickname message)))))

;;;###autoload
(defun ercn-fix-hook-order (&rest _)
  "Notify before timestamps are added"
  (when (memq 'erc-add-timestamp erc-insert-modify-hook)
    (remove-hook 'erc-insert-modify-hook 'erc-add-timestamp)
    (remove-hook 'erc-insert-modify-hook 'ercn-match)
    (add-hook 'erc-insert-modify-hook 'ercn-match 'append)
    (add-hook 'erc-insert-modify-hook 'erc-add-timestamp t)))

(defvar ercn--pre-existing-erc-match-message-flag nil
  "Indicate whether `erc-insert-modify-hook' contained `erc-match-message' on entry.")

(define-erc-module ercn nil
  "Flexible erc notifications"
  ((add-hook 'erc-insert-modify-hook 'ercn-match 'append)
   ;; to avoid duplicate messages, remove the erc-match-message hook
   (setq ercn--pre-existing-erc-match-message-flag
     (memq 'erc-match-message erc-insert-modify-hook))
   (remove-hook 'erc-insert-modify-hook 'erc-match-message)
   (add-hook 'erc-connect-pre-hook 'ercn-fix-hook-order t))
  ((remove-hook 'erc-insert-modify-hook 'ercn-match)
   (remove-hook 'erc-connect-pre-hook 'ercn-fix-hook-order)
   (when ercn--pre-existing-erc-match-message-flag
     (add-hook 'erc-insert-modify-hook #'erc-match-message))))

(defun ercn--add-erc-module ()
  "Add ercn to the end of `erc-modules' and update."
  (add-to-list 'erc-modules 'ercn 'appending)
  (erc-update-modules))

;; For first time use
;;;###autoload
(when (boundp 'erc-modules)
  (ercn--add-erc-module))

(provide 'ercn)

;;;###autoload
(eval-after-load 'erc
  '(progn
     (require 'ercn)
     (ercn--add-erc-module)))

;;; ercn.el ends here
