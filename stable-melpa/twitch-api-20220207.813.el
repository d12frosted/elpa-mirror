;;; twitch-api.el --- An elisp interface for the Twitch.tv API

;; Copyright (C) 2015-2016 Aaron Jacobs
;; Copyright (C) 2020-2021 Benedikt Broich
;; Version: 0.1
;; Package-Version: 20220207.813
;; Package-Commit: e48b0b350516e20eaf85514e8855c2fbfbf09c11
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

(defcustom twitch-api-client-id "d6hul5ut8dmqvl6tsa90254yzu8g612"
  "The Client ID for the application.

If you want to use your own, you can register for for one at
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

(cl-defstruct (twitch-api-stream (:constructor twitch-api-stream--create))
  "A Twitch.tv stream."
  name viewers status game url)

(cl-defstruct (twitch-api-channel (:constructor twitch-api-channel--create))
  "A Twitch.tv channel."
  name followers game url)

;;;; Authentication

(defun twitch-api-authenticate ()
  "Retrieve an OAuth token for a Twitch.tv account through a browser."
  (interactive)
  (cl-assert twitch-api-client-id)
  (browse-url
   (concat "https://api.twitch.tv/kraken/oauth2/authorize?response_type=token"
	   "&client_id=" twitch-api-client-id
	   "&redirect_uri=http://localhost"
	   "&scope=user_read+user_follows_edit+chat_login"))
  (let ((token (read-string "OAuth Token: ")))
    (if (equal token "")
	(user-error "No token supplied. Aborting.? ")
      (setq twitch-api-oauth-token token))))

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
         (api-url (concat "https://api.twitch.tv/kraken/" endpoint "?" params))
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
	  ;; Add the Authorization ID (if present).
    (when (and auth twitch-api-oauth-token)
      (push `("Authorization" . ,(format "OAuth %s" twitch-api-oauth-token))
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
  (let* ((opts (if (integerp limit) '(:limit limit)))
	 (opts (if twitch-api-game-filter
		   (append '(:game twitch-api-game-filter) opts)
		 opts))
	 (opts (append `(:query ,search-term) opts))
	 ;; That was really just a way of building up a plist of options to
	 ;; pass to `twitch-api'...
	 (results (eval `,@(append '(twitch-api "streams" nil) opts))))
    (cl-loop for stream across (plist-get results ':streams) collect
	     (let ((channel (plist-get stream ':channel)))
	       (twitch-api-stream--create
		:name    (plist-get channel ':name)
		:viewers (plist-get stream ':viewers)
		:status  (replace-regexp-in-string "[
]" "" (plist-get channel ':status))
		:game    (plist-get channel ':game)
		:url     (plist-get channel ':url))))))

;;;###autoload
(defun twitch-api-search-channels (search-term &optional limit)
  "Retrieve a list of Twitch channels that match the SEARCH-TERM.

If LIMIT is an integer, pass that along to `twitch-api'."
  (let* ((opts (if (integerp limit) '(:limit limit)))
	 (opts (append `(:query ,search-term) opts))
	 (results (eval `,@(append '(twitch-api "search/channels" nil) opts))))
    (cl-loop for channel across (plist-get results ':channels) collect
	     (twitch-api-channel--create
	      :name      (plist-get channel ':name)
	      :followers (plist-get channel ':followers)
	      :game      (plist-get channel ':game)
	      :url       (plist-get channel ':url)))))

;;;###autoload
(defun twitch-api-get-followed-streams (&optional limit)
  "Retrieve a list of Twitch streams that match the SEARCH-TERM.
If LIMIT is an integer, pass that along to `twitch-api'."
  (cl-assert twitch-api-oauth-token)
  (let* ((opts (if (integerp limit) '(:limit limit)))
	 (results (eval `,@(append
			    '(twitch-api "streams/followed" t
					 :stream_type "live")
			    opts))))
    (cl-loop for stream across (plist-get results ':streams) collect
	     (let ((channel (plist-get stream ':channel)))
	       (twitch-api-stream--create
		:name    (plist-get channel ':name)
		:viewers (plist-get stream ':viewers)
		:status  (replace-regexp-in-string "[
]" "" (plist-get channel ':status))
		:game    (plist-get channel ':game)
		:url     (plist-get channel ':url))))))


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
(defun twitch-api-erc-join-channel (channel-name)
  "Invokes `erc' to open Twitch chat for a given CHANNEL-NAME."
  (interactive "sChannel: ")
  (if (and twitch-api-username twitch-api-oauth-token)
      (erc-join-channel (format "#%s" (downcase channel-name)))
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

;;;###autoload
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
