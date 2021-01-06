;;; mu4e-conversation.el --- Show a complete thread in a single buffer -*- lexical-binding: t -*-

;; Copyright (C) 2018 Pierre Neidhardt <mail@ambrevar.xyz>

;; Author: Pierre Neidhardt <mail@ambrevar.xyz>
;; Maintainer: Pierre Neidhardt <mail@ambrevar.xyz>
;; URL: https://gitlab.com/Ambrevar/mu4e-conversation
;; Package-Version: 20190609.812
;; Package-Commit: ccf85002b18fee54051dbfaf8d3931ca2a07db24
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: mail, convenience, mu4e

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package offers an alternate view to `mu4e' e-mail display.  It shows all
;; e-mails of a thread in a single view, where each correspondant has their own
;; face.  Threads can be displayed linearly (in which case e-mails are displayed
;; in chronological order) or as an Org document where the node tree maps the
;; thread tree.
;;
;; * Setup
;;
;; mu4e 1.0 or above is required.
;;
;; To fully replace `mu4e-view' with `mu4e-conversation' from any other command
;; (e.g. `mu4e-headers-next', `helm-mu'), call
;;
;;   (global-mu4e-conversation-mode)
;;
;; * Features
;;
;; Call `mu4e-conversation-toggle-view' (bound to "V" by default) to switch between
;; linear and tree view.
;;
;; The last section is writable.
;;
;; Call `mu4e-conversation-send' ("C-c C-c" by default) to send the message.
;;
;; When the region is active anywhere in the thread, `mu4e-conversation-cite'
;; ("<return>" by default) will append the selected text as citation to the
;; message being composed.  With prefix argument, the author name will be
;; prepended.
;;
;; Each conversation gets its own buffer.


;;; Code:

;; REVIEW: Overrides are not commended.  Use unwind-protect to set handlers?  I don't think it would work.
;; TODO: Only mark visible messages as read.
;; TODO: Detect subject changes.
;; TODO: Check out mu4e gnus view.
;; TODO: Should we reply to the selected message or to the last?  Make it an option: 'current, 'last, 'ask.
;; TODO: Does toggle-display HTML work?
;; TODO: Save using "save-buffer"?  This would allow different bindings to work
;; transparently (e.g. ":w" with Evil).  Problem is that the draft buffer and
;; the conversation view are different buffers.

;; TODO: Views should be structures with
;; - Thread sort function
;; - Previous / next function
;; - Print function
;; TODO: Indent user messages?  Make formatting more customizable.
;; TODO: Tweak Org indentation?  See `org-adapt-indentation'.

;; REVIEW: Sometimes messages are not marked as read.
;; TODO: When updating new message, mark previous ones as read.
;; TODO: Before next index update, display sent message in special area in buffer.  After index update, remove that area.
;; TODO: Add convenience functions to check if some recipients have been left out, or to return the list of all recipients.
;; TODO: Mark/flag messages that are in thread but not in headers buffer.  See `mu4e-mark-set'.
;; TODO: Fine-tune the recipient list display and composition in linear view.
;; In tree view, we could read properties from the composition subtree.

(require 'mu4e)
(require 'rx)
(require 'outline)
(require 'org)
(require 'subr-x)
(require 'cl-lib)
(require 'shr)

;; TODO: Merge headers and content into "messages".  Need ":thread" from headers.
;; (plist-get (mu4e-message-field msg-header :thread) :level)
(cl-defstruct (mu4e-conversation-thread
               (:copier nil)
               (:constructor mu4e-conversation--make-thread
                             (&optional msg &aux (current-docid (if msg (mu4e-message-field msg :docid) 0)))))
  "Structure that holds a thread and its associated buffer."
  content
  headers
  (current-docid 0)                     ; TODO: Replace with "current-message"?
  print-function
  buffer)

;; TODO: Include this into the thread structure?
(defvar mu4e-conversation--last-query-timestamp nil
  "Timestamp of the last query.
This can be used to know which message is \"new\".")

(defvar mu4e-conversation--thread-buffer-hash nil
  "A global hash map where keys are conversation buffers and values are threads.
This is useful to keep track of the conversation buffers.
A buffer local variable would not be as convenient since they are not preserved
across major mode change.")

(defun mu4e-conversation--buffer-p (&optional buffer)
  "Tell whether current buffer is a conversation view."
  (setq buffer (or buffer (current-buffer)))
  (when mu4e-conversation--thread-buffer-hash
    (gethash buffer mu4e-conversation--thread-buffer-hash)))

(defcustom mu4e-conversation-print-function 'mu4e-conversation-print-linear
  "Function that formats and inserts the content of a message in the current buffer.
The argument is the message index in the thread, counting from 0."
  :type '(choice (function :tag "Linear display" mu4e-conversation-print-linear)
                 (function :tag "Tree display" mu4e-conversation-print-tree))
  :group 'mu4e-conversation)

(defgroup mu4e-conversation nil
  "Settings for the mu4e conversation view."
  :group 'mu4e)

(defcustom mu4e-conversation-own-name "Me"
  "Name to display instead of your own name.
This applies to addresses matching `mu4e-user-mail-address-list'.
If nil, the name value is not substituted."
  :type 'string
  :group 'mu4e-conversation)

(defcustom mu4e-conversation-buffer-name-format "*mu4e-view-%s*"
  "Format of the conversation buffer name.
'%s' will be replaced by the buffer name."
  :type 'string
  :group 'mu4e-conversation)

(defcustom mu4e-conversation-before-send-hook nil
  "A hook run before sending messages.
For example, to disable appending signature at the end of a message:

  (add-hook
   'mu4e-conversation-before-send-hook
   (lambda ()
     (setq mu4e-compose-signature-auto-include nil)))
"
  ;; TODO: Test signature example.
  :type 'hook
  :group 'mu4e-conversation)

(defcustom mu4e-conversation-after-send-hook nil
  "A hook run after sending messages, if sucessful.
For example, if you use a remote SMTP server you might want to
immediately sync the \"sent mail\" folder so that it appears in
the conversation buffer.

Say you are using \"mbsync\" configured with a \"sent-mail-channel\":

  (add-hook
   'mu4e-conversation-after-send-hook
   (lambda ()
    (let ((mu4e-get-mail-command \"mbsync sent-mail-channel\"))
    (mu4e-update-mail-and-index 'run-in-background))))"
  :type 'hook
  :group 'mu4e-conversation)

(defcustom mu4e-conversation-hook nil
  "A hook run after displaying a conversation.
For example, use it to enable spell-checking:

  (add-hook 'mu4e-conversation-hook 'flyspell-mode)"
  :type 'hook
  :group 'mu4e-conversation)

(defcustom mu4e-conversation-use-citation-line nil
  "If non-nil, precede each citation with a line as per
`mu4e-conversation-citation-line-function'."
  :type 'boolean
  :group 'mu4e-conversation)

(defcustom mu4e-conversation-citation-line-function 'mu4e-conversation-insert-citation-line
  "Function called to insert the \"Whomever writes:\" line."
  :type '(choice
	  (function-item :tag "default" mu4e-conversation-insert-citation-line)
	  (function :tag "Other"))
  :group 'mu4e-conversation)

(defface mu4e-conversation-unread
  '((t :weight bold))
  "Face for unread messages."
  :group 'mu4e-conversation)

(defface mu4e-conversation-sender-me
  '((t :inherit default))
  "Face for conversation message sent by yourself."
  :group 'mu4e-conversation)

(defface mu4e-conversation-sender-1
  `((t :foreground ,(face-foreground 'outline-1 nil 'inherit)))
  "Face for conversation message from the 1st sender who is not yourself."
  :group 'mu4e-conversation)

(defface mu4e-conversation-sender-2
  `((t :foreground ,(face-foreground 'outline-2 nil 'inherit)))
  "Face for conversation message from the 2rd sender who is not yourself."
  :group 'mu4e-conversation)

(defface mu4e-conversation-sender-3
  `((t :foreground ,(face-foreground 'outline-3 nil 'inherit)))
  "Face for conversation message from the 3rd sender who is not yourself."
  :group 'mu4e-conversation)

(defface mu4e-conversation-sender-4
  `((t :foreground ,(face-foreground 'outline-4 nil 'inherit)))
  "Face for conversation message from the 4th sender who is not yourself."
  :group 'mu4e-conversation)

(defface mu4e-conversation-sender-5
  `((t :foreground ,(face-foreground 'outline-5 nil 'inherit)))
  "Face for conversation message from the 5th sender who is not yourself."
  :group 'mu4e-conversation)

(defface mu4e-conversation-sender-6
  `((t :foreground ,(face-foreground 'outline-6 nil 'inherit)))
  "Face for conversation message from the 6th sender who is not yourself."
  :group 'mu4e-conversation)

(defface mu4e-conversation-sender-7
  `((t :foreground ,(face-foreground 'outline-7 nil 'inherit)))
  "Face for conversation message from the 7th sender who is not yourself."
  :group 'mu4e-conversation)

(defface mu4e-conversation-sender-8
  `((t :foreground ,(face-foreground 'outline-8 nil 'inherit)))
  "Face for conversation message from the 8th sender who is not yourself."
  :group 'mu4e-conversation)

(defface mu4e-conversation-header
  '((t :foreground "grey70" :background "grey25"))
  "Face for conversation message sent by someone else."
  :group 'mu4e-conversation)

(defcustom mu4e-conversation-max-colors -1
  "Max number of colors to use to colorize sender messages.
If 0, don't use colors.
If less than 0, don't limit the number of colors."
  :type 'integer
  :group 'mu4e-conversation)

(defvar mu4e-conversation-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'mu4e-conversation-send)
    ;; Bind message-mark-inserted-region because I like it and otherwise it's
    ;; not available in Org mode.
    (define-key map (kbd "C-c M-m") 'message-mark-inserted-region)
    (define-key map (kbd "C-x C-s") 'mu4e-conversation-save)
    (define-key map (kbd "C-c C-p") 'mu4e-conversation-previous-message)
    (define-key map (kbd "C-c C-n") 'mu4e-conversation-next-message)
    map)
  "Map for `mu4e-conversation'.")

(defvar mu4e-conversation-thread-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<return>") 'mu4e-conversation-cite)
    (define-key map (kbd "M-q") 'mu4e-conversation-fill-long-lines)
    (define-key map (kbd "V") 'mu4e-conversation-toggle-view)
    (define-key map (kbd "#") 'mu4e-conversation-toggle-hide-cited)
    (define-key map (kbd "q") 'mu4e-conversation-quit)
    map)
  "Map for `mu4e-conversation' when over the read-only messages.")

(defun mu4e-conversation-fill-long-lines ()
  "Same as `mu4e-view-fill-long-lines' but does not change the modified state."
  (interactive)
  (unless (mu4e-conversation--buffer-p)
    (mu4e-warn "(fill-long-lines) Not a conversation buffer"))
  (let ((modified-p (buffer-modified-p))
        (mu4e~view-buffer-name (buffer-name))
        ;; We set mail-header-separator buffer-locally to separate the
        ;; conversation from the composition area, but that changes how
        ;; (message-goto-body-1) behaves for this function.  It should not match
        ;; anything here.
        (mail-header-separator (default-value 'mail-header-separator)))
    (set-buffer-modified-p nil)         ; Don't warn if modified.
    (mu4e-view-fill-long-lines)
    (set-buffer-modified-p modified-p)))

(defun mu4e-conversation-set-attachment (&optional msg &rest _)
  "Call before attachment
functions (e.g. `mu4e-view-save-attachment-multi') so that it
works for message at point.  Suitable as a :before advice."
  (interactive)
  (unless (mu4e-conversation--buffer-p)
    (mu4e-warn "(set-attachment) Not a conversation buffer"))
  (setq msg (or msg (mu4e-message-at-point)))
  (mu4e~view-construct-attachments-header msg))

(defun mu4e-conversation-fill-paragraph (orig-fun &optional region)
  "Like `mu4e-fill-paragraph' but also works on the composition area."
  (interactive)
  (if (mu4e-conversation--buffer-p)
      (let ((start (save-excursion (goto-char (point-max))
                                   (mu4e-conversation-previous-message)
                                   (forward-line)
                                   (point))))
        (save-restriction
          (narrow-to-region start (point-max))
          (apply orig-fun region)))
    (apply orig-fun region)))

(defun mu4e-conversation-previous-message (&optional count)
  "Go to previous message in linear view.
With numeric prefix argument or if COUNT is given, move that many
messages.  A negative COUNT goes forwards."
  (interactive "p")
  (mu4e-conversation-next-message (if count (- count) -1)))

(defun mu4e-conversation-next-message (&optional count)
  "Go to next message in linear view.
With numeric prefix argument or if COUNT is given, move that many
messages.  A negative COUNT goes backwards."
  (interactive "p")
  (unless (mu4e-conversation--buffer-p)
    (mu4e-warn "(next-message) Not a conversation buffer"))
  (setq count (or count 1))
  (if (eq major-mode 'org-mode)
      (org-next-visible-heading count)
    (let ((move-function (if (< count 0)
                             ;; Don't use `next-single-char-property-change' or
                             ;; else it would stop at flyspell's highlights, for
                             ;; instance.
                             'previous-single-property-change
                           'next-single-property-change))
          (limit (if (< count 0)
                     (point-min)
                   (point-max))))
      (setq count (abs count))
      (dotimes (_ count)
        (while (and (goto-char (funcall move-function (point) 'face nil limit))
                    (not (eq (get-text-property (point) 'face) 'mu4e-conversation-header))
                    (not (eobp))))))))

(defun mu4e-conversation-toggle-hide-cited ()
  "Toggle hiding of cited lines in the message body."
  (interactive)
  (if (and (listp buffer-invisibility-spec)
           (member '(mu4e-conversation-quote . t) buffer-invisibility-spec))
      (remove-from-invisibility-spec '(mu4e-conversation-quote . t))
    (add-to-invisibility-spec '(mu4e-conversation-quote . t)))
  (force-window-update))

(defun mu4e-conversation-kill-buffer-query-function ()
  "Ask before killing a modified mu4e conversation buffer."
  (let (conv-buffer)
    ;; We need to check if it is a conversation buffer first so that we know if
    ;; we need to run the exit cleanup.
    (when (or (not (setq conv-buffer (mu4e-conversation--buffer-p)))
              (not (buffer-modified-p))
              (yes-or-no-p  "Reply message has been modified.  Kill anyway? "))
      (when conv-buffer
        ;; Mark all messages as read.
        (dolist (msg (mu4e-conversation-thread-content
                      (gethash (current-buffer) mu4e-conversation--thread-buffer-hash)))
          (mu4e~view-mark-as-read-maybe msg))
        (remhash (current-buffer) mu4e-conversation--thread-buffer-hash))
      t)))

;; TODO: Add option to bury instead of quit.
(defun mu4e-conversation-quit (&optional no-confirm)
  "Quit conversation window.
If NO-CONFIRM is nil, ask for confirmation if message was not saved."
  ;; This function is useful as a replacement for `mu4e~view-quit-buffer': it
  ;; allows us to keep focus on the view buffer when we confirm not to quit.
  (interactive)
  (unless (mu4e-conversation--buffer-p)
    (mu4e-warn "(quit) Not a conversation buffer"))
  (when (or no-confirm
            (not (buffer-modified-p))
            (yes-or-no-p "Reply message has been modified.  Kill anyway? "))
    ;; Mark all messages as read.
    (dolist (msg (mu4e-conversation-thread-content
                  (gethash (current-buffer) mu4e-conversation--thread-buffer-hash)))
      (mu4e~view-mark-as-read-maybe msg))
    (remhash (current-buffer) mu4e-conversation--thread-buffer-hash)
    ;; Don't ask for confirmation again in the `kill-buffer-query-functions'.
    (set-buffer-modified-p nil)
    ;; `mu4e~view-quit-buffer' must be called from a buffer in `mu4e-view-mode'.
    (unless (eq major-mode 'mu4e-view-mode)
      (mu4e-view-mode))
    (mu4e~view-quit-buffer)))

(defun mu4e-conversation-toggle-view ()
  "Switch between tree and linear view."
  (interactive)
  (unless (mu4e-conversation--buffer-p)
    (mu4e-warn "(toggle-view) Not a conversation buffer"))
  (when (and buffer-undo-list
             (not (yes-or-no-p "Undo list will be reset after switching view.  Continue? ")))
    (mu4e-warn "Keeping undo list"))
  (mu4e-conversation--print
   (gethash (current-buffer) mu4e-conversation--thread-buffer-hash)
   (if (eq major-mode 'org-mode)
       'mu4e-conversation-print-linear
     'mu4e-conversation-print-tree)))

(defun mu4e-conversation--body-without-signature (message)
  "Return the message body (a string) stripped from its signature."
  (with-temp-buffer
    (insert (mu4e-message-body-text message))
    (goto-char (point-min))
    (when (looking-at "<#secure")
      ;; Discard MML line.
      (kill-whole-line))
    (message-goto-signature)
    (unless (eobp)
      (forward-line -1)
      (delete-region (point) (point-max)))
    (buffer-string)))

(defun  mu4e-conversation--get-buffer (&optional title)
  "Return conversation buffer.
This mimics the behaviour of `mu4e-get-view-buffer' but supports multiple
buffers.

- If TITLE is non-nil, return a buffer named (format
mu4e-conversation-buffer-name-format title) and create it if necessary.
- If current buffer is a conversation, return it.
- Otherwise get most recent conversation buffer."
  (cond
   (title (get-buffer-create (format mu4e-conversation-buffer-name-format title)))
   ((mu4e-conversation--buffer-p) (current-buffer))
   (t (seq-find #'mu4e-conversation--buffer-p
                (buffer-list)))))

(defun mu4e-conversation--title (thread)
  "Return THREAD title, that is, the subject of the first message."
  (mu4e-message-field
   (car (mu4e-conversation-thread-headers thread)) :subject))

(defun mu4e-conversation--headers-redraw-get-view-window ()
  "Like `mu4e~headers-redraw-get-view-window' but preserve conversation buffers."
  (if (eq mu4e-split-view 'single-window)
      (or (and (buffer-live-p (mu4e-get-view-buffer))
               (get-buffer-window (mu4e-get-view-buffer)))
          (selected-window))
    (mu4e-hide-other-mu4e-buffers)
    (unless (buffer-live-p (mu4e-get-headers-buffer))
      (mu4e-error "No headers buffer available"))
    (switch-to-buffer (mu4e-get-headers-buffer))
    ;; kill the existing view window
    (when (and (buffer-live-p (mu4e-get-view-buffer))
               (mu4e-conversation--buffer-p (mu4e-get-view-buffer)))
      (let ((win (get-buffer-window (mu4e-get-view-buffer))))
        (when (eq t (window-deletable-p win))
          (delete-window win))))
    ;; get a new view window
    (setq mu4e~headers-view-win
          (let* ((new-win-func
                  (cond
                   ((eq mu4e-split-view 'horizontal) ;; split horizontally
                    '(split-window-vertically mu4e-headers-visible-lines))
                   ((eq mu4e-split-view 'vertical) ;; split vertically
                    '(split-window-horizontally mu4e-headers-visible-columns)))))
            (cond ((with-demoted-errors "Unable to split window: %S"
                     (eval new-win-func)))
                  (t ;; no splitting; just use the currently selected one
                   (selected-window)))))))

(defun mu4e-conversation--line-number (thread-buffer)
  "Return current line-number relative to the message at point."
  (with-current-buffer thread-buffer
    (let ((block (org-get-property-block))
          begin end)
      (when block
        ;; Skip Org block.
        (save-excursion
          (goto-char (car block))
          (forward-line -1)
          (setq begin (point))
          (goto-char (cdr block))
          (forward-line 1)
          (setq end (point)))
        (cond
         ((< end (point))
          (forward-line (- (line-number-at-pos begin)
                           (line-number-at-pos end))))
         ((<= begin (point))
          (goto-char begin)
          (forward-line -1))))
      (let ((current-message (mu4e-message-at-point 'no-error)))
        (save-excursion
          (let ((current-line (line-number-at-pos)))
            (mu4e-conversation-previous-message)
            (if (or (not current-message)
                    ;; current-message might be nil when point is in a draft.
                    (eq current-message (mu4e-message-at-point 'no-error)))
                (- current-line (line-number-at-pos))
              0)))))))

(defun mu4e-conversation--goto-line (current-message line-offset)
  "Go to LINE-OFFSET, relative to the CURRENT-MESSAGE."
  (if (not current-message)
      ;; Draft.
      (progn
        (goto-char (point-max))
        (mu4e-conversation-previous-message))
    (goto-char (point-min))
    (while (and (not (eobp))
                (not (eq current-message (mu4e-message-at-point 'no-error))))
      (mu4e-conversation-next-message)))
  (let ((block (org-get-property-block))
        begin end)
    (when block
      (save-excursion
        (goto-char (car block))
        (forward-line -1)
        (setq begin (point))
        (goto-char (cdr block))
        (forward-line 1)
        (setq end (point))))
    (dotimes (_ line-offset)
      (forward-line)
      (when (and block
                 (<= begin (point) end))
        ;; If point meets an Org property block, skip it at once.
        (goto-char end)))))

(defvar mu4e-conversation--separator "Compose new message:"
  "The text displayed between the comversation and the
  composition area.")

;; TODO: Restore draft in composition area.
(defun mu4e-conversation--print (thread &optional print-function)
  "Print the conversation in the buffer associated to the THREAD.
If PRINT-FUNCTION is nil, use `mu4e-conversation-print-function'."
  ;; See the docstring of `mu4e-message-field-raw'.
  ;; We need to store the print-function so that updates don't revert the mode.
  (setq print-function (or print-function
                           (mu4e-conversation-thread-print-function thread)
                           mu4e-conversation-print-function))
  (setf (mu4e-conversation-thread-print-function thread) print-function)
  (let (line column current-message)
    (if (buffer-live-p (mu4e-conversation-thread-buffer thread))
        (setq line (mu4e-conversation--line-number (mu4e-conversation-thread-buffer thread))
              column (with-current-buffer (mu4e-conversation-thread-buffer thread)
                       (- (point) (line-beginning-position)))
              current-message (mu4e-message-at-point 'noerror))
      (setf (mu4e-conversation-thread-buffer thread)
            (mu4e-conversation--get-buffer (mu4e-conversation--title thread)))
      (mu4e-message "Found %d matching message%s"
                    (length (mu4e-conversation-thread-headers thread))
                    (if (= 1 (length (mu4e-conversation-thread-headers thread))) "" "s")))
    (with-current-buffer (mu4e-conversation-thread-buffer thread)
      ;; Register buffer as a conversation buffer.
      ;; This is used by `mu4e-conversation--buffer-p'.
      ;; Must set this here for the rest of the functions to work,
      ;; e.g. `mu4e-conversation-previous-message'.
      (unless mu4e-conversation--thread-buffer-hash
        (setq mu4e-conversation--thread-buffer-hash (make-hash-table)))
      (puthash (current-buffer) thread mu4e-conversation--thread-buffer-hash)
      (let* ((index 0)
             ;; If we want to re-order a thread, let's do it on a copy so that we
             ;; don't lose the tree structure.
             (thread-content-sorted (mu4e-conversation-thread-content thread))
             (thread-headers-sorted (mu4e-conversation-thread-headers thread))
             (inhibit-read-only t)
             ;; Extra care must be taken to copy along the draft with its properties, in
             ;; case it wasn't saved.
             (draft-text (when (buffer-modified-p)
                           (buffer-substring (save-excursion
                                               (goto-char (point-max))
                                               (mu4e-conversation-previous-message)
                                               (forward-line)
                                               (point))
                                             (point-max))))
             (buffer-modified (buffer-modified-p))
             draft-messages)
        (when (eq print-function
                  'mu4e-conversation-print-linear)
          ;; In linear view, it makes more sense to sort messages chronologically.
          (let ((filter (lambda (seq)
                          (sort (copy-sequence seq)
                                (lambda (msg1 msg2)
                                  (time-less-p (mu4e-message-field msg1 :date)
                                               (mu4e-message-field msg2 :date)))))))
            (setq thread-content-sorted (funcall filter thread-content-sorted)
                  thread-headers-sorted (funcall filter thread-headers-sorted))))
        (erase-buffer)
        (delete-all-overlays)
        (if (eq print-function 'mu4e-conversation-print-linear)
            (progn
              (mu4e-view-mode)
              (read-only-mode 0)
              (use-local-map (make-composed-keymap mu4e-conversation-map mu4e-compose-mode-map)))
          (insert "#+SEQ_TODO: UNREAD READ NEW\n\n")
          (org-mode)
          (erase-buffer) ; TODO: Is it possible to set `org-todo-keywords' locally without this workaround?
          (use-local-map (make-composed-keymap mu4e-conversation-map org-mode-map)))
        (dolist (msg thread-content-sorted)
          (if (member 'draft (mu4e-message-field msg :flags))
              (push msg draft-messages)
            (let ((begin (point)))
              (funcall print-function
                       index
                       thread-content-sorted
                       thread-headers-sorted)
              (mu4e~view-show-images-maybe msg)
              (goto-char (point-max))
              (add-text-properties begin (point) (list 'msg msg)))
            (insert (propertize "\n" 'msg msg)) ; Insert a final newline after potential images.
            (goto-char (point-max)))
          (setq index (1+ index)))
        (insert (propertize (format "%s%s" (if (eq major-mode 'org-mode) "* NEW " "")
                                    mu4e-conversation--separator)
                            'face 'mu4e-conversation-header 'read-only t)
                (propertize "\n"
                            'face 'mu4e-conversation-header
                            'rear-nonsticky t))
        (add-text-properties (point-min) (point-max)
                             `(
                               read-only t
                               local-map ,(if (eq major-mode 'org-mode)
                                              (make-composed-keymap
                                               (list mu4e-conversation-thread-map mu4e-conversation-map mu4e-view-mode-map)
                                               org-mode-map)
                                            (make-composed-keymap
                                             (list mu4e-conversation-thread-map mu4e-conversation-map)
                                             mu4e-view-mode-map))))
        (if draft-messages ""
          (insert (propertize
                   "\n"
                   'front-sticky t)))
        (cond
         (draft-text
          (save-excursion
            (goto-char (point-max))
            (mu4e-conversation-previous-message)
            (forward-line)
            (delete-region (point) (point-max))
            (insert draft-text)))
         (draft-messages
          ;; REVIEW: Discard signature.
          (add-text-properties
           (save-excursion (mu4e-conversation-previous-message)
                           (point))
           (point-max)
           (list 'msg (car draft-messages)))
          (if (= (length draft-messages) 1)
              (insert (propertize (mu4e-conversation--body-without-signature (car draft-messages))
                                  'msg (car draft-messages)
                                  'front-sticky t))
            (warn "Multiple drafts found.  You must clean up the drafts manually.")
            (let ((count 1))
              (dolist (draft draft-messages)
                (insert (propertize (concat (format "--Draft #%s--\n" count)
                                            (mu4e-conversation--body-without-signature draft))
                                    'msg (car draft-messages) ; Use first draft file.
                                    'front-sticky t))
                (setq count (1+ count)))))))
        (unless (eq major-mode 'org-mode)
          (mu4e~view-make-urls-clickable)) ; TODO: Don't discard sender face.
        (setq header-line-format (propertize
                                  (mu4e-conversation--title thread)
                                  'face 'bold))
        (add-to-invisibility-spec '(mu4e-conversation-quote . t))
        (set-buffer-modified-p buffer-modified)
        (add-to-list 'kill-buffer-query-functions 'mu4e-conversation-kill-buffer-query-function)
        ;; TODO: Undo history is not preserved accross redisplays.
        (buffer-disable-undo)           ; Reset `buffer-undo-list'.
        (buffer-enable-undo)
        (when line
          ;; Restore point.
          (mu4e-conversation--goto-line current-message line)
          (move-to-column column))
        ;; Set signature or commands like `message-insert-signature' won't work.
        (set (make-local-variable 'message-signature) mu4e-compose-signature)
        ;; We need to set `mail-header-separator' to ensure `mml-*' commands
        ;; work.
        (set (make-local-variable 'mail-header-separator)
             (format "%s%s" (if (eq major-mode 'org-mode) "* NEW " "")
                     mu4e-conversation--separator))
        (run-hooks 'mu4e-conversation-hook)))))

(defun mu4e-conversation--get-message-face (index thread)
  "Map 'from' addresses to 'sender-N' faces in chronological
order and return corresponding face for e-mail at INDEX in
THREAD.
E-mails whose sender is in `mu4e-user-mail-address-list' are skipped."
  (let* ((message (nth index thread))
         (from (car (mu4e-message-field message :from)))
         ;; The e-mail address is not enough as key since automated messaging
         ;; system such as the one from github have the same address with
         ;; different names.
         (sender-key (concat (car from) (cdr from)))
         (sender-faces (make-hash-table :test 'equal))
         (face-index 1))
    (dotimes (i (1+ index))
      (let* ((msg (nth i thread))
             (from (car (mu4e-message-field msg :from)))
             (sender-key (concat (car from) (cdr from)))
             (from-me-p (member (cdr from) mu4e-user-mail-address-list)))
        (unless (or from-me-p
                    (gethash sender-key sender-faces))
          (when (or (not (facep (intern (format "mu4e-conversation-sender-%s" face-index))))
                    (< 0 mu4e-conversation-max-colors face-index))
            (setq face-index 1))
          (puthash sender-key
                   (intern (format "mu4e-conversation-sender-%s" face-index))
                   sender-faces)
          (setq face-index (1+ face-index)))))
    (gethash sender-key sender-faces)))

(defun mu4e-conversation--from-name (message)
  "Return a string describing the sender (the 'from' field) of MESSAGE."
  (let* ((from (car (mu4e-message-field message :from)))
         (from-me-p (member (cdr from) mu4e-user-mail-address-list)))
    (if (and mu4e-conversation-own-name from-me-p)
        mu4e-conversation-own-name
      (concat (car from)
              (when (car from) " ")
              (format "<%s>" (cdr from))))))

(defun mu4e-conversation--propertize-quote (message)
  "Trim the replied-to emails quoted at the end of message."
  (with-temp-buffer
    (insert message)
    (goto-char (point-min))
    ;; Regexp seemed to be doomed to kill performance here, so we do it manually
    ;; instead.  It's not much longer anyways.
    (let (start)
      (while (not (eobp))
        (while (and (not (eobp)) (not (= (following-char) ?>)))
          (forward-line))
        (unless (eobp)
          (setq start (point))
          (while (and (not (eobp)) (= (following-char) ?>))
            (forward-line))
          (unless (eobp)
            ;; Optional gap.
            (while (and (not (eobp))
                        (string-match (rx line-start (* (any space)) line-end)
                                      (buffer-substring-no-properties
                                                  (line-beginning-position)
                                                  (line-end-position))))
              (forward-line))
            (if (or (eobp)
                    (string-match (rx line-start "--" (* (any space)) line-end)
                                  (buffer-substring-no-properties
                                                (line-beginning-position)
                                                (line-end-position))))
                ;; Found signature or end of buffer, no need to continue.
                (goto-char (point-max))
              ;; Restart the loop.
              (setq start nil)))))
      (when start
        ;; Buffer functions like (point) return 1-based indices while string
        ;; functions use 0-based indices.
        (add-text-properties (1- start) (length message)
                             '(invisible mu4e-conversation-quote) message)))))

(defun mu4e-conversation-print-linear (index thread-content &optional _thread-headers)
  "Insert formatted message found at INDEX in THREAD-CONTENT."
  (let* ((msg (nth index thread-content))
         (from (car (mu4e-message-field msg :from)))
         (from-me-p (member (cdr from) mu4e-user-mail-address-list))
         (sender-face (or (get-text-property (point) 'face)
                          (and from-me-p 'mu4e-conversation-sender-me)
                          (and (/= 0 mu4e-conversation-max-colors)
                               (mu4e-conversation--get-message-face
                                index
                                thread-content))
                          'default)))
    (insert (propertize (format "%s, %s %s\n"
                                (mu4e-conversation--from-name msg)
                                (current-time-string (mu4e-message-field msg :date))
                                (mu4e-message-field msg :flags))
                        'face 'mu4e-conversation-header)
            (or (mu4e~view-construct-attachments-header msg) "") ; TODO: Append newline?
            ;; TODO: Add button to display trimmed quote of current message only.
            (let ((s (mu4e-message-body-text msg)))
              (add-face-text-property 0 (length s) sender-face nil s)
              (mu4e-conversation--propertize-quote s)
              (when (memq 'unread (mu4e-message-field msg :flags))
                (add-face-text-property 0 (length s) 'mu4e-conversation-unread nil s))
              s))))

(defun mu4e-conversation--format-address-list (address-list)
  "Return ADDRESS-LIST as a string.
The list is in the following format:
  ((\"name\" . \"email\")...)"
  (mapconcat
   (lambda (addrcomp)
     (if (and message-recipients-without-full-name
              (string-match
               (regexp-opt message-recipients-without-full-name)
               (cdr addrcomp)))
         (cdr addrcomp)
       (if (car addrcomp)
           (message-make-from (car addrcomp) (cdr addrcomp))
         (cdr addrcomp))))
   address-list
   ", "))

(defcustom mu4e-conversation--use-org-quote-blocks nil
  "If non-nil, display quoted text as Org quote blocks.
If nil, prefix quoted text with ':'."
  :type 'boolean
  :group 'mu4e-conversation)

(defun mu4e-conversation--format-org-quote-blocks (body-start)
  "Turn all \">\"-prefixed quotes into Org quote blocks in
current buffer."
  (save-excursion
    (goto-char body-start)
    (while (not (eobp))
      (when (= (char-after) ?>)
        (delete-char 1)
        (when (= (char-after) ? )
          (delete-char 1))
        (beginning-of-line)
        (insert "#+begin_quote")
        (newline)
        (if (looking-at "[ \t]*$")
            (delete-blank-lines)
          (forward-line))
        (while (and (not (eobp))
                    (or (= (char-after) ?>)
                        (looking-at "[ \t]*$")))
          (when (= (char-after) ?>)
            (delete-char 1)
            (when (= (char-after) ? )
              (delete-char 1)))
          (forward-line))
        ;; Go back to first non-empty line.
        (forward-line -1)
        (while (looking-at "[ \t]*$")
          (forward-line -1))
        (forward-line)
        (insert "#+end_quote")
        (newline)
        (when (looking-at "[ \t]*$")
          (delete-blank-lines))
        (newline))
      (forward-line))))

(defun mu4e-conversation-print-tree (index thread-content thread-headers)
  "Insert Org-formatted message found at INDEX in THREAD-CONTENT."
  (let* ((msg (nth index thread-content))
         (msg-header (nth index thread-headers))
         (level (plist-get (mu4e-message-field msg-header :thread) :level))
         (org-level (make-string (1+ level) ?*))
         body-start)
    ;; Header.
    (insert (format "%s %s%s, %s %s\n"
                    org-level
                    (if (memq 'unread (mu4e-message-field msg :flags))
                        "UNREAD "
                      "")
                    (mu4e-conversation--from-name msg)
                    (current-time-string (mu4e-message-field msg :date))
                    (mu4e-message-field msg :flags)))
    ;; Body
    (goto-char (point-max))
    (setq body-start (point))
    (insert (mu4e-message-body-text msg))
    ;; Turn shr-url into Org links.
    (goto-char body-start)
    (let (begin end url text)
      (while (and (not (eobp))
                  (setq begin (next-single-char-property-change (point) 'shr-url))
                  (get-text-property begin 'shr-url))
        (goto-char begin)
        (setq url (get-text-property (point) 'shr-url)
              end (next-single-char-property-change (point) 'shr-url)
              text (buffer-substring-no-properties begin end))
        (delete-region begin end)
        (insert (format "[[%s][%s]]" url text))))
    ;; Prefix "*" at the beginning of lines with a space to prevent them
    ;; from being interpreted as Org sections.
    (goto-char body-start)
    (while (re-search-forward (rx line-start "*") nil t) (replace-match " *"))
    (goto-char body-start)
    (if mu4e-conversation--use-org-quote-blocks
        (mu4e-conversation--format-org-quote-blocks body-start)
        (while (re-search-forward (rx line-start ">" (?  blank)) nil t) (replace-match ": ")))
    (goto-char body-start)
    (while (re-search-forward (concat "^" message-mark-insert-begin) nil t)
      (replace-match "#+begin_src
"))
    (goto-char body-start)
    (while (re-search-forward (concat "^" message-mark-insert-end) nil t)
      (replace-match "#+end_src
"))
    (goto-char (point-max))
    (org-set-property "Maildir" (mu4e-message-field msg :maildir))
    (org-set-property "To" (mu4e-conversation--format-address-list
                            (mu4e-message-field msg :to)))
    (when (mu4e-message-field msg :cc)
      (org-set-property "CC" (mu4e-conversation--format-address-list
                              (mu4e-message-field msg :cc))))
    (let ((attachments (mu4e~view-construct-attachments-header msg)))
      ;; TODO: Propertize attachments.
      (when attachments
        (org-set-property "Attachments" (replace-regexp-in-string "\n$" "" attachments)))
      (when (and (< (length (mu4e-message-field msg :to)) 2)
                 (not (mu4e-message-field msg :cc))
                 (not attachments))
        (save-excursion
          (goto-char (car (org-get-property-block)))
          (forward-line -1)
          (org-cycle))))))

(defun mu4e-conversation-insert-citation-line (&optional msg)
  "This is similar to `message-insert-citation-line' but takes a
mu4e message as argument."
  (setq msg (or msg (mu4e-message-at-point)))
  (concat
   (mu4e-conversation--format-address-list (mu4e-message-field msg :from))
   " writes:\n"))

(defun mu4e-conversation-cite (start end &optional toggle-citation-line)
  (interactive "r\nP")
  (unless (mu4e-conversation--buffer-p)
    (mu4e-warn "(cite) Not a conversation buffer"))
  (if (not (use-region-p))
      (mu4e-scroll-up)                  ; TODO: Call function associate to `this-command-key' in mu4e-view-mode / org-mode.
    (let ((text (replace-regexp-in-string
                 (rx (or (group (1+ "\n") string-end)
                         (group string-start (1+ "\n"))))
                 ""
                 (buffer-substring-no-properties start end)))
          (mu4e-conversation-use-citation-line (if toggle-citation-line
                                             (not mu4e-conversation-use-citation-line)
                                           mu4e-conversation-use-citation-line))
          (msg (mu4e-message-at-point)))
      (save-excursion
        (goto-char (point-max))
        (newline 2)
        (delete-blank-lines)
        (newline)
        (insert
         (if (and mu4e-conversation-use-citation-line msg)
             (funcall mu4e-conversation-citation-line-function msg)
           "")
         "> "
         ;; TODO: Re-cite first line properly.
         (replace-regexp-in-string
          "\n" "\n> "
          text))))))

(defun mu4e-conversation--open-draft (&optional msg)
  "Open conversation composed message as a mu4e draft buffer.
This is a helper function for operations such as saving and sending."
  (unless (mu4e-conversation--buffer-p)
    (mu4e-warn "(open-draft) Not a conversation buffer"))
  (let ((mu4e-compose-in-new-frame nil)
        (body (save-excursion
                (goto-char (point-max))
                (mu4e-conversation-previous-message)
                (forward-line)
                (buffer-substring-no-properties (line-beginning-position 1) (point-max))))
        (draft-message (save-excursion
                         (goto-char (point-max))
                         (mu4e-conversation-previous-message)
                         (forward-line)
                         (mu4e-message-at-point 'noerror)))
        (msg (or msg
                 (mu4e-message-at-point 'noerror)
                 (save-excursion
                   (goto-char (point-max))
                   (mu4e-conversation-previous-message 2)
                   (mu4e-message-at-point)))))
    (when (string-blank-p
           (replace-regexp-in-string
            (rx string-start ">" (* not-newline))
            ""
            (replace-regexp-in-string (rx "\n>" (* not-newline)) "" body)))
      (mu4e-warn "Empty or citation-only message"))
    ;; Pick context from parent message.  This is important if the user
    ;; configuration sets variable like `smtpmail-smtp-user' in a context.
    (mu4e~context-autoswitch msg
                             mu4e-compose-context-policy)
    ;; `mu4e-compose-pre-hook' can be use to, for instance, set the signature.
    (run-hooks 'mu4e-compose-pre-hook)
    (if draft-message
        (mu4e-draft-open 'edit draft-message)
      ;; Advice mu4e~draft-reply-all-p so that we don't get prompted and always "reply to all".
      ;; TODO: Protect the advice so that it gets remove cleanly even in case of error.
      (advice-add 'mu4e~draft-reply-all-p :override 'mu4e-conversation--draft-reply-all-p)
      (mu4e-draft-open 'reply msg)
      (advice-remove 'mu4e~draft-reply-all-p 'mu4e-conversation--draft-reply-all-p))
    (mu4e~draft-insert-mail-header-separator)
    (mu4e-compose-mode)
    (message-goto-body)
    (when (looking-at "<#secure")
      (if (string-match "^<#secure" body)
          ;; If body has a <#secure...> MML line, use it instead of the possibly
          ;; existing one.
          (kill-whole-line)
        ;; Keep existing MML line.
        (forward-line)))
    ;; Delete citation:
    (delete-region (point) (save-excursion
                             (message-goto-signature)
                             (if (eobp)
                                 (point)
                               (forward-line -2)
                               (point))))
    (insert
     ;; Ensure there is a newline between body and signature.
     (replace-regexp-in-string "\n*$" "\n" body))))

(defcustom mu4e-conversation-kill-buffer-on-exit nil
  "If non-nil, kill the conversation buffer after sending a message."
  :type 'boolean
  :group 'mu4e-conversation)

(defun mu4e-conversation-send (&optional msg)
  "Send message at the end of the view buffer.
If MSG is specified, then send this message instead.

Most `mu4e-compose-…' variables are lexically bound during the
call of this function."
  (interactive)
  (unless (mu4e-conversation--buffer-p)
    (mu4e-warn "(send) Not a conversation buffer"))
  (let (draft-buf
        (buf (current-buffer))
        (mu4e-compose-signature mu4e-compose-signature)
        (mu4e-compose-keep-self-cc mu4e-compose-keep-self-cc)
        (mu4e-compose-format-flowed mu4e-compose-format-flowed)
        (mu4e-compose-cite-function mu4e-compose-cite-function)
        (mu4e-compose-reply-to-address mu4e-compose-reply-to-address)
        (mu4e-compose-auto-include-date mu4e-compose-auto-include-date)
        (mu4e-compose-dont-reply-to-self mu4e-compose-dont-reply-to-self)
        (mu4e-compose-reply-ignore-address mu4e-compose-reply-ignore-address)
        (mu4e-compose-forward-as-attachment mu4e-compose-forward-as-attachment)
        (mu4e-compose-signature-auto-include mu4e-compose-signature-auto-include)
        (mu4e-compose-crypto-reply-plain-policy mu4e-compose-crypto-reply-plain-policy)
        (mu4e-compose-crypto-reply-encrypted-policy mu4e-compose-crypto-reply-encrypted-policy))
    (run-hooks 'mu4e-conversation-before-send-hook)
    (save-window-excursion
      (mu4e-conversation--open-draft msg)
      (condition-case nil
          ;; Force-kill DRAFT-BUF on succcess since it's an implementation
          ;; detail in mu4e-conversation and the composition area is in BUF.
          (let ((message-kill-buffer-on-exit t))
            (message-send-and-exit))
        ;; Stay in draft buffer and widen in case we failed during header check.
        (error (setq draft-buf (current-buffer))
               (widen))))
    (cond
     (draft-buf
      (switch-to-buffer draft-buf))
     (mu4e-conversation-kill-buffer-on-exit
      (switch-to-buffer buf)
      (mu4e-conversation-quit 'no-confirm))
     (t
      ;; Delete message that was just sent.
      (goto-char (point-max))
      (mu4e-conversation-previous-message)
      (forward-line)
      (delete-region (line-beginning-position 1) (point-max))
      ;; Ensure it's writable.
      (insert
       (propertize "\n"
                   'face 'mu4e-conversation-header
                   'rear-nonsticky t))
      (set-buffer-modified-p nil)
      ;; -after-send-hook can be used to update the conversation buffer so that
      ;; it includes the message that was just sent.
      (run-hooks 'mu4e-conversation-after-send-hook)))))

;; TODO: Can we do better than a global?  We could use `mu4e-get-view-buffer'
;; but that would only work if the buffer has not been renamed.  With
;; `mu4e-conversation--get-buffer' it should work.
(defvar mu4e-conversation--draft-msg nil)
(defun mu4e-conversation--update-draft (msg _)
  "Handler for `mu4e-update-func' to get the msg structure corresponding to the saved draft."
  (setq mu4e-conversation--draft-msg msg))

(defun mu4e-conversation-save (&optional msg)
  "Save conversation draft."
  (interactive)
  (unless (mu4e-conversation--buffer-p)
    (mu4e-warn "(save) Not a conversation buffer"))
  (unless (buffer-modified-p)
    (mu4e-warn "(No changes need to be saved)"))
  (let ((composition-start (save-excursion
                             (goto-char (point-max))
                             (mu4e-conversation-previous-message)
                             (forward-line)
                             (point)))
        (draft-message (save-excursion
                         (goto-char (point-max))
                         (mu4e-conversation-previous-message)
                         (forward-line)
                         (mu4e-message-at-point 'noerror))))
    (save-window-excursion
      (mu4e-conversation--open-draft msg)
      ;; TODO: Use transaction?
      (unless draft-message
        (advice-add mu4e-update-func :override 'mu4e-conversation--update-draft))
      (save-buffer)
      (unless draft-message
        (advice-remove mu4e-update-func 'mu4e-conversation--update-draft))
      (kill-buffer))
    (unless draft-message
      ;; We need to add the newly created draft to the 'msg property, otherwise
      ;; every subsequent save would create a new draft.
      (add-text-properties composition-start (point-max)
                           (list 'msg mu4e-conversation--draft-msg)))
    (set-buffer-modified-p nil)))

(defun mu4e-conversation--draft-reply-all-p (&optional _origmsg)
  "Override of `mu4e~draft-reply-all-p' to always reply to all."
  t)

(defun mu4e-conversation--find-buffer (msg)
  "Return the conversation buffer displaying MSG.
Return nil if there is none."
  ;; TODO: Early out?
  (when mu4e-conversation--thread-buffer-hash
    (let (buf)
      (maphash (lambda (buffer thread)
                 (when (or (memq msg (mu4e-conversation-thread-content thread))
                           (seq-find (lambda (m)
                                       (eq (mu4e-message-field m :docid)
                                           (mu4e-message-field msg :docid)))
                                     (mu4e-conversation-thread-content thread)))
                   (setq buf buffer)))
               mu4e-conversation--thread-buffer-hash)
      buf)))

(defun mu4e-conversation--update (thread)
  "If old version of the same thread is already known with a live
buffer, re-print it."
  (let ((buf (mu4e-conversation--find-buffer
              ;; TODO: Is the `car' guaranteed to be the same in the old
              ;; and the new thread?
              (car (mu4e-conversation-thread-content thread)))))
    (when (buffer-live-p buf)
      ;; TODO: Make sure we handle renamed buffers.
      ;; (puthash buf thread mu4e-conversation--thread-buffer-hash)
      (setf (mu4e-conversation-thread-buffer thread) buf)
      (mu4e-conversation--print thread))))

;; TODO: Make sure we handle message removal.
(defun mu4e-conversation--update-handler-extra (msg &optional _is-move)
  "If MSG belongs to a live-buffer, update the buffer.
Suitable to be run after the update handler."
  (let ((thread (and mu4e-conversation--thread-buffer-hash
                     (gethash (mu4e-conversation--find-buffer msg)
                              mu4e-conversation--thread-buffer-hash))))
        ;; Messages not matching any thread here are not new.  New messages
        ;; should be handled via the `mu4e-index-updated-hook'.
    (when thread
      ;; If MSG can be found in a live-buffer, no need to -query-thread,
      ;; just manually replace msg in thread and re-print.
      ;; TODO: Make sure that replacing the thread-content and not the
      ;; thread-header is enough.
      (cl-nsubstitute-if msg
                         (lambda (m) (eq (mu4e-message-field m :docid)
                                         (mu4e-message-field msg :docid)))
                         (mu4e-conversation-thread-content thread))
      (mu4e-conversation--print thread))))

;; TODO: Merge --show and --switch-to-buffer?
(defun mu4e-conversation--switch-to-buffer (thread)
  (unless (buffer-live-p (mu4e-conversation-thread-buffer thread))
    (mu4e-conversation--print thread))
  ;; TODO: Use mu4e's algorithm to select window.
  (let ((viewwin (get-buffer-window (mu4e-conversation-thread-buffer thread))))
    (if (window-live-p viewwin)
        (select-window viewwin)
      (switch-to-buffer (mu4e-conversation-thread-buffer thread))))
  ;; Move point to the message corresponding to the current-docid.
  (goto-char (point-min))
  (while (and (not (eobp))
              (mu4e-message-at-point 'noerror)
              (not (eq (mu4e-message-field (mu4e-message-at-point 'noerror) :docid)
                       (mu4e-conversation-thread-current-docid thread))))
    (mu4e-conversation-next-message))
  (recenter))

(defun mu4e-conversation--show (thread)
  "Switch to conversation buffer."
  (unless (buffer-live-p (mu4e-conversation-thread-buffer thread))
    (mu4e-conversation--print thread))
  (mu4e-conversation--switch-to-buffer thread))

;; TODO: Recenter sync'ed window where it was.  Or recenter it on the first new
;; message?
;; TODO: Preserve view function on sync.
(defun mu4e-conversation--sync (new-messages)
  "Re-print view buffers with new messages"
  (dolist (msg (mu4e-conversation-thread-content new-messages))
    ;; TODO: Pack messages together so that --query-thread is run only once per
    ;; thread for performance reasons.
    (mu4e-log 'misc "Sync %S" msg)
    (mu4e-conversation--query-thread 'mu4e-conversation--update
                                     (format "msgid:%s"
                                             (mu4e-message-field msg :message-id))
                                     msg
                                     'show-thread
                                     'include-related)))

(defvar mu4e-conversation--transaction-queue nil)
(defvar mu4e-conversation--transaction-marker "mu4e-conversation")
(defun mu4e-conversation--transaction-marker-p (sexp)
  "Return non-nil if sexp is a transaction marker.
See `mu4e-conversation--proc-filter'."
  (and (plist-get sexp :error)
       ;; Message to parse: "expected: '<alphanum>+:' (mu4e-conversation)"
       (string= (replace-regexp-in-string
                 (rx (* any) "(" (group (+ (any alnum punct))) ")" string-end)
                 "\\1"
                 (plist-get sexp :message))
                mu4e-conversation--transaction-marker)))

(defun mu4e-conversation--enqueue (callback command &rest args)
  "Enqueue transaction (COMMAND ARGS) and run CALLBACK on the response.
CALLBACK must take a list of mu4e sexps.  See `mu4e~proc-filter'.
COMMAND must be (possibly indirectly) calling `mu4e-proc-send-command'."
  ;; We roll our own transaction queue system because Emacs' `tq' package has
  ;; some flaws: it needs a regexp to identify the transactions in the output,
  ;; which is rather unreliable and a possibly a performance killer.
  (setq mu4e-conversation--transaction-queue
        (nconc mu4e-conversation--transaction-queue (list callback)))
  (mu4e-log 'to-server "New transaction (new total %s)"
            (length mu4e-conversation--transaction-queue))
  ;; Because "mu server" does not identify transactions itself, we use a hack:
  ;; we wrap the transaction between calls to well-known erronerous commands
  ;; that act as begin/end markers.  By parsing the error responses that
  ;; references those markers, we know that all responses in-between correspond
  ;; to the actual transaction.
  (mu4e~proc-send-command mu4e-conversation--transaction-marker)
  (apply command args)
  (mu4e~proc-send-command mu4e-conversation--transaction-marker)
  (mu4e-log 'to-server "Transaction sent"))

(defvar mu4e-conversation--transaction-running nil)

;; TODO: Don't override proc-filter function, set process filter to this instead?
;; Then we could call the original proc-filter instead of the big copy-paste at the end?
;; Maybe not, since we still need to catch the marker (an error) in the original proc-filter.
(defun mu4e-conversation--proc-filter (_proc str)
  "Like `mu4e~proc-filter' but if a transaction is running, run
its associated function instead of the usual filter.  The
function takes every s-exp as argument.

See `mu4e-conversation--enqueue' to add a transaction."
  (mu4e-log 'misc "* Received %d byte(s)" (length str))
  (setq mu4e~proc-buf (concat mu4e~proc-buf str)) ;; update our buffer
  (let ((sexp (mu4e~proc-eat-sexp-from-buf)))
    (cond
     ((and (mu4e-conversation--transaction-marker-p sexp)
           mu4e-conversation--transaction-running)
      (setq mu4e-conversation--transaction-running nil)
      (mu4e-log 'from-server "Transaction end (old total %s)"
                (length mu4e-conversation--transaction-queue))
      (pop mu4e-conversation--transaction-queue)
      (mu4e-conversation--proc-filter nil ""))
     ((and (mu4e-conversation--transaction-marker-p sexp)
           (not mu4e-conversation--transaction-running))
      (setq mu4e-conversation--transaction-running t)
      (mu4e-log 'from-server "Transaction start (total %s)"
                (length mu4e-conversation--transaction-queue))
      (mu4e-conversation--proc-filter nil ""))
     (mu4e-conversation--transaction-running
      (let ((sexp-list (list sexp)))
        (while (and (setq sexp (mu4e~proc-eat-sexp-from-buf))
                    (not (mu4e-conversation--transaction-marker-p sexp)))
          (mu4e-log 'from-server "%S" sexp)
          (setq sexp-list (nconc sexp-list (list sexp))))
        (funcall (car mu4e-conversation--transaction-queue) sexp-list)
        (when (mu4e-conversation--transaction-marker-p sexp)
          (setq mu4e-conversation--transaction-running nil)
          (mu4e-log 'from-server "Transaction end (old total %s)"
                    (length mu4e-conversation--transaction-queue))
          (pop mu4e-conversation--transaction-queue)
          (mu4e-conversation--proc-filter nil ""))
        ;; Don't call the proc filter
        ;; recursively if buffer is empty, otherwise it will call itself to much
        ;; before the next s-exp is made available.
        ))
     (t
      ;; Rest of the function as in the original except that we recurse when we
      ;; find a marker.
      (let (marker)
        (with-local-quit
          (while (and sexp (not marker))
            (mu4e-log 'from-server "%S" sexp)
            (cond
             ;; a header plist can be recognized by the existence of a :date field
             ((plist-get sexp :date)
              (funcall mu4e-header-func sexp))

             ;; the found sexp, we receive after getting all the headers
             ((plist-get sexp :found)
              (funcall mu4e-found-func (plist-get sexp :found)))

             ;; viewing a specific message
             ((plist-get sexp :view)
              (funcall mu4e-view-func (plist-get sexp :view)))

             ;; receive an erase message
             ((plist-get sexp :erase)
              (funcall mu4e-erase-func))

             ;; receive a :sent message
             ((plist-get sexp :sent)
              (funcall mu4e-sent-func
                       (plist-get sexp :docid)
                       (plist-get sexp :path)))

             ;; received a pong message
             ((plist-get sexp :pong)
              (funcall mu4e-pong-func
                       (plist-get sexp :props)))

             ;; received a contacts message
             ;; note: we use 'member', to match (:contacts nil)
             ((plist-member sexp :contacts)
              (funcall mu4e-contacts-func
                       (plist-get sexp :contacts)))

             ;; something got moved/flags changed
             ((plist-get sexp :update)
              (funcall mu4e-update-func
                       (plist-get sexp :update) (plist-get sexp :move)))

             ;; a message got removed
             ((plist-get sexp :remove)
              (funcall mu4e-remove-func (plist-get sexp :remove)))

             ;; start composing a new message
             ((plist-get sexp :compose)
              (funcall mu4e-compose-func
                       (plist-get sexp :compose)
                       (plist-get sexp :original)
                       (plist-get sexp :include)))

             ;; do something with a temporary file
             ((plist-get sexp :temp)
              (funcall mu4e-temp-func
                       (plist-get sexp :temp)  ;; name of the temp file
                       (plist-get sexp :what)  ;; what to do with it
                       ;; (pipe|emacs|open-with...)
                       (plist-get sexp :docid) ;; docid of the message
                       (plist-get sexp :param))) ;; parameter for the action

             ;; get some info
             ((plist-get sexp :info)
              (funcall mu4e-info-func sexp))

             ;; receive an error
             ((plist-get sexp :error)
              (if (mu4e-conversation--transaction-marker-p sexp)
                  (setq marker t)
                (funcall mu4e-error-func
                         (plist-get sexp :error)
                         (plist-get sexp :message))))

             (t (mu4e-message "Unexpected data from server [%S]" sexp)))

            (setq sexp (mu4e~proc-eat-sexp-from-buf)))
          (when marker
            (setq mu4e-conversation--transaction-running t)
            (mu4e-log 'from-server "Transaction start (total %s)"
                      (length mu4e-conversation--transaction-queue))
            (mu4e-conversation--proc-filter nil ""))))))))

(defun mu4e-conversation--proc-start-reset ()
  "Call before `mu4e~proc-start' to make sure the transaction queue is clean when starting.
This is useful when we restart the server.
Suitable as a :before advice"
  (setq mu4e-conversation--transaction-running nil)
  (setq mu4e-conversation--transaction-queue nil))

(defun mu4e-conversation--query-thread (query-function query &optional message show-thread include-related)
  (setq message (or message (mu4e-message-at-point 'noerror)))
  (let ((count 0)
        collect-headers
        collect-bodies
        headers
        bodies
        collect-headers-done
        collect-bodies-done)
    ;; We need closures to share headers and bodies across callbacks.
    ;; A callback can be called multiple times.
    (setq collect-bodies
          (lambda (sexp-list)
            (while sexp-list
              (when (plist-get (car sexp-list) :view)
                (setq bodies (nconc bodies (list (plist-get (car sexp-list) :view)))))
              (setq sexp-list (cdr sexp-list)))
            (mu4e-log 'from-server "Total headers %s, bodies %s" (length headers) (length bodies))
            (when (and (not collect-bodies-done) (= (length headers) (length bodies)))
              ;; If more sexps come after headers are complete, this could be
              ;; run several times.  Thus the guard.
              (setq collect-bodies-done t)
              (let ((thread (mu4e-conversation--make-thread message)))
                (setf (mu4e-conversation-thread-content thread) bodies)
                (setf (mu4e-conversation-thread-headers thread) headers)
                (funcall query-function thread)))))
    (setq collect-headers
          (lambda (sexp-list)
            (dolist (sexp sexp-list)
              (cond
               ((plist-get sexp :date)
                (setq headers (nconc headers (list sexp))))
               ((plist-get sexp :found)
                (setq count (+ count (plist-get sexp :found))))))
            (setq mu4e-conversation--last-query-timestamp (format-time-string "%Y-%m-%dT%H:%M:%S"))
            (mu4e-log 'from-server "Total headers %s%s"
                      (length headers)
                      (if (/= count 0) (format ", count %s" count) ""))
            (when (and (not collect-headers-done) (> count 0) (= (length headers) count))
              (setq collect-headers-done t)
              (dolist (msg headers)
                (let ((docid (mu4e-message-field msg :docid))
                      ;; decrypt (or not), based on `mu4e-decryption-policy'.
                      (decrypt
                       (and (member 'encrypted (mu4e-message-field msg :flags))
                            (if (eq mu4e-decryption-policy 'ask)
                                (yes-or-no-p (mu4e-format "Decrypt message?")) ; TODO: Never ask.
                              mu4e-decryption-policy))))
                  (mu4e-conversation--enqueue
                   collect-bodies
                   'mu4e~proc-view docid mu4e-view-show-images decrypt))))))
    (mu4e-conversation--enqueue
     collect-headers
     'mu4e~proc-find
     ;; `mu4e-query-rewrite-function' seems to be missing from mu<1.0.
     (funcall (or mu4e-query-rewrite-function 'identity)
              query)
     show-thread
     :date
     'ascending
     (not 'limited)
     'skip-duplicates
     include-related)))

(defun mu4e-conversation--query-new ()
  "Query all unread messages.
This is useful after an index update to include the new messages
in existing view buffers. "
  (when mu4e-conversation--last-query-timestamp
    (mu4e-log 'to-server "Querying new messages since %s" mu4e-conversation--last-query-timestamp)
    (mu4e-conversation--query-thread
     'mu4e-conversation--sync
     ;; Don't use flag:unread or else it won't see newly sent messages.
     (format "date:%s..now" mu4e-conversation--last-query-timestamp))))

(define-minor-mode mu4e-conversation-mode
  "Replace `mu4e-view' with `mu4e-conversation'."
  :init-value nil
  (if mu4e-conversation-mode
      (progn
        ;; TODO: Finish & test window management.
        (advice-add 'mu4e-get-view-buffer :override 'mu4e-conversation--get-buffer)
        (advice-add 'mu4e~headers-redraw-get-view-window :override 'mu4e-conversation--headers-redraw-get-view-window)
        (advice-add 'mu4e~proc-filter :override 'mu4e-conversation--proc-filter)
        (advice-add 'mu4e~proc-start :before 'mu4e-conversation--proc-start-reset)
        ;; Some commands need specialization:
        (advice-add 'mu4e-view-save-attachment-multi :before 'mu4e-conversation-set-attachment)
        (advice-add 'mu4e-view-save-attachment-single :before 'mu4e-conversation-set-attachment)
        (advice-add 'mu4e-view-open-attachment :before 'mu4e-conversation-set-attachment)
        (advice-add 'mu4e-fill-paragraph :around 'mu4e-conversation-fill-paragraph)
        ;; Live-update the buffer:
        (advice-add mu4e-update-func :after 'mu4e-conversation--update-handler-extra)
        (add-hook 'mu4e-index-updated-hook 'mu4e-conversation--query-new)
        (advice-add mu4e-view-func :override 'mu4e-conversation))
    (advice-remove 'mu4e-get-view-buffer 'mu4e-conversation--get-buffer)
    (advice-remove 'mu4e~headers-redraw-get-view-window 'mu4e-conversation--headers-redraw-get-view-window)
    (advice-remove 'mu4e~proc-filter 'mu4e-conversation--proc-filter)
    (advice-remove 'mu4e~proc-start 'mu4e-conversation--proc-start-reset)
    ;; De-specialize.
    (advice-remove 'mu4e-view-save-attachment-multi 'mu4e-conversation-set-attachment)
    (advice-remove 'mu4e-view-save-attachment-single 'mu4e-conversation-set-attachment)
    (advice-remove 'mu4e-view-open-attachment 'mu4e-conversation-set-attachment)
    (advice-remove 'mu4e-fill-paragraph 'mu4e-conversation-fill-paragraph)
    ;; Remove live-updates.
    (advice-remove mu4e-update-func 'mu4e-conversation--update-handler-extra)
    (remove-hook 'mu4e-index-updated-hook 'mu4e-conversation--query-new)
    (advice-remove mu4e-view-func 'mu4e-conversation)
    (setq kill-buffer-query-functions (delq 'mu4e-conversation-kill-buffer-query-function kill-buffer-query-functions))))

;; mu4e >1.0 has this function.
(declare-function mu4e~view-define-mode "mu4e-view")
(defun mu4e-conversation--turn-on ()
  "Turn on `mu4e-conversation-mode'."
  (mu4e-conversation-mode)
  (unless (fboundp 'mu4e-view-mode)
    (mu4e~view-define-mode)))

;;;###autoload
(define-globalized-minor-mode global-mu4e-conversation-mode mu4e-conversation-mode mu4e-conversation--turn-on
  :require 'mu4e-conversation)

;;;###autoload
(defun mu4e-conversation (&optional msg)
  (interactive)
  (unless (or mu4e-conversation-mode global-mu4e-conversation-mode)
    (mu4e-warn "mu4e-conversation-mode must be enabled"))
  (setq msg (or msg (mu4e-message-at-point)))
  (unless msg
    (mu4e-warn "No message at point"))
  (if (and msg (gethash (mu4e-message-field msg :path)
                        mu4e~path-parent-docid-map))
      ;; If msg is embedded, use vanilla `mu4e-view'.
      (mu4e-view msg)
    (let ((thread (and mu4e-conversation--thread-buffer-hash
                       (gethash (mu4e-conversation--find-buffer msg)
                                mu4e-conversation--thread-buffer-hash))))
      (if (not thread)
          (mu4e-conversation--query-thread 'mu4e-conversation--show
                                           (format "msgid:%s"
                                                   (mu4e-message-field msg :message-id))
                                           msg
                                           'show-thread
                                           'include-related)
        (setf (mu4e-conversation-thread-current-docid thread) (mu4e-message-field msg :docid))
        (mu4e-conversation--switch-to-buffer thread)))))

(provide 'mu4e-conversation)
;;; mu4e-conversation.el ends here
