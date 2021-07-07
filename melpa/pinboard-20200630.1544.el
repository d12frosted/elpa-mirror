;;; pinboard.el --- A pinboard.in client -*- lexical-binding: t -*-
;; Copyright 2019-2020 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.3.1
;; Package-Version: 20200630.1544
;; Package-Commit: d426f9d2ebec5f907c8a89d6b38ccbcb13750d4f
;; Keywords: hypermedia, bookmarking, reading, pinboard
;; URL: https://github.com/davep/pinboard.el
;; Package-Requires: ((emacs "25.1") (cl-lib "0.5"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; pinboard.el provides an Emacs client for pinboard.in.
;;
;; To get started, visit your password settings page
;; (https://pinboard.in/settings/password) on Pinboard and get the API token
;; that's displayed there. Then edit ~/.authinfo and add a line like this:
;;
;; machine api.pinboard.in password foo:8ar8a5w188l3
;;
;; Once done, you can M-x pinboard RET and browse your pins. A number of
;; commands are available when viewing the pin list, press "?" or see the
;; "Pinboard" menu for more information.
;;
;; Commands available that aren't part of the pin list, and that you might
;; want to bind to keys, include:
;;
;; | Command                | Description                           |
;; | ---------------------- | ------------------------------------- |
;; | pinboard               | Open the Pinboard pin list            |
;; | pinboard-add           | Add a new pin to Pinboard             |
;; | pinboard-add-for-later | Prompt for a URL and add it for later |

;;; Code:

(require 'seq)
(require 'json)
(require 'subr-x)
(require 'widget)
(require 'cl-lib)
(require 'url-vars)
(require 'url-util)
(require 'wid-edit)
(require 'easymenu)
(require 'thingatpt)
(require 'browse-url)
(require 'parse-time)
(require 'auth-source)

(defgroup pinboard nil
  "Pinboard client for Emacs."
  :group 'hypermedia
  :link '(url-link :tag "pinboard.el on GitHub"
                   "https://github.com/davep/pinboard.el")
  :link '(url-link :tag "Pinboard"
                   "https://pinboard.in/"))

(defcustom pinboard-private-symbol "-"
  "The character to use to show a pin is private."
  :type 'string
  :group 'pinboard)

(defcustom pinboard-public-symbol " "
  "The character to use to show a pin is public."
  :type 'string
  :group 'pinboard)

(defcustom pinboard-time-format-function
  '(lambda (time)
     (format-time-string "%Y-%m-%d %H:%M:%S" (parse-iso8601-time-string time)))
  "The function to use to format the time of a pin in the list."
  :type 'function
  :group 'pinboard)

(defcustom pinboard-confirm-toggle-read t
  "Should we confirm toggling the read state of a pin?"
  :type 'boolean
  :group 'pinboard)

(defface pinboard-caption-face
  '((t :inherit (bold font-lock-function-name-face)))
  "Face used on captions in the Pinboard output windows."
  :group 'pinboard)

(defface pinboard-unread-face
  '((t :inherit (bold)))
  "Face used for unread pins in the pin list."
  :group 'pinboard)

(defface pinboard-read-face
  '((t :inherit (default)))
  "Face used for read pins in the pin list."
  :group 'pinboard)

(defconst pinboard-list-buffer-name "*Pinboard*"
  "The name of the main Pinboard pin list buffer.")

(defconst pinboard-api-url "https://api.pinboard.in/v1/%s?auth_token=%s&format=json"
  "Base URL of the Pinboard API.")

(defconst pinboard-agent "pinboard.el (https://github.com/davep/pinboard.el)"
  "User agent to send to the Pinboard server.")

(defvar pinboard-api-token nil
  "Your Pinboard account's API token.

Visit https://pinboard.in/settings/password to get the token for
your account.

DO NOT EVER SET THIS IN A WAY THAT IT CAN BE SEEN IN SOME PUBLIC
REPOSITORY!")

(defvar pinboard-last-updated nil
  "Cache of the time that Pinboard was last updated.")

(defvar pinboard-pins nil
  "Cache of pins to display.")

(defvar pinboard-tags nil
  "Cache of tags the user has used.")

(defvar pinboard-last-filter nil
  "The last filter used by `pinboard-redraw'.")

(defvar pinboard-tag-filter nil
  "The current list of tags we're filtering by.

Used by `pinboard-tagged' to create an additive filtering
effect.")

(defun pinboard-remember-call (caller)
  "Remember now as when CALLER was last called."
  (put caller :pinboard-last-called (float-time)))

(defun pinboard-last-called (caller)
  "When was CALLER last called?"
  (or (get caller :pinboard-last-called) 0))

(defun pinboard-too-soon (caller &optional rate)
  "Are we hitting on Pinboard too soon?

See if we're calling CALLER before RATE has expired. RATE is
optional and defaults to 3 seconds (as per the pinboard API
documentation.)"
  (when-let ((last (pinboard-last-called caller)))
    (<= (- (float-time) last) (or rate 3))))

(defun pinboard-auth ()
  "Attempt to get the API token for Pinboard."
  (unless pinboard-api-token
    (when-let ((auth (car (auth-source-search :host "api.pinboard.in" :requires '(secret))))
               (token (plist-get auth :secret)))
      (setq pinboard-api-token (funcall token)))))

(defun pinboard-api-url (&rest params)
  "Build the API call from PARAMS."
  (format pinboard-api-url (string-join params "/") pinboard-api-token))

(defun pinboard-with-params (url &rest params)
  "Combine URL with PARAMS to make a new URL."
  (format "%s&%s"
          url
          (string-join
           (mapcar (lambda (param)
                     (format "%s=%s" (car param) (url-hexify-string (cdr param))))
                   params)
           "&")))

(defun pinboard--api-bom-guard (s)
  "Guard S against the current BOM issue with the Pinboard API."
  ;; Yes, yes, I know... It's just for now. See
  ;; https://github.com/davep/pinboard.el/issues/12 for some background.
  (substring s (if (= (aref s 0) 65279) 1 0)))

(defun pinboard-call (url caller)
  "Call on URL and return the data.

CALLER is a symbol that is the name of the caller. This is used
to help set rate limits."
  (let ((url-request-extra-headers `(("User-Agent" . ,pinboard-agent)))
        (url-show-status nil))
    (pinboard-remember-call caller)
    (with-temp-buffer
      (url-insert-file-contents url)
      (condition-case err
          ;; https://github.com/davep/pinboard.el/issues/7
          (let ((json-false ""))
            (json-read-from-string (pinboard--api-bom-guard (buffer-string))))
        (error
         (error "Error '%s' handling reply from Pinboard: %s"
                (error-message-string err) (buffer-string)))))))

(defun pinboard-last-updated ()
  "Get when Pinboard was last updated."
  (if (pinboard-too-soon :pinboard-last-updated)
      pinboard-last-updated
    (when-let ((result (alist-get 'update_time (pinboard-call (pinboard-api-url "posts" "update") :pinboard-last-updated))))
      (setq pinboard-last-updated (float-time (parse-iso8601-time-string result))))))

(defun pinboard-get-tags ()
  "Get the list of tags used by the user."
  ;; If it's within the 3 second rule...
  (if (pinboard-too-soon :pinboard-get-tags)
      ;; ...just go with what we've got.
      pinboard-tags
    ;; We're not calling on Pinboard too soon. So, next up, let's see if
    ;; pins have been updated since we last called for tags, or if we simply
    ;; don't have any tags yet...
    (if (or (not pinboard-tags) (< (pinboard-last-called :pinboard-get-tags) (pinboard-last-updated)))
        ;; ...grab a copy of the user's tags.
        (setq pinboard-tags (pinboard-call
                             (pinboard-api-url "tags" "get")
                             :pinboard-get-tags))
      ;; Looks like nothing has changed, so go with the tags we've already
      ;; got.
      pinboard-tags)))

(defun pinboard-get-pins ()
  "Return all of the user's pins on Pinboard."
  ;; If we're calling on the list within 5 minutes of a previous call, just
  ;; go with what we've got (see the rate limits in the Pinboard API).
  (if (pinboard-too-soon :pinboard-get-pins 300)
      pinboard-pins
    ;; Okay, we're not calling too soon. This also suggests we've called
    ;; before too. If we don't have any pins yet (normally not an issue at
    ;; this point, but useful for testing), or pins have been updated more
    ;; recently...
    (if (or (not pinboard-pins) (< (pinboard-last-called :pinboard-get-pins) (pinboard-last-updated)))
        ;; ...grab a fresh copy.
        (setq pinboard-pins
              (pinboard-call
               (pinboard-api-url "posts" "all")
               :pinboard-get-pins))
      ;; Looks like nothing has changed. Return what we've got.
      pinboard-pins)))

(defun pinboard-delete-pin (href)
  "Delete the pin for HREF."
  ;; Get the API to delete it on the server.
  (pinboard-call
   (pinboard-with-params
    (pinboard-api-url "posts" "delete")
    (cons 'url href))
   :pinboard-delete-pin)
  ;; Filter out any versions held locally.
  (when pinboard-pins
    (setq pinboard-pins
          (seq-remove
           (lambda (pin) (string= (alist-get 'href pin) href))
           pinboard-pins)))
  ;; Let the user know we did it.
  (message "Deleted \"%s\"." href))

(defun pinboard-find-pin (via value)
  "Find and return the pin identified by VIA.

The pin is returned if VALUE matches."
  (seq-find
   (lambda (pin) (string= (alist-get via pin) value))
   (pinboard-get-pins)))

(defun pinboard-redraw (&optional filter)
  "Redraw the pin list.

Optionally filter the list of pins to draw using the function
FILTER."
  ;; If there is no filter...
  (unless filter
    ;; ...ensure any ongoing tagging filter gets cleared.
    (setq pinboard-tag-filter nil))
  (cl-flet ((highlight (s pin)
                       (propertize s 'font-lock-face
                                   (if (string= (alist-get 'toread pin) "yes")
                                       'pinboard-unread-face
                                     'pinboard-read-face))))
    (setq tabulated-list-entries
          (mapcar (lambda (pin)
                    (list
                     (alist-get 'hash pin)
                     (vector
                      (highlight
                       (if (string= (alist-get 'shared pin) "yes")
                           pinboard-public-symbol
                         pinboard-private-symbol)
                       pin)
                      (highlight (alist-get 'description pin) pin)
                      (highlight (funcall pinboard-time-format-function (alist-get 'time pin)) pin)
                      (highlight (alist-get 'href pin) pin))))
                  (seq-filter
                   (setq pinboard-last-filter (or filter #'identity))
                   (pinboard-get-pins)))))
  (tabulated-list-print t))

(defun pinboard-maybe-redraw ()
  "Redraw the pin list, but only if it exists."
  (when-let ((buffer (get-buffer pinboard-list-buffer-name)))
    (with-current-buffer buffer
      (pinboard-redraw pinboard-last-filter))))

(defmacro pinboard-with-current-pin (name &rest body)
  "Evaluate BODY with the currently-selected pin as NAME."
  (declare (indent 1))
  (let ((pin-id (gensym)))
    `(if (not (string= (buffer-name) pinboard-list-buffer-name))
         (error "Only available in the Pinboard list buffer")
       (when-let ((,pin-id  (tabulated-list-get-id)))
         (let ((,name (pinboard-find-pin 'hash ,pin-id)))
           (if ,name
               (progn ,@body)
             (error "Could not find pin %s" ,pin-id)))))))

(defun pinboard-open ()
  "Open the currently-highlighted pin in a web browser."
  (interactive)
  (pinboard-with-current-pin pin
    (browse-url (alist-get 'href pin))))

(defun pinboard-kill-url ()
  "Add the current pin's URL to the `kill-ring'."
  (interactive)
  (pinboard-with-current-pin pin
    (kill-new (alist-get 'href pin))
    (message "URL copied to the kill ring")))

(defun pinboard-caption (s)
  "Add properties to S to make it a caption for Pinboard output."
  (propertize (concat s ": ") 'font-lock-face 'pinboard-caption-face))

(defun pinboard-view ()
  "View the details of the currently-highlighted pin."
  (interactive)
  (pinboard-with-current-pin pin
    (with-help-window "*Pinboard pin*"
      (with-current-buffer standard-output
        (insert
         (pinboard-caption "Title") "\n"
         (alist-get 'description pin) "\n\n"
         (pinboard-caption "URL") "\n")
        (help-insert-xref-button
         (alist-get 'href pin)
         'help-url
         (alist-get 'href pin))
        (let ((desc (string-trim (alist-get 'extended pin))))
          (unless (zerop (length desc))
            (insert
             "\n\n"
             (pinboard-caption "Description") "\n"
             (with-temp-buffer
               (insert desc)
               (fill-region (point-min) (point-max))
               (buffer-string)))))
        (insert
         "\n\n"
         (pinboard-caption "Time") "\n"
         (funcall pinboard-time-format-function (alist-get 'time pin)) "\n\n"
         (pinboard-caption "Public") "\n"
         (capitalize (alist-get 'shared pin)) "\n\n"
         (pinboard-caption "Unread") "\n"
         (capitalize (alist-get 'toread pin)) "\n\n"
         (pinboard-caption "Tags") "\n"
         (alist-get 'tags pin))))))

(defun pinboard-unread (on-web)
  "Only show unread pins.

If ON-WEB is non-nil a view of unread pins will be opened in the
web browser instead."
  (interactive "P")
  (if on-web
      (browse-url "https://pinboard.in/toread")
    (pinboard-redraw (lambda (pin) (string= (alist-get 'toread pin) "yes")))))

(defun pinboard-read ()
  "Only show read pins."
  (interactive)
  (pinboard-redraw (lambda (pin) (string= (alist-get 'toread pin) "no"))))

(defun pinboard-public ()
  "Only show public pins."
  (interactive)
  (pinboard-redraw (lambda (pin) (string= (alist-get 'shared pin) "yes"))))

(defun pinboard-private ()
  "Only show private pins."
  (interactive)
  (pinboard-redraw (lambda (pin) (string= (alist-get 'shared pin) "no"))))

(defun pinboard-read-tag ()
  "Read and return a Pinboard tag from the user."
  (completing-read "Tag: " (pinboard-get-tags)))

(defun pinboard-extend-tagged (tag)
  "Add TAG to the current tag filter and redraw."
  (interactive (list (pinboard-read-tag)))
  (cl-pushnew (downcase tag) pinboard-tag-filter :test #'equal)
  (pinboard-redraw
   (lambda (pin)
     (=
      (length (seq-intersection
               (split-string (downcase (alist-get 'tags pin)))
               pinboard-tag-filter))
      (length pinboard-tag-filter))))
  (message "Showing all pins tagged: %s" (string-join pinboard-tag-filter ", ")))

(defun pinboard-tagged (tag)
  "Show all pins tagged with TAG."
  (interactive (list (pinboard-read-tag)))
  (setq pinboard-tag-filter nil)
  (pinboard-extend-tagged tag))

(defun pinboard-untagged ()
  "Only show pints that have no tags."
  (interactive)
  (pinboard-redraw (lambda (pin) (zerop (length (alist-get 'tags pin ""))))))

(defun pinboard-search (text)
  "Only show pins that contain TEXT somewhere.

The title, description and tags are all searched. Search is case-insensitive."
  (interactive "sText: ")
  (let ((text (downcase text)))
    (pinboard-redraw
     (lambda (pin)
       (string-match-p (regexp-quote text)
                       (downcase
                        (concat
                         (alist-get 'description pin)
                         " "
                         (alist-get 'extended pin)
                         " "
                         (alist-get 'tags pin))))))))

(defun pinboard-refresh ()
  "Refresh the list."
  (interactive)
  (pinboard-redraw))

(defun pinboard-refresh-locally (url title description tags private to-read)
  "Refresh the local list of pins with the given information.

Parameters are:

URL         - The URL of the pin.
TITLE       - The title to give the pin.
DESCRIPTION - The longer description to give the pin.
TAGS        - The tags of the pin.
PRIVATE     - Is the pin private or not?
TO-READ     - Should the pin be marked has having being read or not?

This function updates the local copy of the pins held in
`pinboard-pins' (which should always be accessed via
`pinboard-get-pins'). If the URL already exists in
`pinboard-pins' the entry will be updated, otherwise a new pin
will be added to `pinboard-pins'."
  ;; Find any existing pin data based on the URL.
  (let ((pin (pinboard-find-pin 'href url)))
    ;; Update all the normal values.
    (setf (alist-get 'href pin) url)
    (setf (alist-get 'description pin) title)
    (setf (alist-get 'extended pin) description)
    (setf (alist-get 'tags pin) tags)
    (setf (alist-get 'shared pin) (if private "no" "yes"))
    (setf (alist-get 'toread pin) (if to-read "yes" "no"))
    ;; If there's no hash, we didn't really find a pin and we're building up
    ;; data for a brand new one, so...
    (unless (alist-get 'hash pin)
      ;; Fake the hash; we need one so let's fake it and it'll do until we
      ;; get the real one back from the server some time in the future.
      (setf (alist-get 'hash pin) (md5 url))
      ;; Ditto with the time. Set it to now and we'll go with the server
      ;; version later on.
      (setf (alist-get 'time pin) (format-time-string "%Y-%m-%dT%T%z"))
      ;; Add the new faked pin to the start of the local pin list.
      (setq pinboard-pins (vconcat (list pin) pinboard-pins)))
    ;; If the pinboard list buffer is kicking around somewhere...
    (pinboard-maybe-redraw)))

(defun pinboard-save (url title description tags private to-read)
  "Save a new pin to Pinboard.

The following values are added:

URL         - The URL of the pin.
TITLE       - The title to give the pin.
DESCRIPTION - The longer description to give the pin.
TAGS        - The tags of the pin.
PRIVATE     - Is the pin private or not?
TO-READ     - Should the pin be marked has having being read or not?"
  (pinboard-call
   (pinboard-with-params
    (pinboard-api-url "posts" "add")
    (cons 'url url)
    (cons 'description title)
    (cons 'extended description)
    (cons 'tags tags)
    (cons 'shared (if private "no" "yes"))
    (cons 'toread (if to-read "yes" "no")))
   :pinboard-save)
  (pinboard-refresh-locally url title description tags private to-read)
  (message "Saved %s to Pinboard" url))

(defun pinboard-save-pin (pin)
  "Save PIN to Pinboard.

This is simply a wrapper around `pinboard-save' that pulls apart
the pin data as is used in the main list."
  (pinboard-save
   (alist-get 'href pin)
   (alist-get 'description pin)
   (alist-get 'extended pin)
   (alist-get 'tags pin)
   (string= (alist-get 'shared pin) "no")
   (string= (alist-get 'toread pin) "yes")))

(defmacro pinboard-field (suffix widget)
  "Create a Pinboard field for a form.

The field name will be pinboard-field- followed by SUFFIX, and
its value will be set to WIDGET."
  (declare (indent 1))
  (let ((name (intern (format "pinboard-field-%s" suffix))))
    `(progn
       (make-local-variable (defvar ,name))
       (setq ,name ,widget))))

(defun pinboard-make-form (buffer-name title &optional pin)
  "Make a pinboard edit form in the current buffer.

A new buffer is created, with a name based around BUFFER-NAME.

TITLE is shown at the top of the form and the form is optionally
populated with the values of PIN."
  (let ((default-url (unless (derived-mode-p 'pinboard-mode)
                       (thing-at-point-url-at-point)))
        (form-buffer-name (format "*Pinboard: %s*" buffer-name)))
    (when (get-buffer form-buffer-name)
      (kill-buffer form-buffer-name))
    (let ((buffer (get-buffer-create form-buffer-name)))
      (with-current-buffer buffer
        (widget-insert (format "%s\n\n" (pinboard-caption title)))
        (pinboard-field url
          (widget-create 'editable-field
                         :size 80
                         :format (format "%s\n%%v" (pinboard-caption "URL"))
                         (if pin
                             (alist-get 'href pin)
                           (or default-url ""))))
        (pinboard-field title
          (widget-create 'editable-field
                         :size 80
                         :format (format "\n%s\n%%v" (pinboard-caption "Title"))
                         (if pin (alist-get 'description pin) "")))
        (pinboard-field description
          (widget-create 'text
                         :size 80
                         :format (format "\n%s\n%%v" (pinboard-caption "Description"))
                         (if pin (alist-get 'extended pin) "")))
        (pinboard-field tags
          (widget-create 'editable-field
                         :size 80
                         :format (format "\n\n%s\n%%v" (pinboard-caption "Tags"))
                         (if pin (alist-get 'tags pin) "")))
        (widget-insert "\n\n" (pinboard-caption "Private"))
        (pinboard-field private
          (widget-create 'checkbox
                         (if pin (not (string= (alist-get 'shared pin) "yes")) t)))
        (widget-insert " " (pinboard-caption "To Read"))
        (pinboard-field to-read
          (widget-create 'checkbox
                         (if pin (string= (alist-get 'toread pin) "yes") t)))
        (widget-insert "\n\n")
        (widget-create 'push-button
                       :notify
                       (lambda (&rest _)
                         (when (string-empty-p (widget-value pinboard-field-url))
                           (error "Please provide a URL for the pin"))
                         (when (string-empty-p (widget-value pinboard-field-title))
                           (error "Please provide a title for the pin"))
                         (pinboard-save
                          (widget-value pinboard-field-url)
                          (widget-value pinboard-field-title)
                          (widget-value pinboard-field-description)
                          (widget-value pinboard-field-tags)
                          (widget-value pinboard-field-private)
                          (widget-value pinboard-field-to-read))
                         (kill-buffer buffer))
                       "Save")
        (widget-insert " ")
        (widget-create 'push-button
                       :notify (lambda (&rest _) (kill-buffer buffer))
                       "Cancel")
        (widget-insert "\n")
        (use-local-map widget-keymap)
        (widget-setup)
        (font-lock-mode)
        (switch-to-buffer buffer)
        (setf (point) (point-min))
        (widget-forward 1)))))

(defmacro pinboard-not-too-soon (action &rest body)
  "Ensure the API isn't hit on too soon.

A check is made to see if ACTION is happening too soon for the
Pinboard API. If it is an error is emitted and BODY isn't
evaluated, otherwise BODY is evaluated."
  (declare (indent 1))
  `(if (pinboard-too-soon ,action)
       (error "Too soon. Please try again in a few seconds")
     ,@body))

;;;###autoload
(defun pinboard-add ()
  "Add a new pin to Pinboard."
  (interactive)
  (pinboard-auth)
  (pinboard-not-too-soon :pinboard-save
    (pinboard-make-form "New pin" "Add a new pin to Pinboard")))

(defun pinboard-edit ()
  "Edit the current pin in the pin list."
  (interactive)
  (pinboard-auth)
  (pinboard-not-too-soon :pinboard-save
    (pinboard-with-current-pin pin
      (pinboard-make-form "Edit pin" "Edit the pin" pin))))

(defun pinboard-delete ()
  "Delete the current pin in the pin list."
  (interactive)
  (pinboard-auth)
  (pinboard-not-too-soon :pinboard-delete-pin
    (pinboard-with-current-pin pin
      (when (yes-or-no-p (format "Delete \"%s\"? " (alist-get 'href pin)))
        (pinboard-delete-pin (alist-get 'href pin))
        (pinboard-maybe-redraw)))))

(defun pinboard-toggle-read ()
  "Toggle the read/unread status of the current pin in the list."
  (interactive)
  (pinboard-auth)
  (pinboard-not-too-soon :pinboard-save
    (pinboard-with-current-pin pin
      (let ((current (string= (alist-get 'toread pin) "yes")))
        (when (or (not pinboard-confirm-toggle-read)
                  (y-or-n-p (format "Mark \"%s\" as %sread? "
                                    (alist-get 'href pin)
                                    (if current "" "un"))))
          (setf (alist-get 'toread pin) (if current "no" "yes"))
          (pinboard-save-pin pin))))))

;;;###autoload
(defun pinboard-visit-pinboard()
  "Visit pinboard.in itself."
  (interactive)
  (browse-url "https://pinboard.in/"))

;;;###autoload
(defun pinboard-add-for-later (url)
  "Quickly add URL for later review and reading.

This command simply prompts for a URL and adds it to Pinboard as
private and unread, so you can come back to it and look at it
later."
  (interactive (list (read-string "URL: " (thing-at-point-url-at-point))))
  (if (string-empty-p (string-trim url))
      (error "Please provide a URL to save")
    (pinboard-auth)
    (pinboard-not-too-soon :pinboard-save
      (pinboard-save url url "" "" t t))))

(defvar pinboard-mode-map
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map t)
    (define-key map "a"         #'pinboard-refresh)
    (define-key map "k"         #'pinboard-kill-url)
    (define-key map "g"         #'pinboard-refresh)
    (define-key map "p"         #'pinboard-public)
    (define-key map "P"         #'pinboard-private)
    (define-key map "u"         #'pinboard-unread)
    (define-key map "r"         #'pinboard-read)
    (define-key map "t"         #'pinboard-extend-tagged)
    (define-key map "T"         #'pinboard-tagged)
    (define-key map "U"         #'pinboard-untagged)
    (define-key map "/"         #'pinboard-search)
    (define-key map " "         #'pinboard-view)
    (define-key map (kbd "RET") #'pinboard-open)
    (define-key map "n"         #'pinboard-add)
    (define-key map "e"         #'pinboard-edit)
    (define-key map "d"         #'pinboard-delete)
    (define-key map "R"         #'pinboard-toggle-read)
    (define-key map "v"         #'pinboard-visit-pinboard)
    map)
  "Local keymap for `pinboard'.")

(define-derived-mode pinboard-mode tabulated-list-mode "Pinboard Mode"
  "Major mode for handling a list of Pinboard pins.

The key bindings for `pinboard-mode' are:

\\{pinboard-mode-map}"
  (setq tabulated-list-format
        [("P" 1 t)
         ("Description" 60 t)
         ("Time" 20 t)
         ("URL" 30 t)])
  (tabulated-list-init-header)
  (setq tabulated-list-sort-key '("Time" . t)))

(easy-menu-define pinboard-mode-menu pinboard-mode-map "Pinboard menu"
  '("Pinboard"
    ["Refresh/Show all"               pinboard-refresh]
    ["View pin"                       pinboard-view        (tabulated-list-get-id)]
    ["Add URL to kill buffer"         pinboard-kill-url    (tabulated-list-get-id)]
    ["Search pins..."                 pinboard-search]
    "--"
    ["Add a pin..."                   pinboard-add]
    ["Edit the current pin..."        pinboard-edit        (tabulated-list-get-id)]
    ["Toggle read status..."          pinboard-toggle-read (tabulated-list-get-id)]
    ["Delete the current pin..."      pinboard-delete      (tabulated-list-get-id)]
    "--"
    ["Show public pins"               pinboard-public]
    ["Show private pins"              pinboard-private]
    "--"
    ["Show read pins"                 pinboard-read]
    ["Show unread pins"               pinboard-unread]
    "--"
    ["Show pins tagged..."            pinboard-tagged]
    ["Add tag to current tag view..." pinboard-extend-tagged pinboard-tag-filter]
    ["Show untagged pins"             pinboard-untagged]
    "--"
    ["Visit pinboard in browser"      pinboard-visit-pinboard]
    "--"
    ["Quit"                           quit-window]))

;;;###autoload
(defun pinboard ()
  "Browse your Pinboard pins.

Key bindings that are active in the pin list include:

\\{pinboard-mode-map}"
  (interactive)
  (pinboard-auth)
  (if (not pinboard-api-token)
      (error "Please set your Pinboard API token")
    (pop-to-buffer pinboard-list-buffer-name)
    (pinboard-mode)
    (pinboard-refresh)))

(provide 'pinboard)

;;; pinboard.el ends here
