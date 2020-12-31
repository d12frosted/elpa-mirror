;;; mu4e-views.el --- View emails in mu4e using xwidget-webkit -*- lexical-binding: t -*-

;; Author: Boris Glavic <lordpretzel@gmail.com>
;; Maintainer: Boris Glavic <lordpretzel@gmail.com>
;; Version: 0.3
;; Package-Version: 20201229.216
;; Package-Commit: 55e5467a25d424b2c10b5392e68b370164efa230
;; Package-Requires: ((emacs "26.1") (xwidgets-reuse "0.2") (ht "2.2"))
;; Homepage: https://github.com/lordpretzel/mu4e-views
;; Keywords: mail


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; `mu4e' is great, but viewing of html emails is suboptimal.  This packages
;; enables the user to choose how to view emails.  It's main use case is to view
;; emails using an xwidgets window, but the user provided viewing methods are
;; also supported.
;;
;; Also provides methods for user defined viewing methods to access content
;; extracted from an email, e.g., urls or attachments.  This makes it easier to
;; build new views.


;;; Code:
;;TODO also wrap mu4e text email viewing to get the customizable behaviour and reduction of window messing
(require 'seq)
(require 'mu4e)
(require 'ht)
(require 'xwidgets-reuse)
(require 'cl-lib)
(require 'thingatpt)

;; ********************************************************************************
;; Customize and defvars
(defcustom mu4e-views-view-commands
  '(;; open with standard mu4e function
    ("text" . (:viewfunc mu4e-views-text-view-message
                         :create-view-window mu4e-views-text-create-view-window
                         :is-view-window-p mu4e-views-text-is-view-window-p
                         :view-function-only-msg t
                         ))
    ;; open with xwidget
	("html" . (:viewfunc mu4e-views-xwidget-mu4e-view
                         :is-view-window-p mu4e-views-xwidget-is-view-window-p
                         ))
    ;; open with browser
	("browser" . (:viewfunc mu4e-views-view-in-browser
                            :no-view-window t))
    ;; open with gnus
    ("gnus" . (:viewfunc mu4e-views-gnus-view-message
                         :create-view-window mu4e-views-text-create-view-window
                         :is-view-window-p mu4e-views-text-is-view-window-p
                         :view-function-only-msg t)))
  "A list of commands for viewing messages in mu4e.

Currently supported are:

- \"text\" - the standard `mu4e' text email view
- \"html\" - view email as html in xwidgets
- \"browser\" - view email as html in browser using `browse-url'
- \"gnus\" - use mu4e's build-in gnus article view

A viewing command ic a cons of a string (the methods name as
shown to the user), and a plist the defines the methods
behavior. The following keys are supported:

`:viewfunc' - this is function that does the actual work of
displaying a message. The signature is `(html msg
win)' (or `(msg)' if `:view-function-only-msg' is t) where `html'
is the name of a file storing the message as html, `msg' is a
mu4e message plist (see relevant `mu4e' code, and `win' is a
window in which the message should be displayed in.
`:view-function-only-msg' - if t, then the view function does
only take a single argument `msg' which is a mu4e message
plist. In this case `mu4e-views' will not write the message to an
html file.  `:create-view-window-function' - if called, this
function should create the mu4e message viewing window.
`:is-view-window-p' - if it is currently shown return the viewing
window, otherwise return nil.  `:no-view-window' - if t, then the
viewing method does not use a separate viewing window, e.g., it
may be using an external program like a browser to show the
method. In this case also `:is-view-window-p' does not have to be
provided"
  :group 'mu4e-views
  :type 'alist)

(defcustom mu4e-views-respect-mu4e-view-use-gnus
  nil
  "If t, then repect `mu4e-view-use-gnus' over the mu4e-views viewing method.
That is, if `mu4e-view-use-gnus' is t, then always use viewing method \"gnus\"."
  :group 'mu4e-views
  :type 'boolean)

(defcustom mu4e-views-default-view-method
  (cdr (assoc "text" mu4e-views-view-commands))
  "Default method to use for viewing emails in mu4e."
  :group 'mu4e-views
  :type 'plist)

(defcustom mu4e-views-inject-email-information-into-html
  t
  "Show email headers (e.g., subject) in the html view.

If t then `mu4e-views' will inject email message headers information into the
email's html file for the email.  This is useful for viewing emails in
browsers and xwidgets."
  :group 'mu4e-views
  :type 'boolean)

(defcustom mu4e-views-auto-view-selected-message
  t
  "If t, then selecting a message in headers view (moving) automatically shows that message in the view window if it is open."
  :group 'mu4e-views
  :type 'boolean)

(defcustom mu4e-views-next-previous-message-behaviour
  'always-switch-to-headers
  "Behavior when moving to the next / previous message in the mu4e-headers view.

Default (`always-switch-to-headers') is to stay in the headers views.  Other
options are staying in the current view (`stick-to-current-window') or always
moving to the `mu4e-views' window (`always-switch-to-view')."
  :group 'mu4e-views
  :type '(radio (const :tag
                       "Always switch to mu4e-headers window which shows the list of emails"
                       always-switch-to-headers)
                (const :tag
                       "Always switch to mu4e-views view window which shows the current email"
                       always-switch-to-view)
                (const :tag
                       "Always stay in the current window"
                       stick-to-current-window)))

(defcustom mu4e-views-mu4e-html-email-header-style
  "<style type=\"text/css\">
.mu4e-mu4e-views-mail-headers { font-family: Courier New; font-size:10pt; border: solid 2px;  padding: 2px; background-color: #EEEEEE; }
.mu4e-mu4e-views-header-row { display:block; padding: 1px; }
.mu4e-mu4e-views-mail-header { font-family: Courier New; font-size:10pt; display: inline-block; font-weight: normal; color: #155327; background-color: #ECFFEC; border: 1px solid; border-color: #155327; padding: 1px;}
.mu4e-mu4e-views-header-content { font-family: Courier New; font-size:10pt; display: inline-block; font-weight: normal; color: black; padding-right: 6px; }
.mu4e-mu4e-views-email { font-family: Courier New; font-size:10pt; display: inline-block; padding-right: 8px; }
.mu4e-mu4e-views-attachment { font-family: Courier New; font-size:10pt; display: inline-block; padding-right: 8px; }
</style>"
  "CSS style for displaying email header information in a mu4e-views email view."
  :group 'mu4e-views
  :type 'string)

(defcustom mu4e-views-completion-method
  'default
  "The completion framework to use when letting choosing an option from a list.

The default (`default') is to just use completing read.  Other
supported options are `ivy', `helm', and `ido'."
  :group 'mu4e-views
  :type '(radio (const :tag "Use completing read." default)
                (const :tag "Use ivy." ivy)
                (const :tag "Use helm." helm)
                (const :tag "Use ido." ido)
                (function :tag "Custom function")))

(defcustom mu4e-views-mu4e-email-headers-as-html-function
  #'mu4e-views-mu4e-email-headers-as-html
  "This function is used to create html code from an mu4e message.  The function should take a single argument MSG.  If you want to provide your custom implementation, then have a look at the implementation of `mu4e-views-mu4e-email-headers-as-html'."
  :group 'mu4e-views
  :type 'function)

(defvar mu4e-views--mu4e-select-view-msg-method-history
  nil
  "Store completion history for `mu4e-views-mu4e-select-view-msg-method'.")

(defvar mu4e-views--current-viewing-method
  mu4e-views-default-view-method
  "Records which method for viewing email in mu4e is currently active.")

(defvar mu4e-views--view-window
  nil
  "Caches the view window.")

(defvar mu4e-views--current-mu4e-message
  nil
  "Store the `mu4e' message object for the message shown in `mu4e-views' window.

This enables us to provide `mu4e' functionality in a `mu4e-views'
view such as opening or storing attachments which need this
object.")

(defvar mu4e-views--header-selected
  t
  "On moving to another email, store whether we are in the headers window.")

(defvar mu4e-views--called-from-view
  nil
  "Set if we are called from the view window.")

(defvar mu4e-views--debug
  nil
  "If true than show a lot of log output for debugging.")

;; ********************************************************************************
;; FUNCTIONS

;; ********************************************************************************
;; helper function for debug logging
(defun mu4e-views-debug-log (format-string &rest args)
  "Use message with FORMAT-STRING and ARGS, but only when mu4e-views--debug is true."
  (when mu4e-views--debug
    (message format-string args)))

;; ********************************************************************************
;; helper functions for advising
(defun mu4e-views-advice-unadvice (sym)
  "Remove all advices from symbol SYM."
  (interactive "aFunction symbol: ")
  (advice-mapc (lambda (advice _props) (advice-remove sym advice)) sym))

(defun mu4e-views-advice-add-if-def (f type theadvice)
  "Add advice THEADVICE as type TYPE to function F.

Only do this if the function to be advised (F) and the advising
function (THEADVICE) both exists."
  (when (and (fboundp f)  (fboundp theadvice))
    (advice-add f type theadvice)))

(defun mu4e-views-advice-remove-if-def (f theadvice)
  "Remove advice THEADVICE from function F.

Only do this if the function to be advised (F) and the advising
function (THEADVICE) both exists."
  (when (and (fboundp f)  (fboundp theadvice))
    (advice-remove f theadvice)))

;; ********************************************************************************
;; wrapper for completing read frameworks (adapted from projectile:
;; https://github.com/bbatsov/projectile/)
(cl-defun mu4e-views-completing-read (prompt
                                      choices
                                      &key initial-input
                                      action
                                      history
                                      sort
                                      caller
                                      require-match)
  "Present a PROMPT with CHOICES.

Optionally, provide INITIAL-INPUT and an ACTION to execute with
the chosen option.  If the completion framework supports it and
HISTORY is not nil, then store completion history in HISTORY.  If
the framework supports it and SORT is t, then sort CHOICES.  If
CALLER is provided and the framework supports it, provide CALLER
as a caller.  Otherwise, provide `mu4e-views-completing-read' as
a caller.  If REQUIRE-MATCH is provided, then only matching
inputs can be selected."
  (let (res)
    (setq res
          (cond
           ((eq mu4e-views-completion-method 'ido)
            (ido-completing-read prompt
                                 choices
                                 nil
                                 require-match
                                 initial-input
                                 history))
           ((eq mu4e-views-completion-method 'default)
            (completing-read prompt
                             choices
                             nil
                             require-match
                             initial-input
                             history))
           ((eq mu4e-views-completion-method 'helm)
            (if (and (fboundp 'helm)
                     (fboundp 'helm-make-source))
                (helm :sources
                      (helm-make-source "mu4e-views" 'helm-source-sync
                        :candidates choices
                        :must-match require-match
                        :action (if action
                                    (prog1 action
                                      (setq action nil))
                                  #'identity))
                      :prompt prompt
                      :input initial-input
                      :history history
                      :buffer "*helm-mu4e-views*")
              (user-error "Please install helm from \
https://github.com/emacs-helm/helm")))
           ((eq mu4e-views-completion-method 'ivy)
            (if (fboundp 'ivy-read)
                (ivy-read prompt choices
                          :initial-input initial-input
                          :action (prog1 action
                                    (setq action nil))
                          :caller (or caller 'mu4e-views-completing-read)
                          :history history
                          :require-match require-match
                          :sort sort)
              (user-error "Please install ivy from \
https://github.com/abo-abo/swiper")))
           (t (funcall mu4e-views-completion-method prompt choices))))
    (if action
        (funcall action res)
      res)))

; ********************************************************************************
; Functions to create and manage view windows
;;;###autoload
(defun mu4e-views-mu4e-use-view-msg-method (method)
  "Apply METHOD for viewing emails in mu4e-headers view."
  (let
	  ((cmd (cdr (assoc
                  ; when user asked to respect mu4e-view-use-gnus and this setting
                  ; is on then use gnus irrespective of selection
                  (if (and mu4e-views-respect-mu4e-view-use-gnus mu4e-view-use-gnus)
                      "gnus"
                    method)
                  mu4e-views-view-commands)))
	   (oldmethod mu4e-views--current-viewing-method))
	; do not update anything if the method is the same
	(unless (eq cmd oldmethod)
	  (setq mu4e-views--current-viewing-method cmd)
      (mu4e-views-advice-mu4e))))

;; ********************************************************************************
;; VIEWING METHOD: html
;; functions for viewing a mu4e message in xwidgets
(defun mu4e-views-xwidget-mu4e-view (html msg win)
  "View message MSG with HTML content in xwidget using window WIN."
  (interactive)
  (ignore msg)
  (unless (fboundp 'xwidget-webkit-browse-url)
	(mu4e-error "No xwidget support available"))
  ;; select window
  (select-window win)
  ;; show message
  (xwidgets-reuse-xwidget-reuse-browse-url
   (concat "file://" html)
   'mu4e-views-view-actions-mode))

(defun mu4e-views-xwidget-is-view-window-p (win)
  "Return t if WIN is the xwidget view window."
  (let ((buf (window-buffer win)))
    (with-current-buffer buf
      (eq major-mode 'xwidget-webkit-mode))))

;; ********************************************************************************
;; VIEWING METHOD: html

; keep byte compiler quiet. This is function is dynamically defined by mu4e based on the selected viewing method.
(declare-function 'mu4e-view-mode "mu4e-view" nil)

(defun mu4e-views-text-view-message (msg win)
  "Copy of most of the cost of `mu4e~view-internal' to be used when using this viewing method from `mu4e-views'.  Takes MSG plist and window WIN as input."
  (let* ((mu4e-ver (version-to-list mu4e-mu-version))
         (embedded ;; is it as an embedded msg (ie. message/rfc822 att)?
          (when (gethash (mu4e-message-field msg :path)
                         mu4e~path-parent-docid-map) t))
         (buf (if embedded
                  (mu4e~view-embedded-winbuf)
                (get-buffer-create mu4e~view-buffer-name)))
         (previouswin (selected-window)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (if (version-list-<= '(1 5) mu4e-ver)
            (progn
              (mu4e-views-debug-log "IN TEXT VIEW 1.5 selected message is %s" msg)
              (erase-buffer)
              (mu4e~delete-all-overlays)
              (insert (mu4e-view-message-text msg))
              (goto-char (point-min))
              (mu4e~fontify-cited)
              (mu4e~fontify-signature)
              (mu4e~view-make-urls-clickable)
              (mu4e~view-show-images-maybe msg)
              (when (not embedded) (setq mu4e~view-message msg))
              (mu4e-view-mode)
              (when embedded (local-set-key "q" 'kill-buffer-and-window)))
          (mu4e-views-debug-log "IN TEXT VIEW < 1.5 selected message is %s" msg)
          (when (or embedded (not (mu4e~view-mark-as-read-maybe msg)))
            (erase-buffer)
            (mu4e~delete-all-overlays)
            (insert (mu4e-view-message-text msg))
            (goto-char (point-min))
            (mu4e~fontify-cited)
            (mu4e~fontify-signature)
            (mu4e~view-make-urls-clickable)
            (mu4e~view-show-images-maybe msg)
            (when (not embedded) (setq mu4e~view-message msg))
            (mu4e-view-mode)
            (when embedded (local-set-key "q" 'kill-buffer-and-window))))
          (select-window win)
          (switch-to-buffer buf t t)
          (select-window previouswin)))))

(defun mu4e-views-text-create-view-window (window)
  "Create the mu4e-view window for the `text' method in WINDOW."
  (select-window window)
  (unless (buffer-live-p mu4e~headers-loading-buf)
    (setq mu4e~headers-loading-buf (get-buffer-create " *mu4e-loading*"))
    (with-current-buffer mu4e~headers-loading-buf
      (mu4e-loading-mode))))

(defun mu4e-views-text-is-view-window-p (window)
  "Check whether WINDOW is the mu4e-view window for the `text' or `gnus' (standard mu4e method)."
  (let ((buf (window-buffer window)))
    (or (eq buf mu4e~headers-loading-buf)
        (eq buf (mu4e-get-view-buffer)))))

;; ********************************************************************************
;; VIEWING METHOD: browser
;; functions viewing email in a webbrowser (available as action and as a view method)
(defun mu4e-views-gnus-view-message (msg win)
  "View message MSG on window WIN using Gnus article mode."
  (require 'gnus-art)
  (let* ((mu4e-ver (version-to-list mu4e-mu-version))
         (marked-read (if (version-list-<= '(1 5) mu4e-ver)
                          nil
                        (mu4e~view-mark-as-read-maybe msg)))
         (path (mu4e-message-field msg :path))
         (inhibit-read-only t)
         ;; support signature verification
         (mm-verify-option 'known)
         (mm-decrypt-option 'known)
         (gnus-article-emulate-mime t)
         (previouswin (selected-window))
         (buf (get-buffer-create mu4e~view-buffer-name))
         (gnus-buttonized-mime-types (append (list "multipart/signed"
                                                   "multipart/encrypted")
                                             gnus-buttonized-mime-types)))
    (select-window win)
    (switch-to-buffer buf t t)
    (erase-buffer)
    (unless marked-read
      ;; when we're being marked as read, no need to start rendering
      ;; the messages; just the minimal so (update... ) can find us.
      (insert-file-contents-literally path)
      (unless (message-fetch-field "Content-Type" t)
        ;; For example, for messages in `mu4e-drafts-folder'
        (let ((coding (or (default-value 'buffer-file-coding-system)
                          'prefer-utf-8)))
          (recode-region (point-min) (point-max) coding 'no-conversion)))
      (setq
       gnus-summary-buffer (get-buffer-create " *appease-gnus*")
       gnus-original-article-buffer (current-buffer))
      (run-hooks 'gnus-article-decode-hook)
      (let ((mu4e~view-rendering t) ; customize gnus in mu4e
            (max-specpdl-size mu4e-view-max-specpdl-size)
            (gnus-blocked-images ".") ;; don't load external images.
            ;; Possibly add headers (before "Attachments")
            (gnus-display-mime-function (mu4e~view-gnus-display-mime msg))
            (gnus-icalendar-additional-identities (mu4e-personal-addresses)))
        (gnus-article-prepare-display))
      (setq mu4e~gnus-article-mime-handles gnus-article-mime-handles)
      (setq mu4e~view-message msg)
      (mu4e-view-mode)
      (setq gnus-article-decoded-p gnus-article-decode-hook)
      (set-buffer-modified-p nil)
      (add-hook 'kill-buffer-hook
                (lambda() ;; cleanup the mm-* buffers that the view spawns
                  (when mu4e~gnus-article-mime-handles
                    (mm-destroy-parts mu4e~gnus-article-mime-handles)
                    (setq mu4e~gnus-article-mime-handles nil))))
      (read-only-mode))
    (select-window previouswin)))

(defun mu4e-views-mu4e-view-in-browser-action (msg)
  "Open email MSG in browser using `browse-url'."
  (interactive)
  (browse-url (concat "file://"
                      (mu4e-views-mu4e~write-body-and-headers-to-html msg))))

(defun mu4e-views-view-in-browser (html msg)
  "Open email `MSG` with content HTML using `browse-url'."
  (ignore msg)
  (browse-url (concat "file://" html)))

;; access with `aV' from headers view
(add-to-list 'mu4e-headers-actions
             '("ViewInBrowser" . mu4e-views-mu4e-view-in-browser-action) t)

;; ********************************************************************************
;; functions for writing a message to HTML and making it accessible to custom views
(defun mu4e-views-mu4e-email-headers-as-html (msg)
  "Create formatted html for headers like subject and from/to of email MSG."
  (interactive)
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by
   mu4e-views--current-mu4e-message)
  (cl-flet ((wrap-row (header content id)
                      (concat "<div class=\"mu4e-mu4e-views-header-row\">"
                              "<div class=\"mu4e-mu4e-views-mail-header\">"
                              header "</div>: <div class=\"mu4e-mu4e-views-header-content\" id=\""
                              id "\">"
                              content "</div></div>"))
			(wrap-row-multi (headers)
                            (concat "<div class=\"mu4e-mu4e-views-header-row\">"
									(mapconcat
                                     (lambda (l) (let ((header (nth 0 l))
												       (content (nth 1 l))
												       (id (nth 2 l)))
												   (concat "<div class=\"mu4e-mu4e-views-mail-header\">"
													       header "</div>: <div class=\"mu4e-mu4e-views-header-content\" id=\""
                                                           id "\">"
													       content "</div>")))
									 headers "")
									"</div>")))
	(with-temp-buffer
	  (insert (concat "<div class=\"mu4e-mu4e-views-mail-headers\">"))
	  (insert (wrap-row "from"
                        (mapconcat
                         (lambda (mail)
                           (concat "<div class=\"mu4e-mu4e-views-email\">"
                                   (car mail) " ("
                                   (cdr mail) ")</div>"))
                         (mu4e-message-field msg :from) "")
                        "mu4e-from"))
	  (insert (wrap-row "to" (mapconcat
                              (lambda (mail)
                                (concat "<div class=\"mu4e-mu4e-views-email\">"
                                        (car mail) " ("
                                        (cdr mail) ")</div>"))
                              (mu4e-message-field msg :to) "")
                        "mu4e-to"))
	  (when (mu4e-message-field msg :cc)
		(insert (wrap-row "cc" (mapconcat
                                (lambda (mail)
                                  (concat "<div class=\"mu4e-mu4e-views-email\">"
                                          (car mail) " ("
                                          (cdr mail) ")</div>"))
                                (mu4e-message-field msg :cc) "")
                          "mu4e-cc")))
	  (when (mu4e-message-field msg :bcc)
		(insert (wrap-row "bcc" (mapconcat
                                 (lambda (mail)
                                   (concat "<div class=\"mu4e-mu4e-views-email\">"
                                           (car mail) " ("
                                           (cdr mail) ")</div>"))
                                 (mu4e-message-field msg :bcc) "")
                          "mu4e-bcc")))
	  (insert (wrap-row "subject" (mu4e-message-field msg :subject) "mu4e-subject"))
	  (insert (wrap-row-multi (list
							   (list "date"
                                     (format-time-string mu4e-view-date-format
											             (mu4e-message-field msg :date))
                                     "mu4e-date")
							   (list "size"
                                     (mu4e-display-size (mu4e-message-field msg :size))
                                     "mu4e-size")
							   (list "maildir"
                                     (mu4e-message-field msg :maildir)
                                     "mu4e-maildir"))))
	  (let ((attachments (mapcar
                          (lambda (k) (mu4e~view-get-attach mu4e-views--current-mu4e-message k))
                          (ht-keys mu4e~view-attach-map))))
		(when attachments
		  (insert (wrap-row "attachments" (mapconcat
                                           (lambda (att)
                                             (concat "<div class=\"mu4e-mu4e-views-attachment\">"
                                                     (lax-plist-get att :name) " ("
                                                     (mu4e-display-size (lax-plist-get att :size)) ")</div>"))
                                           attachments "")
                            "mu4e-attachments"))))
	  (insert "</div>")
	  (buffer-string))))

(defun mu4e-views-set-auto-mode-dummy (&optional keep-mode-if-same)
  "Do nothing function to replace `set-auto-mode' when just writing to a file.
Ignore `KEEP-MODE-IF-SAME'."
  (ignore keep-mode-if-same))

(defun mu4e-views-vc-refresh-state-dummy ()
  "Do nothing function to replace `vc-refresh-state' when just writing to a file.")

(defun mu4e-views-vc-before-save-dummy ()
  "Do nothing function to replace `vc-before-save' when just writing to a file.")

(defun mu4e-views-vc-after-save-dummy ()
  "Do nothing function to replace `vc-before-after' when just writing to a file.")

(defun mu4e-views-mu4e~write-body-and-headers-to-html (msg)
  "Write the body (either html or text) and headers of MSG to a temporary file.

Return the file's name.  Text messages are converted into html."
  (let* ((html (mu4e-message-field msg :body-html))
		 (txt (mu4e-message-field msg :body-txt))
		 (tmpfile (mu4e-make-temp-file "html"))
		 (attachments (cl-remove-if (lambda (part)
								      (or (null (plist-get part :attachment))
								          (null (plist-get part :cid))))
								    (mu4e-message-field msg :parts))))
	(unless (or html txt)
	  (mu4e-error "No body part for this message"))
	;; remove hooks and advices that are not needed for writing constructed content to a file, but slow us down
	(mu4e-views-advice-remove-if-def #'set-visited-file-name 'doom-modeline-update-buffer-file-name)
	(mu4e-views-advice-remove-if-def #'set-visited-file-name 'lsp--on-set-visited-file-name)
	(mu4e-views-advice-remove-if-def #'basic-save-buffer 'polymode-with-current-base-buffer)
	(mu4e-views-advice-remove-if-def #'vc-refresh-state 'doom-modeline-update-vcs-text)
	(mu4e-views-advice-remove-if-def #'vc-refresh-state 'doom-modeline-update-vcs-icon)
	(mu4e-views-advice-remove-if-def #'rename-buffer 'doom-modeline-update-buffer-file-name)
	(mu4e-views-advice-add-if-def #'set-auto-mode :override #'mu4e-views-set-auto-mode-dummy)
	(mu4e-views-advice-add-if-def #'vc-refresh-state :override #'mu4e-views-vc-refresh-state-dummy)
	(mu4e-views-advice-add-if-def #'vc-before-save :override #'mu4e-views-vc-before-save-dummy)
	(mu4e-views-advice-add-if-def #'vc-after-save :override #'mu4e-views-vc-after-save-dummy)
	(let ((cache-before-save-hook before-save-hook)
		  (cache-after-save-hook after-save-hook))
	  (with-temp-buffer
		(setq before-save-hook nil)
		(setq after-save-hook nil)
		(insert (concat "<head><meta charset=\"UTF-8\">" mu4e-views-mu4e-html-email-header-style  "</head>\n"))
        (when mu4e-views-inject-email-information-into-html
          (insert (funcall mu4e-views-mu4e-email-headers-as-html-function msg)))
		(insert (or html (concat "<div style=\"white-space: pre-wrap;\">" txt "</div>")))
		(write-file tmpfile)
		;; rewrite attachment urls
		(mapc (lambda (attachment)
				(goto-char (point-min))
				(while (re-search-forward (format "src=\"cid:%s\""
									              (plist-get attachment :cid)) nil t)
				  (if (plist-get attachment :temp)
					  (replace-match (format "src=\"%s\""
									         (plist-get attachment :temp)))
					(replace-match (format "src=\"%s%s\"" temporary-file-directory
								           (plist-get attachment :name)))
					(let ((tmp-attachment-name
						   (format "%s%s" temporary-file-directory
							       (plist-get attachment :name))))
					  (mu4e~proc-extract 'save (mu4e-message-field msg :docid)
								         (plist-get attachment :index)
								         mu4e-decryption-policy tmp-attachment-name)
					  (mu4e-remove-file-later tmp-attachment-name)))))
			  attachments)
		(save-buffer)
		;; restore normal behaviour
		(mu4e-views-advice-add-if-def #'set-visited-file-name :after 'doom-modeline-update-buffer-file-name)
		(mu4e-views-advice-add-if-def #'set-visited-file-name :around 'lsp--on-set-visited-file-name)
		(mu4e-views-advice-add-if-def #'basic-save-buffer :around 'polymode-with-current-base-buffer)
		(mu4e-views-advice-add-if-def #'vc-refresh-state :after 'doom-modeline-update-vcs-text)
		(mu4e-views-advice-add-if-def #'vc-refresh-state :after 'doom-modeline-update-vcs-icon)
		(mu4e-views-advice-add-if-def #'rename-buffer :after 'doom-modeline-update-buffer-file-name)
		(mu4e-views-advice-remove-if-def #'set-auto-mode #'mu4e-views-set-auto-mode-dummy)
		(mu4e-views-advice-remove-if-def #'vc-refresh-state #'mu4e-views-vc-refresh-state-dummy)
		(mu4e-views-advice-remove-if-def #'vc-before-save #'mu4e-views-vc-before-save-dummy)
		(mu4e-views-advice-remove-if-def #'vc-after-save #'mu4e-views-vc-after-save-dummy)
		(setq before-save-hook cache-before-save-hook)
		(setq after-save-hook cache-after-save-hook)
		(lax-plist-put msg :html-file tmpfile)
		tmpfile))))

;; ********************************************************************************
;; functions that replace mu4e functions and additional helper functions for
;; handling the mu4e header view windows
;;TODO check that the window size ratios are ok?
(defun mu4e-views-mu4e-header-and-view-windows-p ()
  "Check whether we are already showing the `mu4e-headers' and our view windows."
  (let ((have-header nil)
        (have-view nil)
        (other-buf nil)
        (is-view-p (plist-get mu4e-views--current-viewing-method :is-view-window-p))
        (header-buffer (mu4e-get-headers-buffer)))
    (mu4e-views-debug-log "TEST FUNCTION %s " is-view-p)
    (if (eq (length (window-list)) 2)
        ;; we have two window check whether they are the correct ones
        (progn
          (cl-loop for w in (window-list) do
                   (let* ((buf (window-buffer w)))
                     (when (eq buf header-buffer)
                       (setq have-header t))
                     (when (funcall is-view-p w)
                       (setq have-view t))
                     (unless (or (eq buf header-buffer) (funcall is-view-p w))
                       (setq other-buf t))))
          (mu4e-views-debug-log "HAVE HEADER: %s, HAVE VIEW: %s HAVE OTHER: %s\nwindows are %s" have-header have-view other-buf (window-list))
          (and have-header have-view (not other-buf)))
      ;; return nil if window list has not exactly 2 windows
      nil)))

(defun mu4e-views-mu4e-view-window-p (&optional window)
  "Return t if WINDOW is the mu4e-views message window.  If WINDOW is omitted, then check for the current window.  Use `:is-view-window-p' of the current viewing method."
  (let ((is-view-p (plist-get mu4e-views--current-viewing-method :is-view-window-p))
        (thewindow (or window (selected-window))))
    (mu4e-views-debug-log "selected win: %s" thewindow)
    (if (mu4e-views-mu4e-header-and-view-windows-p)
        (funcall is-view-p thewindow)
      nil)))

(defun mu4e-views-get-view-win (&optional noerror)
  "Return window to use for `mu4e-views' viewing of emails.

If optional argument NOERROR is t then do not throw an error if the window does not exist."
  (let (win
        (view-window-p (plist-get mu4e-views--current-viewing-method :is-view-window-p)))
    (cl-loop for w in (window-list) do
             (when (and (funcall view-window-p w) (window-valid-p w))
               (setq win w)))
    (if win
        win
      (unless noerror (error "View window not found in %s" (window-list))))))

(defun mu4e-views-headers-redraw-get-view-window ()
  "Unless we already have the correct window layout, rebuild it.

For that we close all windows, redraw the headers buffer based on
the value of `mu4e-split-view', and return a window for the
message view (if the current viewing method needs a window)."
  ;; if single is used then the headers buffer needs to be replaced
  (mu4e-views-debug-log "IN REDRAW!")
  (let ((create-view-fun (plist-get mu4e-views--current-viewing-method :create-view-window)))
    ;; single window
    (when (eq mu4e-split-view 'single-window)
      (mu4e-views-debug-log "SINGLE PANE")
      (let* ((win (selected-window))
             (viewwin (mu4e-views-get-view-win t))
             (usewin (if (and viewwin (window-live-p viewwin)) viewwin win)))
        (setq mu4e-views--view-window usewin)
        (setq mu4e~headers-view-win usewin)
        (when create-view-fun
          (mu4e-views-debug-log "CALL CREATE VIEW FUNCTION: %s" create-view-fun)
          (funcall create-view-fun newwin))
        usewin))
    ;; if we have already the right setup, then just return the mu4e-views window
    (mu4e-views-debug-log "MULTIPLE PANES")
    (if (mu4e-views-mu4e-header-and-view-windows-p)
        (progn
          (mu4e-views-debug-log "REUSE EXISTING WINDOW %s" (mu4e-views-get-view-win))
          (mu4e-views-get-view-win))
      ;; create the window
      (unless (buffer-live-p (mu4e-get-headers-buffer))
        (mu4e-error "No headers buffer available"))
      (switch-to-buffer (mu4e-get-headers-buffer))
      (delete-other-windows)
      ;; kill the existing view buffer
      ;; (when (buffer-live-p (mu4e-get-view-buffer))
      ;;   (kill-buffer (mu4e-get-view-buffer)))
      ;; get a new view window
      (let* ((new-win-func
              (cond
               ((eq mu4e-split-view 'horizontal) ;; split horizontally
                '(split-window-vertically mu4e-headers-visible-lines))
               ((eq mu4e-split-view 'vertical) ;; split vertically
                '(split-window-horizontally mu4e-headers-visible-columns))))
             (newwin (with-demoted-errors "Unable to split window: %S"
                       (eval new-win-func))))
        (when newwin
          (mu4e-views-debug-log "WINDOW TO USE FOR VIEWING: %s\nall windows: %s" newwin (window-list))
          (setq mu4e-views--view-window newwin)
          (setq mu4e~headers-view-win newwin)
          ;; if viewing method provdes a setup method for the viewing window then call it
          (when create-view-fun
            (mu4e-views-debug-log "CALL CREATE VIEW FUNCTION: %s" create-view-fun)
            (funcall create-view-fun newwin))
          newwin)))))

(defun mu4e-views-headers-redraw-get-view-buffer ()
  "Return the view buffer, redrawing the view window if we do not have the correct layout."
  (window-buffer (mu4e-views-headers-redraw-get-view-window)))

(defun mu4e-views-select-other-view ()
  "When the headers view is selected, then select the message view (if that has a live window), and vice versa."
  (interactive)
  (let* ((other-buf
          (cond
           ((eq major-mode 'mu4e-headers-mode)
            (window-buffer (mu4e-views-get-view-win t)))
           ((mu4e-views-mu4e-view-window-p)
            (mu4e-get-headers-buffer))))
         (other-win (and other-buf (get-buffer-window other-buf))))
    (if (window-live-p other-win)
        (select-window other-win)
      (mu4e-message "No window to switch to"))))

(defun mu4e-views-mu4e-headers-view-message ()
  "View message at point.

If there's an existing window for the view, re-use that one.  If
not, create a new one, depending on the value of
`mu4e-split-view': if it's a symbol `horizontal' or `vertical',
split the window accordingly; if it is nil, replace the current
window."
  (interactive)
  (unless (eq major-mode 'mu4e-headers-mode)
    (mu4e-error "Must be in mu4e-headers-mode (%S)" major-mode))
  (let* ((msg (mu4e-message-at-point))
         (docid (or (mu4e-message-field msg :docid)
                    (mu4e-warn "No message at point")))
         (decrypt (mu4e~decrypt-p msg))
         (verify  (not mu4e-view-use-gnus))
         (mu4e-ver (version-to-list mu4e-mu-version)))
      (mu4e-views-debug-log "IN HEADERS VIEW selected message is %s" msg)
      (cond
       ((version-list-<= mu4e-ver '(1 3 9)) (mu4e~proc-view docid mu4e-view-show-images decrypt))
       ((version-list-< mu4e-ver '(0 9 9)) (mu4e~proc-view docid mu4e-view-show-images))
       (t (mu4e~proc-view docid mu4e-view-show-images decrypt verify)))))

(defun mu4e-views-view-msg-internal (msg)
  "Replacement for `mu4e-view-msg-internal'.

Takes `mu4e' message MSG as input."
  (mu4e-views-debug-log "IN INTERNAL!")
  (let* ((viewfunc (plist-get mu4e-views--current-viewing-method :viewfunc))
         (only-msg (plist-get mu4e-views--current-viewing-method :view-function-only-msg))
         (no-window (plist-get mu4e-views--current-viewing-method :no-view-window))
         (html (mu4e-message-field msg :body-html))
	     (txt (mu4e-message-field msg :body-txt))
         ;; (currentwin (selected-window))
         htmlfile)
    (mu4e-views-debug-log "use view function: %s" viewfunc)
    (unless only-msg
      ;; if there is a no content still show message for its metadata (e.g., only attachments)
	  (unless (or html txt)
	    (mu4e-views-debug-log "No body part for this message")
        (setq txt "")))
	(setq mu4e-views--current-mu4e-message msg)
    (unless only-msg
	  (setq htmlfile (mu4e-views-mu4e~write-body-and-headers-to-html msg)))
    (if only-msg
        ;; only pass msg
        (funcall viewfunc msg (mu4e-views-headers-redraw-get-view-window))
      (if no-window
          ;; method does not use a window, do nothing
          (funcall viewfunc htmlfile msg)
        ;; method needs a window, reuse or create a new one, then switch to the
        ;; headers or view window based on
        ;; `mu4e-views-next-previous-message-behaviour'.
        (funcall viewfunc htmlfile msg (mu4e-views-headers-redraw-get-view-window))
        ;;(mu4e-views-headers-redraw-get-view-window)
        ))
    (mu4e-views-switch-to-right-window)))

(defun mu4e-views-switch-to-right-window ()
  "Switch to a different window based on `mu4e-views-next-previous-message-behaviour'."
  (if (plist-get mu4e-views--current-viewing-method :no-view-window)
      (mu4e-views-debug-log "method without view window, do not attempt to switch.")
    (mu4e-views-debug-log "behavior is %s currently on header? %s"
             mu4e-views-next-previous-message-behaviour
             mu4e-views--header-selected)
    (cl-case mu4e-views-next-previous-message-behaviour
      (stick-to-current-window (if mu4e-views--header-selected
                                   (select-window
                                    (get-buffer-window (mu4e-get-headers-buffer)))
                                 (select-window
                                  (mu4e-views-get-view-win))))
      (always-switch-to-view (select-window
                              (mu4e-views-get-view-win)))
      (always-switch-to-headers (mu4e~headers-select-window)))))

;; ********************************************************************************
;; helpers for mu4e-headers view.

;;;###autoload
(defun mu4e-views-mu4e-headers-windows-only ()
  "Show only the headers window of mu4e."
  (interactive)
  ;; delete other windows because otherwise mu4e will mess up and select the
  ;; header window for replacement.
  (switch-to-buffer (mu4e-get-headers-buffer))
  (delete-other-windows))

;;;###autoload
(defun mu4e-views-cursor-msg-view-window-down ()
  "Scroll message view down if we are viewing the message using xwidget-webkit."
  (interactive)
  (let* ((wind (other-window-for-scrolling))
		 (mode (with-selected-window wind major-mode)))
	(if (eq mode 'xwidget-webkit-mode)
		(with-selected-window wind
          (if (>= emacs-major-version 27)
		      (xwidget-webkit-scroll-up 100)
            (xwidget-webkit-scroll-up)))
	  (scroll-other-window 2))))

;;;###autoload
(defun mu4e-views-cursor-msg-view-window-up ()
  "Scroll message view up if we are viewing the message using xwidget-webkit."
  (interactive)
  (let* ((wind (other-window-for-scrolling))
		 (mode (with-selected-window wind major-mode)))
	(if (eq mode 'xwidget-webkit-mode)
		(with-selected-window wind
          (if (>= emacs-major-version 27)
		      (xwidget-webkit-scroll-down 100)
            (xwidget-webkit-scroll-down)))
	  (scroll-other-window -2))))

;;;###autoload
(defun mu4e-views-mu4e-headers-next (&optional n)
  "Move to next message in headers view.

If a xwidget message view is open then use that to show the
message.  With prefix argument move N steps instead."
  (interactive "P")
  (let ((step (or n 1)))
	(mu4e-views-mu4e-headers-move-wrapper step)))

;;;###autoload
(defun mu4e-views-mu4e-headers-prev (&optional n)
  "Move to previous message in headers view.

If a xwidget message view is open then use that to show the
message.  With prefix argument move N steps backwards instead."
  (interactive "P")
  (let ((step (* -1 (or n 1))))
	(mu4e-views-mu4e-headers-move-wrapper step)))

;;;###autoload
(defun mu4e-views-mu4e-headers-move (lines)
  "Move point LINES lines.
Forward (if LINES is positive) or backward (if LINES is negative).
If this succeeds, return the new docid.  Otherwise, return nil."
  (unless (eq major-mode 'mu4e-headers-mode)
    (mu4e-error "Must be in mu4e-headers-mode (%S)" major-mode))
  (let* ((_succeeded (zerop (forward-line lines)))
         (docid (mu4e~headers-docid-at-point)))
    (mu4e-views-debug-log "move to docid: %s" docid)
    ;; move point, even if this function is called when this window is not
    ;; visible
    (when docid
      ;; update all windows showing the headers buffer
      (walk-windows
       (lambda (win)
         (when (eq (window-buffer win) (mu4e-get-headers-buffer))
           (set-window-point win (point))))
       nil t)
      (if (eq mu4e-split-view 'single-window)
          (when (eq (window-buffer) (mu4e-get-view-buffer))
            (mu4e-headers-view-message))
        ;; update message view if it was already showing
        (when (and mu4e-split-view (mu4e-views-mu4e-header-and-view-windows-p) mu4e-views-auto-view-selected-message)
          (mu4e-headers-view-message)))
      ;; attempt to highlight the new line, display the message
      (mu4e~headers-highlight docid)
      docid)))

;;;###autoload
(defun mu4e-views-mu4e-headers-move-wrapper (n)
  "Move by N steps in the headers view.

Negative numbers move backwards.  Record the window that we started from to
be able to respect `mu4e-views-next-previous-message-behaviour'."
  (interactive)
  (setq mu4e-views--header-selected (not (mu4e-views-mu4e-view-window-p (selected-window))))
  (mu4e-views-debug-log "header was selected? %s" mu4e-views--header-selected)
  (with-current-buffer (mu4e-get-headers-buffer)
    (mu4e-views-mu4e-headers-move n)))

;; ********************************************************************************
;; helper function for accessing parts of an email. These can be bound by custom
;; mu4e-view modes.  These functions wrap `mu4e' functions and pass on our
;; saved message.

;;;###autoload
(defun mu4e-views-mu4e-extract-urls-from-msg (msg)
  "Prepare mu4e message data structure for MSG.
This data structure is used to support commands like browsing
urls in `mu4e-views' xwidget message view."
  (interactive)
  (unless (plist-member msg :body-urls)
    (let ((num 0)
          (urls nil))
      (with-temp-buffer
        (setq mu4e~view-link-map ;; buffer local
              (make-hash-table :size 32 :weakness nil))
        (insert-file-contents (lax-plist-get msg :html-file))
        (goto-char (point-min))
        (while (re-search-forward mu4e~view-beginning-of-url-regexp nil t)
          (let ((bounds (thing-at-point-bounds-of-url-at-point)))
            (when bounds
              (let* ((url (thing-at-point-url-at-point)))
                (puthash (cl-incf num) url mu4e~view-link-map)
                (push url urls))))))
      (lax-plist-put msg :body-urls urls))))

;;;###autoload
(defun mu4e-views-mu4e-select-url-from-message ()
  "Select a url from a mu4e message."
  (interactive)
  (mu4e-views-mu4e-extract-urls-from-msg mu4e-views--current-mu4e-message)
  (mu4e-views-completing-read "Select url: " ;; prompt
			                  (lax-plist-get
                               mu4e-views--current-mu4e-message
                               :body-urls)
			                  :action (lambda (x)
					                    (browse-url x))
			                  :sort t
			                  :require-match t
			                  :caller 'mu4e-views-mu4e-select-url-from-message))

;;;###autoload
(defun mu4e-views-mu4e-open-attachment ()
  "Select an attached from a mu4e message and open it."
  (interactive)
  (let* ((attachments (mapcar (lambda (k)
                                (list k
                                      (mu4e~view-get-attach
                                       mu4e-views--current-mu4e-message
                                       k)))
                              (ht-keys mu4e~view-attach-map)))
		 (names (mapcar
                 (lambda (x) (mu4e-message-part-field (cadr x) :name))
                 attachments))
		 (name-to-index (mapcar
                         (lambda (x) (cons (plist-get (cadr x) :name) (car x)))
                         attachments)))
	(mu4e-views-completing-read "Select url: " ;; prompt
			                    names ;; collection to complete over
			                    :action (lambda (x)
						                  (let ((index (cdr (assoc x name-to-index))))
						                    (mu4e-view-open-attachment
                                             mu4e-views--current-mu4e-message
                                             index)))
			                    :sort t
			                    :require-match t
			                    :caller 'mu4e-views-mu4e-open-attachment)))

;;;###autoload
(defun mu4e-views-mu4e-save-attachment ()
  "Select an attached from a mu4e message and save it."
  (interactive)
  (let* ((attachments (mapcar (lambda (k)
                                (list k
                                      (mu4e~view-get-attach
                                       mu4e-views--current-mu4e-message k)))
                              (ht-keys mu4e~view-attach-map)))
		 (names (mapcar
                 (lambda (x) (mu4e-message-part-field (cadr x) :name))
                 attachments))
		 (name-to-index (mapcar
                         (lambda (x) (cons (plist-get (cadr x) :name) (car x)))
                         attachments)))
	(mu4e-views-completing-read "Select attachment(s): " ;; prompt
			                    names ;; collection to complete over
			                    :action (lambda (x)
						                  (let ((index (cdr (assoc x name-to-index))))
						                    (mu4e-view-save-attachment-single
                                             mu4e-views--current-mu4e-message index)))
			                    :sort t
			                    :require-match t
			                    :caller 'mu4e-views-mu4e-save-attachment)))

;;;###autoload
(defun mu4e-views-mu4e-save-all-attachments ()
  "Save all attachments to a single directory chosen by the user."
  (interactive)
  (let* ((msg mu4e-views--current-mu4e-message)
		 (attachnums (sort (ht-keys mu4e~view-attach-map) '<))
		 (path (concat (mu4e~get-attachment-dir) "/"))
		 (attachdir (mu4e~view-request-attachments-dir path)))
	(dolist (num attachnums)
	  (let* ((att (mu4e~view-get-attach msg num))
			 (fname  (plist-get att :name))
			 (index (plist-get att :index))
			 (retry t)
			 fpath)
		(while retry
		  (setq fpath (expand-file-name (concat attachdir fname) path))
		  (setq retry
				(and (file-exists-p fpath)
					 (not (y-or-n-p
						   (mu4e-format "Overwrite '%s'?" fpath))))))
		(mu4e~proc-extract
		 'save (mu4e-message-field msg :docid)
		 index mu4e-decryption-policy fpath)))))

(defun mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by (msg)
  "Call the `mu4e' function to setup the attachments hash-map for MSG.

The function we are using is
`mu4e~view-construct-attachments-header'.  Only do this if we have
not already done this for this message."
  (unless (plist-member msg :attachment-setup)
	(mu4e~view-construct-attachments-header msg)
	(lax-plist-put msg :attachment-setup t)))

;;;###autoload
(defun mu4e-views-mu4e-view-open-attachment ()
  "Wraps the `mu4e-view-open-attachment' function.

Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by
   mu4e-views--current-mu4e-message)
  (mu4e-views-mu4e-open-attachment))

;;;###autoload
(defun mu4e-views-mu4e-view-go-to-url ()
  "Wraps the `mu4e-view-go-to-url' function.

Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-views-mu4e-select-url-from-message))

;;;###autoload
(defun mu4e-views-mu4e-view-save-url ()
  "Wraps the `mu4e-view-save-url' function.

 Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-view-save-url mu4e-views--current-mu4e-message))

;;;###autoload
(defun mu4e-views-mu4e-view-save-attachment ()
  "Wraps the `mu4e-save-attachment' function.

 Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by
   mu4e-views--current-mu4e-message)
  (mu4e-views-mu4e-save-attachment))

;;;###autoload
(defun mu4e-views-mu4e-view-save-all-attachments ()
  "Wraps function to save all attachments using `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by
   mu4e-views--current-mu4e-message)
  (mu4e-views-mu4e-save-all-attachments))

;;;###autoload
(defun mu4e-views-mu4e-view-action ()
  "Wraps the `mu4e-view-action' function.

Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-view-action mu4e-views--current-mu4e-message))

;;;###autoload
(defun mu4e-views-mu4e-view-fetch-url ()
  "Wraps the `mu4e-view-fetch-url' function.

Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-view-fetch-url mu4e-views--current-mu4e-message))

;; ********************************************************************************
;; Minor mode that bounds keys to access mu4e email actions like saving attachments.
;; create a custom keymap for mu4e-views-view-actions-mode-map
(defvar mu4e-views-view-actions-mode-map
  (let ((km (make-sparse-keymap)))
    (define-key km (kbd "q") #'mu4e-views-mu4e-headers-windows-only)
    (define-key km (kbd "n") #'mu4e-views-mu4e-headers-next)
    (define-key km (kbd "p") #'mu4e-views-mu4e-headers-prev)
    (define-key km (kbd "o") #'mu4e-views-mu4e-view-open-attachment)
    (define-key km (kbd "g") #'mu4e-views-mu4e-view-go-to-url)
    (define-key km (kbd "k") #'mu4e-views-mu4e-view-save-url)
    (define-key km (kbd "e") #'mu4e-views-mu4e-view-save-attachment)
    (define-key km (kbd "E") #'mu4e-views-mu4e-view-save-all-attachments)
    (define-key km (kbd "a") #'mu4e-views-mu4e-view-action)
    (define-key km (kbd "f") #'mu4e-views-mu4e-view-fetch-url)
    (define-key km (kbd "y") #'mu4e-views-select-other-view)
    km)
  "The keymap for `Mu4e-views-view-actions-mode'.")

;; create a minor mode mainly for custom keys
(define-minor-mode mu4e-views-view-actions-mode
  "Minor mode for setting up keys when viewing a mu4e email in a mu4e-views window."
  ;; The initial value - Set to 1 to enable by default
  :init-value nil
  ;; The indicator for the mode line.
  :lighter " M4"
  ;; The minor mode keymap
  :keymap mu4e-views-view-actions-mode-map
  ;; Make mode global rather than buffer local
  :global nil)

;; Register the minor mode with `xwidgets-reuse' so that it is automatically
;; turned of if the xwidget session is reused for a different purpose.
(xwidgets-reuse-register-minor-mode 'mu4e-views-view-actions-mode)

;; function to select how to view emails
;;;###autoload
(defun mu4e-views-mu4e-select-view-msg-method ()
  "Select the method for viewing emails in `mu4e'."
  (interactive)
  (mu4e-views-completing-read "Select method for viewing mail: " ;; prompt
                              ;; collection to complete over
			                  (mapcar (lambda (x) (car x)) mu4e-views-view-commands)
			                  :action (lambda (x)
					                    (mu4e-views-mu4e-use-view-msg-method x))
			                  :sort t
			                  :require-match t
                              :history 'mu4e-views--mu4e-select-view-msg-method-history
			                  :caller 'mu4e-views-mu4e-select-view-msg-method))

;;;###autoload
(defun mu4e-views-toggle-auto-view-selected-message ()
  "Toggle automatic viewing of message when moving around in the mu4e-headers view."
  (interactive)
  (setq mu4e-views-auto-view-selected-message
        (not mu4e-views-auto-view-selected-message)))

;;;###autoload
(defun mu4e-views-unload-function ()
  "Uninstalls the advices on mu4e functions created by mu4e-views."
  (interactive)
  (mu4e-views-advice-unadvice 'mu4e~view-internal)
  (mu4e-views-advice-unadvice 'mu4e-headers-view-message)
  (mu4e-views-advice-unadvice 'mu4e~headers-move)
  (mu4e-views-advice-unadvice 'mu4e-select-other-view)
  (mu4e-views-advice-unadvice 'mu4e-view-headers-next)
  (mu4e-views-advice-unadvice 'mu4e-view-headers-previous)
  (mu4e-views-advice-unadvice 'mu4e~view-gnus))

(defun mu4e-views-advice-mu4e ()
  "Install the advices on mu4e functions used by mu4e-views to overwrite its functionality."
  (advice-add 'mu4e~view-internal
              :override #'mu4e-views-view-msg-internal)
  (advice-add 'mu4e-headers-view-message
              :override #'mu4e-views-mu4e-headers-view-message)
  (advice-add 'mu4e~headers-move
              :override #'mu4e-views-mu4e-headers-move-wrapper)
  (advice-add 'mu4e-select-other-view
              :override #'mu4e-views-select-other-view)
  (advice-add 'mu4e-view-headers-next
              :override #'mu4e-views-mu4e-headers-next)
  (advice-add 'mu4e-view-headers-previous
              :override #'mu4e-views-mu4e-headers-prev)
  (advice-add 'mu4e~view-gnus
              :override #'mu4e-views-view-msg-internal))

(provide 'mu4e-views)
;;; mu4e-views.el ends here
