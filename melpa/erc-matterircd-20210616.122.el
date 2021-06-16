;;; erc-matterircd.el --- Integrate matterircd with ERC         -*- lexical-binding: t; -*-

;; Copyright (c) 2020 Alex Murray

;; Author: Alex Murray <murray.alex@gmail.com>
;; Maintainer: Alex Murray <murray.alex@gmail.com>
;; URL: https://github.com/alexmurray/erc-matterircd
;; Package-Version: 20210616.122
;; Package-Commit: fa2c5a1d0b4bd0b353e2c7470404d40575d77c83
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Helpers to format *italic* and [link](url) plus removal of redundant GIF
;; bits for easy display via erc-image (although this is not required, it
;; is recommended), also will automatically connect to mattermost when
;; connecting to a matterircd server, and finally ensures @ is prepended
;; when completing nicknames in when connected to matterircd.

;; (require 'erc-matterircd)
;; (setq erc-matterircd-server "mattermost.server")
;; (setq erc-matterircd-team "mytest")
;; (setq erc-matterircd-password "password")
;; (add-to-list 'erc-modules 'matterircd)
;; (erc-update-modules)
;;
;; Then connect to matterircd as a normal erc server:
;; (erc :server "localhost" :port "6667" :nick "mynick")

;;; TODO:

;; - Support post/thread replies / reactions
;;   - remove thread id prefix/suffix and store as text property that
;;     displays on hover
;;   - provide autocomplete for known thread ids
;;   - don't show reactions but instead append it to the original message
;;     with properties so can show who on hover

;;; Code:
(require 'erc)
(require 'erc-button)
(require 'erc-networks)
(require 'erc-pcomplete)
(require 'text-property-search)

(declare-function erc-image-show-url "erc-image")

(defgroup erc-matterircd nil
  "Integrate ERC with matterircd"
  :group 'erc)

(defcustom erc-matterircd-server nil
  "The mattermost server to connect to via matterircd."
  :group 'erc-matterircd
  :type 'string)

(defcustom erc-matterircd-team nil
  "The mattermost team to connect to via matterircd."
  :group 'erc-matterircd
  :type 'string)

(defcustom erc-matterircd-updatelastviewed-on-buffer-switch nil
  "Whether to automatically send updatelastviewed when switching buffers."
  :group 'erc-matterircd
  :type 'boolean)

(defcustom erc-matterircd-password nil
  "The password to use for mattermost to connect via matterircd."
  :group 'erc-matterircd
  :type 'string)

(defun erc-matterircd-connect-to-mattermost (server nick)
  "Try login to mattermost on SERVER with NICK."
  ;; server should contain matterircd somewhere in it
  (when (string-match-p "matterircd" server)
    (erc-message "PRIVMSG"
                 (format "mattermost login %s %s %s %s"
                         erc-matterircd-server erc-matterircd-team
                         nick erc-matterircd-password))))

(defun erc-matterircd-format-links ()
  "Format links sent via matterircd.
Links use markdown syntax of [name](url) so tag name to
open url via `browse-url-buttton-open-url'."
  (when (eq 'matterircd (erc-network))
    (goto-char (point-min))
    (while (re-search-forward "\\[\\([^\\[]*\\)\\](\\(.*?\\))" nil t)
      (let ((name (match-string-no-properties 1))
            (url (match-string-no-properties 2))
            (start (match-beginning 0)))
        (replace-match name)
        ;; erc-button removes old keymaps etc when it runs later - so for
        ;; now just set text-properties so we can actually buttonize it in
        ;; a hook which will run after erc-button / erc-fill etc
        (set-text-properties start (point)
                             `(erc-matterircd-link-url ,url))))))

(defun erc-matterircd-buttonize-links ()
  "Format links sent via matterircd.
Links use markdown syntax of [name](url) so buttonize name to
open url via `browse-url-buttton-open-url'."
  (when (eq 'matterircd (erc-network))
    (goto-char (point-min))
    (let ((match))
      (while (setq match (text-property-search-forward 'erc-matterircd-link-url))
        (erc-button-add-button (prop-match-beginning match)
                               (prop-match-end match)
                               #'browse-url-button-open-url
                               nil
                               (list (prop-match-value match)))
        (remove-text-properties (prop-match-beginning match)
                                (prop-match-end match)
                                '(erc-matterircd-link-url nil))))))

(defun erc-matterircd-cleanup-gifs ()
  "Cleanup gifs sent via matterircd.
For each /gif we see two lines in the message:

 */gif [name](URL)*
![GIF for 'name'](URL)

In mattermost this is shown as:
/gif name
[image]

`erc-matterircd-format-links' will handle the first line, so for
the second, just leave the URL and let erc-image do the hard
work."
  (when (eq 'matterircd (erc-network))
    (goto-char (point-min))
    (while (re-search-forward "!\\[GIF for '.*'\\](\\(.*?\\))" nil t)
      (let ((url (match-string 1)))
        (replace-match url)))))

(defvar erc-matterircd-italic-face
  (if (facep 'erc-italic-face)
      'erc-italic-face
    'italic)
  "Convenience definition of the face to use for italic text.

Will use `erc-italic-face' if it is available, otherwise `italic'.")

(defun erc-matterircd-format-italics ()
  "Format *italics* or _italics_ correctly.
Italics are sent *message* or _message_

In mattermost this is shown as italic, so rewrite it to use
italic face instead."
  (when (eq 'matterircd (erc-network))
    (goto-char (point-min))
    ;; underscores need to be either at the start of end or space delimited
    ;; whereas asterisks can be anywhere
    (while (or (re-search-forward "\\(\\*\\([^\\*]+?\\)\\*\\)" nil t)
               (re-search-forward "\\_<\\(_\\([^_]+?\\)_\\)\\_>" nil t))
      (let ((message (match-string 2)))
        ;; erc-italic-face is only in very recent emacs 28 so use italic
        ;; for now
        (replace-match (propertize message 'face
                                   erc-matterircd-italic-face)
                       t t nil 1)))))

(defun erc-matterircd-format-bolds ()
  "Format **bold** / or __bolds__ correctly.
Bolds are sent **message** or __message__

In mattermost this is shown as bold, so rewrite it to use
bold face instead."
  (when (eq 'matterircd (erc-network))
    (goto-char (point-min))
    (while (or (re-search-forward "\\(\\*\\*\\([^\\*]+?\\)\\*\\*\\)" nil t)
               (re-search-forward "\\_<\\(__\\([^_]+?\\)__\\)\\_>" nil t))
      (let ((message (match-string 2)))
        (replace-match (propertize message 'face 'erc-bold-face)
                       t t nil 1)))))

(defface erc-matterircd-strikethrough-face
  '((t (:strike-through t)))
  "Face to show ~~strikethough~~ text.")

(defun erc-matterircd-format-strikethroughs ()
  "Format ~~strikethrough~~ correctly.
Strikethroughs are sent ~~message~~

In mattermost this is shown as strikethrough, so rewrite it to use
strikethrough face attribute instead."
  (when (eq 'matterircd (erc-network))
    (goto-char (point-min))
    (while (re-search-forward "~~\\(.*?\\)~~" nil t)
      (let ((message (match-string 1)))
        (replace-match (propertize message 'face 'erc-matterircd-strikethrough-face))))))

(defun erc-matterircd-pcomplete-erc-nicks (orig-fun &rest args)
  "Advice for `pcomplete-erc-nicks' to prepend an @ via ORIG-FUN and ARGS."
  (let ((nicks (apply orig-fun args)))
    (if (eq 'matterircd (erc-network))
        (mapcar (lambda (nick) (concat "@" nick)) nicks)
      nicks)))

(defun erc-cmd-SCROLLBACK (&optional num-lines)
  "Request scrollback for the current channel of NUM-LINES.

Defaults to 10 lines if none specified."
  (if (eq 'matterircd (erc-network))
      (let ((target (erc-default-target))
            (lines (or (and (integerp num-lines) num-lines)
                       10)))
        (erc-log (format "cmd: DEFAULT: SCROLLBACK %s %d" target lines))
        (erc-server-send (format "PRIVMSG mattermost :scrollback %s %d" target lines)))
    (erc-display-message nil 'error (current-buffer) 'not-matterircd)))

(defun erc-cmd-UPDATELASTVIEWED ()
  "Send updatelastviewed for the current channel."
  (if (eq 'matterircd (erc-network))
      (let ((target (erc-default-target)))
        (erc-log (format "cmd: DEFAULT: updatelastviewed %s" target))
        (erc-server-send (format "PRIVMSG mattermost :updatelastviewed %s" target)))
    (erc-display-message nil 'error (current-buffer) 'not-matterircd)))

(defvar erc-matterircd--last-buffer nil
  "The last matterircd buffer which was viewed.")

(defun erc-matterircd-maybe-updatelastviewed ()
  "Automatically send updatelastviewed for the current channel on FRAME if desired."
  (when (and (eq 'matterircd (erc-network))
             (not (eq (current-buffer) erc-matterircd--last-buffer)))
    (setq erc-matterircd--last-buffer (current-buffer))
    (when erc-matterircd-updatelastviewed-on-buffer-switch
      (erc-cmd-UPDATELASTVIEWED))))

(define-erc-module matterircd nil
  "Integrate ERC with matterircd"
  ((add-to-list 'erc-networks-alist '(matterircd "matterircd.*"))
   (advice-add #'pcomplete-erc-nicks :around #'erc-matterircd-pcomplete-erc-nicks)
   (add-hook 'erc-after-connect #'erc-matterircd-connect-to-mattermost)
   (add-hook 'post-command-hook #'erc-matterircd-maybe-updatelastviewed)
   ;; remove gifs junk, format bold, then italics, then links
   (dolist (hook '(erc-insert-modify-hook erc-send-modify-hook))
     (add-hook hook #'erc-matterircd-cleanup-gifs -99)
     (add-hook hook #'erc-matterircd-format-bolds -98)
     (add-hook hook #'erc-matterircd-format-italics -97)
     (add-hook hook #'erc-matterircd-format-strikethroughs -96)
     (add-hook hook #'erc-matterircd-format-links -95)
     ;; erc-button unbuttonizes text so we need to do this after everything
     ;; else
     (add-hook hook #'erc-matterircd-buttonize-links '99)
     ;; we want to make sure we come before erc-image-show-url in
     ;; erc-insert-modify-hook
     (when (and (fboundp 'erc-image-show-url)
                (member #'erc-image-show-url (eval hook)))
       ;; remove and re-add to get appended
       (remove-hook hook #'erc-image-show-url)
       (add-hook hook #'erc-image-show-url t))))
  ((remove-hook 'erc-after-connect #'erc-matterircd-connect-to-mattermost)
   (dolist (hook '(erc-insert-modify-hook erc-send-modify-hook))
     (remove-hook hook #'erc-matterircd-buttonize-links)
     (remove-hook hook #'erc-matterircd-format-links)
     (remove-hook hook #'erc-matterircd-format-strikethroughs)
     (remove-hook hook #'erc-matterircd-format-italics)
     (remove-hook hook #'erc-matterircd-format-bolds)
     (remove-hook hook #'erc-matterircd-cleanup-gifs))
   (advice-remove 'pcomplete-erc-nicks #'erc-matterircd-pcomplete-erc-nicks))
  t)

(provide 'erc-matterircd)
;;; erc-matterircd.el ends here
