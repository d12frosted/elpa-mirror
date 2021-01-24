;;; mu4e-marker-icons.el --- Display icons for mu4e markers -*- lexical-binding: t; -*-
;; -*- coding: utf-8 -*-

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "26.1") (all-the-icons "4.0.0"))
;; Package-Version: 20210124.514
;; Package-Commit: e5c4f9b14eab69a0a28f108c6fee3390e19bd080
;; Version: 0.1.0
;; Keywords: mail
;; homepage: https://github.com/stardiviner/mu4e-marker-icons

;; Copyright (C) 2020-2021 Free Software Foundation, Inc.
;;
;; mu4e-marker-icons is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; mu4e-marker-icons is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Usage
;;
;; (mu4e-marker-icons-mode 1)

;;; Code:

(require 'mu4e-headers)
(require 'all-the-icons)

(defgroup mu4e-marker-icons nil
  "Display icons for mu4e markers."
  :group 'mu4e-marker-icons)

(defcustom mu4e-marker-icons-use-unicode nil
  "Whether use unicode icons instead of all-the-icons."
  :type 'boolean
  :safe #'booleanp)

(defvar mu4e-marker-icons-marker-alist
  '((mu4e-headers-seen-mark . mu4e-marker-icons-saved-headers-seen-mark)
    (mu4e-headers-new-mark . mu4e-marker-icons-saved-headers-new-mark)
    (mu4e-headers-unread-mark . mu4e-marker-icons-saved-headers-unread-mark)
    (mu4e-headers-signed-mark . mu4e-marker-icons-saved-headers-signed-mark)
    (mu4e-headers-encrypted-mark . mu4e-marker-icons-saved-headers-encrypted-mark)
    (mu4e-headers-draft-mark . mu4e-marker-icons-saved-headers-draft-mark)
    (mu4e-headers-attach-mark . mu4e-marker-icons-saved-headers-attach-mark)
    (mu4e-headers-passed-mark . mu4e-marker-icons-saved-headers-passed-mark)
    (mu4e-headers-flagged-mark . mu4e-marker-icons-saved-headers-flagged-mark)
    (mu4e-headers-replied-mark . mu4e-marker-icons-saved-headers-replied-mark)
    (mu4e-headers-trashed-mark . mu4e-marker-icons-saved-headers-trashed-mark))
  "An alist of markers used in mu4e.")

(defun mu4e-marker-icons--store (l)
  "Store mu4e header markers value from L."
  (mapcar (lambda (x) (set (cdr x) (symbol-value (car x)))) l))

(defun mu4e-marker-icons--restore (l)
  "Restore mu4e header markers value from L."
  (let ((lrev (mapcar (lambda (x) (cons (cdr x) (car x))) l)))
    (mu4e-marker-icons--store lrev)))


(defun mu4e-marker-icons-enable ()
  "Enable mu4e-marker-icons."
  (mu4e-marker-icons--store mu4e-marker-icons-marker-alist)
  (setq mu4e-use-fancy-chars t)
  (setq mu4e-headers-precise-alignment t)
  (if mu4e-marker-icons-use-unicode
      ;; The unicode icons is totally from http://xenodium.com/mu4e-icons, Thanks, Alvaro Ramirez.
      (setq mu4e-headers-unread-mark    '("u" .  "📩 ")
            mu4e-headers-draft-mark     '("D" .  "🚧 ")
            mu4e-headers-flagged-mark   '("F" .  "🚩 ")
            mu4e-headers-new-mark       '("N" .  "✨ ")
            mu4e-headers-passed-mark    '("P" .  "↪ ")
            mu4e-headers-replied-mark   '("R" .  "↩ ")
            mu4e-headers-seen-mark      '("S" .  " ")
            mu4e-headers-trashed-mark   '("T" .  "🗑️")
            mu4e-headers-attach-mark    '("a" .  "📎 ")
            mu4e-headers-encrypted-mark '("x" .  "🔑 ")
            mu4e-headers-signed-mark    '("s" .  "🖊 "))
    (setq
     mu4e-headers-seen-mark `("S" . ,(propertize
                                      (all-the-icons-material "mail_outline")
                                      'face `(:family ,(all-the-icons-material-family)
                                                      :foreground ,(face-background 'default))))
     mu4e-headers-new-mark `("N" . ,(propertize
                                     (all-the-icons-material "markunread")
                                     'face `(:family ,(all-the-icons-material-family)
                                                     :foreground ,(face-background 'default))))
     mu4e-headers-unread-mark `("u" . ,(propertize
                                        (all-the-icons-material "notifications_none")
                                        'face 'mu4e-unread-face))
     mu4e-headers-signed-mark `("s" . ,(propertize
                                        (all-the-icons-material "check")
                                        'face `(:family ,(all-the-icons-material-family)
                                                        :foreground "DarkCyan")))
     mu4e-headers-encrypted-mark `("x" . ,(propertize
                                           (all-the-icons-material "enhanced_encryption")
                                           'face `(:family ,(all-the-icons-material-family)
                                                           :foreground "CornflowerBlue")))
     mu4e-headers-draft-mark `("D" . ,(propertize
                                       (all-the-icons-material "drafts")
                                       'face 'mu4e-draft-face))
     mu4e-headers-attach-mark `("a" . ,(propertize
                                        (all-the-icons-material "attachment")
                                        'face 'mu4e-attach-number-face))
     mu4e-headers-passed-mark `("P" . ,(propertize ; ❯ (I'm participated in thread)
                                        (all-the-icons-material "center_focus_weak")
                                        'face `(:family ,(all-the-icons-material-family)
                                                        :foreground "yellow")))
     mu4e-headers-flagged-mark `("F" . ,(propertize
                                         (all-the-icons-material "flag")
                                         'face 'mu4e-flagged-face))
     mu4e-headers-replied-mark `("R" . ,(propertize
                                         (all-the-icons-material "reply_all")
                                         'face 'mu4e-replied-face))
     mu4e-headers-trashed-mark `("T" . ,(propertize
                                         (all-the-icons-material "delete_forever")
                                         'face 'mu4e-trashed-face)))))

(defun mu4e-marker-icons-disable ()
  "Disable mu4e-marker-icons."
  (mu4e-marker-icons--restore mu4e-marker-icons-marker-alist))

;;;###autoload
(define-minor-mode mu4e-marker-icons-mode
  "Display icons for mu4e markers."
  :require 'mu4e-marker-icons-mode
  :init-value nil
  :global t
  (if mu4e-marker-icons-mode
      (mu4e-marker-icons-enable)
    (mu4e-marker-icons-disable)))



(provide 'mu4e-marker-icons)

;;; mu4e-marker-icons.el ends here
