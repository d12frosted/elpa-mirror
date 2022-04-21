;;; twitch-api.el --- An elisp interface for the Twitch.tv API

;; Copyright (C) 2015-2016 Aaron Jacobs
;; Copyright (C) 2020-2021 Benedikt Broich
;; Version: 0.1
;; Package-Version: 20220420.1547
;; Package-Commit: 181681097d1fc8d7b78928f8a5b38c61d0e20ef5
;; Keywords: multimedia, twitch-api
;; URL: https://github.com/BenediktBroich/twitch-api
;; Package-Requires: ((emacs "27.1") (dash "2.19.0"))

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Commentary:
;; These are twitch API functions mainly used by helm-twitch.

;;; Code:

(require 'url)
(require 'dash)
(require 'json)
(require 'tabulated-list)
(require 'erc)

(defconst twitch-api-version "0.2"
  "Version of this package to advertise in the User-Agent string.")

(defcustom twitch-api-game-filter nil
  "If specified, limits the search to those streaming this game."
  :group 'helm-twitch
  :version 0.1
  :type 'string)

(defcustom twitch-api-username nil
  "A Twitch.tv username, for connecting to Twitch chat."
  :group 'helm-twitch
  :type 'string)

(defcustom twitch-api-full-name nil
  "A Twitch.tv username, for connecting to Twitch chat."
  :group 'helm-twitch
  :type 'string)

(defcustom twitch-api-oauth-token nil
  "The OAuth token for the Twitch.tv username in `twitch-api-username'.

To retrieve an OAuth token, check out `http://twitchapps.com/tmi/'."
  :group 'helm-twitch
  :type 'string)

(defcustom twitch-api-client-id "fvnc4hhky45iywd0o5q0aiy71ncbii"
  "The Client ID for the application.

If you want to use your own, you can register one at
`https://github.com/justintv/Twitch-API'."
  :group 'helm-twitch
  :type 'string)

(defcustom twitch-api-client-secret "fvnc4hhky45iywd0o5q0aiy71ncbii"
  "The Client secret for the application.

If you want to use your own, you can register one at
`https://github.com/justintv/Twitch-API'."
  :group 'helm-twitch
  :type 'string)

(defcustom twitch-api-curl-binary "curl"
  "Location of the curl program."
  :group 'helm-twitch
  :type 'string)

;;;; Utilities
(defun twitch-api--plist-to-url-params (plist)
  "Turn property list PLIST into an HTML parameter string."
  (mapconcat (lambda (entry)
	       (concat (url-hexify-string
			(nth 1 (split-string (format "%s" (nth 0 entry)) ":")))
		       "="
		       (url-hexify-string (format "%s" (nth 1 entry)))))
	     (-partition 2 plist) "&"))

;;;; Data Structures
(cl-defstruct (twitch-api-user-info (:constructor twitch-api-user-info--create))
  "A Twitch.tv channel."
  client_id login scopes user_id expires_in)

(defcustom twitch-api-current-user-info nil
  "Token Validation information for the user."
  :group 'helm-twitch
  :type 'twitch-api-user-info)

(cl-defstruct (twitch-api-stream (:constructor twitch-api-stream--create))
  "A Twitch.tv stream."
  user_id name viewers status game url)

(cl-defstruct (twitch-api-channel (:constructor twitch-api-channel--create))
  "A Twitch.tv channel."
  user_id name followers game url status)

;;;; Authentication

(defun twitch-api-authenticate ()
  "Retrieve an OAuth token for a Twitch.tv account through a browser."
  (interactive)
  (cl-assert twitch-api-client-id)
  (setq twitch-api-oauth-token nil)
  (browse-url
   (concat "https://id.twitch.tv/oauth2/authorize" "?"
	         "client_id=" twitch-api-client-id
           "&redirect_uri=http://localhost"
           "&response_type=token"
	         "&scope=openid"
           "+user:read:follows"
           "+user:read:subscriptions"
           "+chat:edit"
           "+chat:read"
           "+whispers:read"
           "+whispers:edit"))
  (let ((token (read-string "OAuth Token: ")))
    (if (equal token "")
	(user-error "No token supplied. Aborting.? ")
      (setq twitch-api-oauth-token token))))

;;;; Validation

;;;###autoload
(defun twitch-api-validate ()
  "Validates the Bearer token for a Twitch.tv account."
  (interactive)
  (let* ((results (eval `,@(append '(twitch-api "id.twitch.tv/oauth2/validate" t)
                                   nil))))
	  (setq twitch-api-current-user-info (twitch-api-user-info--create
	                              :client_id      (plist-get results ':client_id)
	                              :login          (plist-get results ':login)
	                              :scopes         (plist-get results ':scopes)
	                              :user_id        (plist-get results ':user_id)
	                              :expires_in     (plist-get results ':expires_in)))))

(defun twitch-api-get-url (name)
  "Create twitch url using the streamer NAME."
  (concat "https://twitch.tv/" name))

;;;; API Wrappers

;;;###autoload
(defun twitch-api (endpoint auth &rest plist)
  "Query the Twitch API at ENDPOINT.
Returns the resulting JSON in a property list structure.
When AUTH is non-nil, include the OAuth token in
`twitch-api-oauth-token' in the request (if it
exists).

Twitch API parameters can be passed in the property list PLIST.
For example:

    (twitch-api \"search/channels\" t :query \"flame\" :limit 15)"
  (let* ((params (twitch-api--plist-to-url-params plist))
         (api-url (concat "https://" endpoint "?" params))
         (curl-opts (list "--compressed" "--silent" "--location" "-D-"))
         (json-object-type 'plist) ;; Decode into a plist.
         (headers
          ;; Use a descriptive User-Agent.
          `(("User-Agent" . ,(format "twitch-api/%s Emacs/%s"
                                     twitch-api-version emacs-version))
            ;; Use version 3 of the API.
            ("Accept" . "application/vnd.twitchtv.v5+json"))))
    ;; Support setting the method lexically, as with url.el.
    (when url-request-method
      (push (format "-X%s" url-request-method) curl-opts))
      ;;; Add the Authorization ID (if present).
    (when (and auth twitch-api-oauth-token)
      (push `("Authorization" . ,(format "Bearer %s" twitch-api-oauth-token))
            headers))
	  ;; Add the Client ID (if present).
	  (when twitch-api-client-id
      (push `("Client-ID" . ,twitch-api-client-id) headers))
    ;; Wrap up arguments to curl.
    (dolist (header headers)
      (cl-destructuring-bind (key . value) header
        (push (format "-H%s: %s" key value) curl-opts)))
    (setq curl-opts (nreverse (cons api-url curl-opts)))
    (with-current-buffer (generate-new-buffer " *twitch-api*")
      (let ((coding-system-for-read 'binary))
        (apply #'call-process twitch-api-curl-binary nil t nil curl-opts))
      (goto-char (point-min))
      ;; Mimic url.el and store the status as a local variable.
      (re-search-forward "^HTTP/[\\.0-9]+ \\([0-9]+\\)")
      (unless (equal (string-to-number (match-string 1)) 204)
        (re-search-forward "^\r\n") ;; End of headers.
        ;; Many Twitch streams have non-ASCII statuses in UTF-8 encoding.
        (decode-coding-region (point) (point-max) 'utf-8)
        (let ((result (json-read)))
          (when (plist-get result ':error)
            ;; According to the Twitch API documentation, the JSON object should
            ;; contain error information of this kind on failure:
            (let ((status (plist-get result ':status))
                  (err    (plist-get result ':error))
                  (errmsg (plist-get result ':message)))
              (user-error "Twitch.tv API request failed: %d (%s)%s"
                          status err (when errmsg (concat " - " errmsg)))))
          result)))))

;;;###autoload
(defun twitch-api-search-streams (search-term &optional limit)
  "Retrieve a list of Twitch streams that match the SEARCH-TERM.

If LIMIT is an integer, pass that along to `twitch-api'."
  (interactive)
  (let* ((opts (if (integerp limit) '(:first limit)))
	       (opts (append `(:query ,search-term) opts))
	 ;; That was really just a way of building up a plist of options to
	 ;; pass to `twitch-api'...
	 (results (eval `,@(append '(twitch-api "api.twitch.tv/helix/streams" t)
                             opts))))
    (cl-loop for stream across (plist-get results ':data) collect
             (twitch-api-stream--create
		          :user_id (plist-get stream ':user_id)
		          :name    (plist-get stream ':user_name)
		          :viewers (plist-get stream ':viewer_count)
		          :status  (replace-regexp-in-string "[
]" "" (plist-get stream ':type))
		          :game    (plist-get stream ':game_name)
              :url (twitch-api-get-url (plist-get stream ':user_name))))))

;;;###autoload
(defun twitch-api-search-channels (search-term &optional limit)
  "Retrieve a list of Twitch channels that match the SEARCH-TERM.

If LIMIT is an integer, pass that along to `twitch-api'."
  (let* ((opts (if (integerp limit) '(:limit limit)))
	 (opts (append `(:query ,search-term) opts))
	 (results
    (eval `,@(append
              '(twitch-api "api.twitch.tv/helix/search/channels" t)
                             opts))))
    (cl-loop for channel across (plist-get results ':data) collect
	     (twitch-api-channel--create
              :user_id (plist-get channel ':user_id)
	      :name (plist-get channel ':display_name)
              :status (plist-get channel ':is_live)
              :game (plist-get channel ':game_name)))))

(defun twitch-api-get-followed-streams (&optional limit)
  "Retrieve a list of Twitch streams that match the SEARCH-TERM.
If LIMIT is an integer, pass that along to `twitch-api'."
  (cl-assert twitch-api-oauth-token)
  (twitch-api-validate)
  (let* ((user-id (twitch-api-user-info-user_id twitch-api-current-user-info))
         (opts (if (integerp limit) '(:limit limit)))
	       (results
                (eval `,@(append
                          #'(twitch-api "api.twitch.tv/helix/streams/followed" t
                                        :user_id user-id)
                          opts))))
    (cl-loop for stream across (plist-get results ':data) collect
             (twitch-api-stream--create
		          :user_id (plist-get stream ':user_id)
		          :name    (plist-get stream ':user_name)
		          :viewers (plist-get stream ':viewer_count)
		          :status  (replace-regexp-in-string "[
]" "" (plist-get stream ':type))
		          :game    (plist-get stream ':game_name)
              :url (twitch-api-get-url (plist-get stream ':user_name))))))

;;;; Twitch Chat Interaction
(defun twitch-api-erc-tls ()
  "Invokes `erc' to open Twitch chat for a given CHANNEL-NAME."
  (interactive)
  (if (and twitch-api-username twitch-api-oauth-token)
      (erc-tls :server "irc.chat.twitch.tv" :port 6697
	             :nick (downcase twitch-api-username)
	             :password (format "oauth:%s" twitch-api-oauth-token))
    (when (not twitch-api-username)
      (message "Set the variable `twitch-api-username' to connect to Twitch chat."))
    (when (not twitch-api-oauth-token)
      (message "Set the variable `twitch-api-oauth-token' to connect to Twitch chat."))))

;;;###autoload
(defun twitch-api-erc-join-channel (stream)
  "Invokes `erc' to open Twitch chat for a given CHANNEL-NAME.
Argument STREAM Channel name to join."
  (interactive "sChannel: ")
  (if (and twitch-api-username twitch-api-oauth-token)
      (erc-join-channel (twitch-api-stream-name stream))
    (when (not twitch-api-username)
      (message "Set the variable `twitch-api-username' to connect to Twitch chat."))
    (when (not twitch-api-oauth-token)
      (message "Set the variable `twitch-api-oauth-token' to connect to Twitch chat."))))

;;;; Top Streams Listing

(define-derived-mode twitch-api-top-streams-mode tabulated-list-mode "Top Twitch.tv Streams"
  "Major mode for `twitch-api-list-top-streams'."
  (setq tabulated-list-format
        [("Streamer" 17 t) ("Viewers" 7 twitch-api--sort-by-viewers)
         ("Game" 20 t) ("Status" 0 nil)])
  (setq tabulated-list-sort-key (cons "Viewers" nil))
  (add-hook 'tabulated-list-revert-hook
            'twitch-api--refresh-top-streams nil t))

(defun twitch-api--refresh-top-streams ()
  "Receive a list of top streams from twitch."
  (setq tabulated-list-entries
        (mapcar (lambda (elt)
                  (list elt (vector (twitch-api-stream-name elt)
                                    (int-to-string
                                     (twitch-api-stream-viewers elt))
                                    (twitch-api-stream-game elt)
                                    (twitch-api-stream-status elt))))
                (twitch-api-search-streams ""))))

(defun twitch-api--sort-by-viewers (s1 s2)
  "Sort streams by viewers. (> S1 S2)."
  (> (twitch-api-stream-viewers (car s1))
     (twitch-api-stream-viewers (car s2))))

(defun twitch-api-list-top-streams ()
  "Display a list of top streams on Twitch.tv."
  (interactive)
  (let ((buffer (get-buffer-create "*Top Twitch.tv Streams*")))
    (with-current-buffer buffer
      (twitch-api-top-streams-mode)
      (twitch-api--refresh-top-streams)
      (tabulated-list-init-header)
      (tabulated-list-print))
    (display-buffer buffer)
    nil))

(provide 'twitch-api)

;; Local Variables:
;; coding: utf-8
;; End:

;;; twitch-api.el ends here
