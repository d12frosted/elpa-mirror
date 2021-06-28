;;; erc-matterircd.el --- Integrate matterircd with ERC         -*- lexical-binding: t; -*-

;; Copyright (c) 2020 Alex Murray

;; Author: Alex Murray <murray.alex@gmail.com>
;; Maintainer: Alex Murray <murray.alex@gmail.com>
;; URL: https://github.com/alexmurray/erc-matterircd
;; Package-Version: 20210628.827
;; Package-Commit: abcdb08dba3711a2f9f72adee3c91b10a0d46f03
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

;; - Improve support post/thread replies / reactions
;;   - don't show reactions but instead append it to the original message
;;     with properties so can show who on hover

;;; Code:
(require 'erc)
(require 'erc-button)
(require 'erc-networks)
(require 'erc-pcomplete)
(require 'rx)
(require 'text-property-search)

(declare-function erc-image-show-url "erc-image")
(declare-function company-doc-buffer "company")

(defgroup erc-matterircd nil
  "Integrate ERC with matterircd."
  :group 'erc)

(defcustom erc-matterircd-server nil
  "The mattermost server to connect to via matterircd."
  :group 'erc-matterircd
  :type 'string)

(defcustom erc-matterircd-team nil
  "The mattermost team to connect to via matterircd."
  :group 'erc-matterircd
  :type 'string)

(defcustom erc-matterircd-password nil
  "The password to use for mattermost to connect via matterircd."
  :group 'erc-matterircd
  :type 'string)

(defcustom erc-matterircd-updatelastviewed-on-buffer-switch nil
  "Whether to automatically send updatelastviewed when switching buffers."
  :group 'erc-matterircd
  :type 'boolean)

(defcustom erc-matterircd-insert-fake-context-id-on-send t
  "Whether to display a local faked context ID when sending messages.

NOTE: this does not actually result in anything additional
getting sent to the server, just in what is displayed to the user
locally."
  :group 'erc-matterircd
  :type 'boolean)

(defcustom erc-matterircd-replace-context-id nil
  "Whether to replace context IDs in messages with a replacement string.

If this is non-nil then replace context IDs in messages with the
value of this variable."
  :group 'erc-matterircd
  :type 'string)

(defcustom erc-matterircd-suppress-mattermost-responses t
  "Whether to suppress responses from the mattermost user.

When sending updatelastviewed and other commands to the
mattermost user, we receive responses as privmsg - suppress these
by default as they are usually not important."
  :group 'erc-matterircd
  :type 'boolean)

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
      (let* ((name (match-string-no-properties 1))
             (url (match-string-no-properties 2))
             (start (match-beginning 0)))
        (replace-match name)
        ;; erc-button removes old keymaps etc when it runs later - so for
        ;; now just set text-properties so we can actually buttonize it in
        ;; a hook which will run after erc-button / erc-fill etc
        (set-text-properties start (point)
                             (list 'erc-matterircd-link-url url
                                   'help-echo url))))))

(defun erc-matterircd-reply-to-context-id (context-id)
  "Go to erc prompt and start a reply to the post with CONTEXT-ID."
  ;; go to prompt and insert text so we can reply
  (when (and erc-input-marker (< (point) erc-input-marker))
    (deactivate-mark)
    (push-mark)
    (goto-char (point-max))
    (ignore-errors (kill-whole-line))
    (insert (concat "@@" context-id " "))))

(defun erc-matterircd-buttonize-from-text-properties ()
  "Buttonize text based on pre-existing text properties.

Buttonize links to open url via `browse-url-buttton-open-url' and
thread contexts so can reply."
  (when (eq 'matterircd (erc-network))
    (dolist (props `((:property erc-matterircd-link-url
                                :function ,#'browse-url-button-open-url)
                     (:property erc-matterircd-context-id
                                :function ,#'erc-matterircd-reply-to-context-id)))
      (goto-char (point-min))
      (let ((prop (plist-get props :property))
            (func (plist-get props :function))
            (match))
        (while (setq match (text-property-search-forward prop))
          (erc-button-add-button (prop-match-beginning match)
                                 (prop-match-end match)
                                 func
                                 nil
                                 (list (prop-match-value match))))))))

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

(defun erc-matterircd-format-reactions ()
  "Format reactions sent via matterircd."
  (when (eq 'matterircd (erc-network))
    (goto-char (point-min))
    (while (re-search-forward "added reaction: \\([^[:space:]]*\\)" nil t)
      (let ((name (match-string-no-properties 1)))
        (replace-match (concat ":" name ":") nil nil nil 1)))))

(defvar erc-matterircd-context-regexp
  "\\[\\([0-9a-f]\\{3\\}\\)\\(->\\([0-9a-f]\\{3\\}\\)\\)?\\]")

(defun erc-matterircd-format-contexts ()
  "Format [xxx] contexts as text properties.

matterircd can be configured to prefix/suffix posts with a
context id that can be referred to in subsequent posts to reply
to, edit or delete a post."
  (when (eq 'matterircd (erc-network))
    (goto-char (point-min))
    ;; this is either a prefix or suffix to the message
    (when (or (re-search-forward (concat "^\\s-*\\(" erc-matterircd-context-regexp "\\) ") nil t)
              (re-search-forward (concat " \\(" erc-matterircd-context-regexp "\\)\\s-*$") nil t))
      ;; delete and propertize message with the context id
      (let ((full-id (match-string-no-properties 1))
            (context-id (match-string-no-properties 2))
            (start (match-beginning 1))
            (end (match-end 1))
            (source (buffer-substring-no-properties
                     (point-min) (point-max))))
        (when erc-matterircd-replace-context-id
          (replace-match erc-matterircd-replace-context-id
                         nil nil nil 1)
          (setq end (point)))
        (add-text-properties start end
                             (list 'erc-matterircd-context-id context-id
                                   'erc-matterircd-source source
                                   'help-echo full-id))))))

(defvar erc-matterircd--pending-responses nil)

(defun erc-matterircd-PRIVMSG (_proc parsed)
  "Intercept and handle PARSED response from the mattermost user."
  (let ((sender (car (erc-parse-user (erc-response.sender parsed))))
        (contents (erc-response.contents parsed))
        (handled nil))
    (when (string= sender "mattermost")
      (pcase contents
        ((rx bos "set viewed for " (let channel (group (one-or-more any))) eos)
         ;; channel name doesn't contain # prefix but it does in our
         ;; list of pending responses
         (remhash (concat "#" channel)
                  erc-matterircd--pending-responses)
         ;; respects users wish to suppress responses
         (setq handled erc-matterircd-suppress-mattermost-responses))
        ((rx bos "updatelastviewed" (zero-or-more any) eos)
         ;; is an error regarding a previous call to updatelastviewed
         ;; respects users wish to suppress responses
         (setq handled erc-matterircd-suppress-mattermost-responses)))
      ;; for any pending responses, re-send
      (maphash #'(lambda (channel _time)
                   (erc-cmd-UPDATELASTVIEWED channel))
               erc-matterircd--pending-responses))
    handled))

(defun erc-matterircd-pcomplete-erc-nicks (orig-fun &rest args)
  "Advice for `pcomplete-erc-nicks' to prepend an @ via ORIG-FUN and ARGS."
  (let ((nicks (apply orig-fun args)))
    (if (eq 'matterircd (erc-network))
        (mapcar (lambda (nick) (concat "@" nick)) nicks)
      nicks)))

(defun erc-matterircd--context-ids (&optional buffer)
  "Get the list of context IDs and locations for BUFFER in MRU order.

Defaults to the current buffer if none specified."
    (with-current-buffer (or buffer (current-buffer))
      (save-excursion
        (goto-char (point-min))
        (let ((context-ids nil)
              (match nil))
          (while (setq match (text-property-search-forward 'erc-matterircd-context-id))
            (let ((id (prop-match-value match)))
              (unless (alist-get id context-ids nil nil #'equal)
                (push (cons (prop-match-value match)
                            (cons (current-buffer)
                                  ;; after searching point is just past the
                                  ;; location
                                  (1- (point))))
                      context-ids))))
          context-ids))))

(defun erc-matterircd--get-docsig-for-context-id (id context-ids)
  "Get the docsig for ID from the list of CONTEXT-IDS."
  (let ((location (alist-get id context-ids nil nil #'equal)))
    (if location
        (get-text-property (cdr location)
                           'erc-matterircd-source
                           (car location))
      "")))

(defun erc-matterircd-complete-context-ids (&optional _candidate)
  "Complete context-ids for replies."
  (when (and (eq 'matterircd (erc-network))
             (not (null (string-match-p "^@@[0-9]\\{0,3\\}$" (erc-user-input)))))
        ;; find the list of context-ids in the current buffer
        (let* ((context-ids (erc-matterircd--context-ids))
               (candidates
                (mapcar (lambda (id) (cons (concat "@@" (car id)) (cdr id))) context-ids))
              (bounds (bounds-of-thing-at-point 'word)))
          (list (car bounds) (cdr bounds)
                candidates
                :exclusive 'no
                :annotation-function (lambda (id)
                                       (let ((docsig
                                              (erc-matterircd--get-docsig-for-context-id
                                               id candidates)))
                                         (substring docsig
                                          0 (min (length docsig) 40))))
                :company-docsig (lambda (id)
                                  (erc-matterircd--get-docsig-for-context-id
                                   id candidates))
                :company-doc-buffer (lambda (id)
                                      (company-doc-buffer
                                       (erc-matterircd--get-docsig-for-context-id
                                        id candidates)))
                :company-location (lambda (id)
                                    (cdr (alist-get id context-ids nil nil #'equal)))))))

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

(defun erc-cmd-UPDATELASTVIEWED (&optional channel)
  "Send updatelastviewed for CHANNEL (or current channel if not specified)."
  (if (eq 'matterircd (erc-network))
      (let* ((target (or channel (erc-default-target)))
             (now (time-convert nil 'integer))
             (last-time (gethash target erc-matterircd--pending-responses)))
        ;; the mattermost user is fake plus we can't seem to
        ;; updatelastviewed for the channel with ourself so skip both of
        ;; these
        (when (and (not (or (string= target "mattermost")
                            (string= target (erc-current-nick))))
                   (> (- now (or last-time 0)) 5))
          ;; keep original time
          (unless last-time
            (puthash target now erc-matterircd--pending-responses))
          (erc-log (format "cmd: DEFAULT: updatelastviewed %s" target))
          (erc-server-send (format "PRIVMSG mattermost :updatelastviewed %s" target))))
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

(defun erc-matterircd--get-next-context-id (context-ids)
  "Get the next context ID which would be allocated from CONTEXT-IDS."
  (if (> (length context-ids) 0)
      (let* ((next (1+ (string-to-number (car (car context-ids))))))
        (format "%03d" (mod next 1000)))
    "001"))

(defun erc-matterircd-insert-fake-context-id ()
  "Insert a fake local context ID for sent messages."
  (when (and (eq 'matterircd (erc-network))
             erc-matterircd-insert-fake-context-id-on-send)
    (let ((id (erc-matterircd--get-next-context-id
               ;; need to widen as we are narrowed
               (save-restriction
                 (widen)
                 (erc-matterircd--context-ids)))))
     (save-excursion
       (goto-char (point-max))
       ;; find first non-blank content
       (re-search-backward "[^\\s-]")
       (insert (concat " [" id "]"))))))

(defvar erc-matterircd--run-first-hook-functions
  `(,#'erc-matterircd-cleanup-gifs
    ,#'erc-matterircd-format-bolds
    ,#'erc-matterircd-format-italics
    ,#'erc-matterircd-format-strikethroughs
    ,#'erc-matterircd-format-links
    ,#'erc-matterircd-format-reactions
    ,#'erc-matterircd-format-contexts))

;; erc-button unbuttonizes text so we need to re-buttonize after everything
;; else
(defvar erc-matterircd--run-last-hook-functions
  `(,#'erc-matterircd-buttonize-from-text-properties))

(define-erc-module matterircd nil
  "Integrate ERC with matterircd"
  ((add-to-list 'erc-networks-alist '(matterircd "matterircd.*"))
   (advice-add #'pcomplete-erc-nicks :around #'erc-matterircd-pcomplete-erc-nicks)
   (add-to-list 'completion-at-point-functions #'erc-matterircd-complete-context-ids)
   (add-hook 'erc-after-connect #'erc-matterircd-connect-to-mattermost)
   (add-hook 'post-command-hook #'erc-matterircd-maybe-updatelastviewed)
   (setq erc-matterircd--pending-responses (make-hash-table :test 'equal))
   ;; ensure we can handle but also suppress responses from mattermost
   (add-hook 'erc-server-PRIVMSG-functions #'erc-matterircd-PRIVMSG -99)
   (dolist (hook '(erc-insert-modify-hook erc-send-modify-hook))
     (let ((depth -99))
       (dolist (func erc-matterircd--run-first-hook-functions)
         (add-hook hook func depth)
         (cl-incf depth)))
     (let ((depth 99))
       (dolist (func erc-matterircd--run-last-hook-functions)
         (add-hook hook func depth)
         (cl-decf depth)))
     ;; we want to make sure we come before erc-image-show-url in
     ;; erc-insert-modify-hook
     (when (and (fboundp 'erc-image-show-url)
                (member #'erc-image-show-url (eval hook)))
       ;; remove and re-add to get appended
       (remove-hook hook #'erc-image-show-url)
       (add-hook hook #'erc-image-show-url t)))
   ;; also ensure we can insert our own fake content ID on sent messages is
   ;; required
   (add-hook 'erc-send-modify-hook #'erc-matterircd-insert-fake-context-id -99))
  ((remove-hook 'erc-after-connect #'erc-matterircd-connect-to-mattermost)
   (remove-hook 'erc-send-modify-hook #'erc-matterircd-insert-fake-context-id)
   (dolist (hook '(erc-insert-modify-hook erc-send-modify-hook))
     (dolist (func (append erc-matterircd--run-last-hook-functions
                           erc-matterircd--run-first-hook-functions))
       (remove-hook hook func)))
   (delete #'erc-matterircd-complete-context-ids completion-at-point-functions)
   (advice-remove 'pcomplete-erc-nicks #'erc-matterircd-pcomplete-erc-nicks)
   (delete '(matterircd "matterircd.*") erc-networks-alist ))
  t)

(provide 'erc-matterircd)
;;; erc-matterircd.el ends here
