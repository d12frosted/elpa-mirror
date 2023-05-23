;;; oauth.el --- OAuth 1.0 client library  -*- lexical-binding: t; -*-

;; Copyright (C) 2009 Peter Sanford

;; Author: Peter Sanford <peter@petersdanceparty.com>
;;  Neil Roberts <bpeeluk@yahoo.co.uk>
;; Maintainer: Folkert van der Beek <folkertvanderbeek@gmail.com>
;; Created: 19 January 2009
;; Version: 1.10
;; Package-Version: 20230522.1900
;; Package-Commit: 78f4f8539c72eda6cb2187c1efbb9e857e013be5

;; Keywords: comm
;; Package-Requires: ((emacs "25.1") (hmac "1.0"))
;; URL: https://github.com/fvdbeek/emacs-oauth

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This is oauth client library implementation in elisp. It is
;; capable of authenticating (receiving an access token) and signing
;; requests. Currently it only supports HMAC-SHA1, although adding
;; additional signature methods should be relatively straight forward.

;; Visit http://oauth.net/core/1.0a for the complete oauth spec.

;; Oauth requires the client application to receive user authorization in order
;; to access restricted content on behalf of the user. This allows for
;; authenticated communication without jeopardizing the user's password.
;; In order for an application to use oauth it needs a key and secret
;; issued by the service provider.

;; Usage:

;; Obtain access token:

;; The easiest way to obtain an access token is to call (oauth-authorize-app)
;; This will authorize the application and return an oauth-access-token.
;; You will use this token for all subsequent requests. In many cases
;; it will make sense to serialize this token and reuse it for future sessions.
;; At this time, that functionality is left to the application developers to
;; implement (see yammer.el for an example of token serialization).

;; Two helper functions are provided to handle authenticated requests:
;; (oauth-fetch-url) and (oauth-post-url)
;; Both take the access-token and a url.
;; Post takes an additional parameter post-vars-alist which is a
;; list of key val pairs to be used in a x-www-form-urlencoded message.

;; yammer.el:
;; http://github.com/psanford/emacs-yammer/tree/master is an example
;; mode that uses oauth.el

;; Dependencies:

;; The default behavior of oauth.el is to dispatch to curl for http
;; communication. It is strongly recommended that you use curl.
;; If curl is unavailable you can set oauth-use-curl to nil and oauth.el
;; will try to use the emacs internal http functions (url-request).
;; Note: if you plan on doing https and have oauth-use-curl set to nil,
;; make sure you have gnutls-bin installed.


;; This library assumes that you are using the oauth_verifier method
;; described in the 1.0a spec.

;;; Code:

(eval-when-compile
  (require 'cl-lib))
(require 'hmac)
(require 'sasl)
(require 'url)
(require 'url-util)
(require 'hex-util)

(cl-defstruct (oauth-request (:constructor oauth-request--create)
                             (:copier nil))
  "Handle for OAuth requests."
  (method "POST"
          :documentation "HTTP request method."
          :type 'string)
  (url ""
       :documentation "The service provider's Request Token URL."
       :type 'string)
  (params nil
          :documentation "Any additional parameters."
          :type 'cons)
  (token nil
         :documentation "Token used for both Unauth Request
         Token and Access Token"
         :type oauth-t))

(cl-defstruct (oauth-t (:constructor oauth-t--create)
                       (:copier nil))
  "Token used for both Unauth Request Token and Access Token"
  (token ""
         :documentation "The Request Token."
         :type 'string)
  (token-secret ""
                :documentation "The Token Secret."
                :type 'string))

(cl-defstruct (oauth-access-token (:constructor oauth-access-token--create)
                                  (:copier nil))
  "Access Token used when signing requests."
  (consumer-key ""
                :documentation "Key issued by the service
                provider")
  (consumer-secret ""
                   :documentation "Secret issued by the service
                   provider")
  (auth-t nil
          :documentation "Access Token"
          :type oauth-t))

(defvar oauth-enable-browse-url t
  "Specifies whether or not to use call browse-url for authorizing apps.

Disabling is useful for remote machines.
Most of the time you will want this set to t.")

(defvar oauth-use-curl t
  "Specifies whether to use curl (external) or url-request (emacs internal) for requests.

It is generally recomended that you use curl for your requests.")

(defvar oauth-curl-insecure t
  "Use the curl insecure flag (-k) which ignores ssl certificate errors.")

(defvar oauth-post-vars-alist nil
  "Alist containing key/vals for POSTing (x-www-form-urlencoded) requests.")

(defvar oauth-callback-url "oob"
  "Callback url for the server to redirect the client after the client authorizes the application.

This is mainly intended for web apps. Most client side apps will use 'oob' instead of a url.")

(defun oauth-authorize-app (consumer-key consumer-secret request-url access-url authorize-url)
  "Authorize application.

CONSUMER-KEY and CONSUMER-SECRET are the key and secret issued by the
service provider.

REQUEST-URL is the url to request an unauthorized token.
ACCESS-URL is the url to request an access token.
AUTHORIZE-URL is the url that oauth.el should redirect the user to once
it has received an unauthorized token.

This will fetch an unauthorized token, prompt the user to authorize this
application and the fetch the authorized token.

Returns an oauth-access-token if everything was successful."
  (let* ((oauth-req (oauth--make-request request-url consumer-key))
         (unauth-req (oauth--sign-request-hmac-sha1 oauth-req consumer-secret))
         (unauth-t (oauth--fetch-token unauth-req))
         (auth-url (format "%s?oauth_token=%s" authorize-url (oauth-t-token unauth-t)))
         auth-t
         auth-req
         access-token)
    (if oauth-enable-browse-url (browse-url auth-url))
    (read-string (concat
                  "Please authorize this application by visiting: " auth-url
                  " \nPress enter once you have done so: "))
    (setq access-token (read-string
                        "Please enter the provided code: "))
    (setq auth-req
          (oauth--sign-request-hmac-sha1
           (oauth--make-request
            (concat access-url "?oauth_verifier=" access-token)
            consumer-key unauth-t)
           consumer-secret))
    (setq auth-t (oauth--fetch-token auth-req))
    (oauth-access-token--create :consumer-key consumer-key
                                :consumer-secret consumer-secret
                                :auth-t auth-t)))

(defun oauth-url-retrieve (access-token url &optional async-callback cb-data)
  "Like url retrieve, with url-request-extra-headers set to the necessary
oauth headers."
  (let ((req (oauth--make-request
              url
              (oauth-access-token-consumer-key access-token)
              (oauth-access-token-auth-t access-token))))
    (setf (oauth-request-method req) (or url-request-method "GET"))
    (when oauth-post-vars-alist
      (setf (oauth-request-params req)
            (append (oauth-request-params req) oauth-post-vars-alist)))
    (oauth--sign-request-hmac-sha1
     req (oauth-access-token-consumer-secret access-token))
    (let ((url-request-extra-headers (if url-request-extra-headers
                                         (append url-request-extra-headers
                                                 (oauth--request-to-header req))
                                       (oauth--request-to-header req)))
          (url-request-method (oauth-request-method req)))
      (cond
       (async-callback (url-retrieve (oauth-request-url req)
                                     async-callback cb-data))
       (oauth-use-curl (oauth--curl-retrieve (oauth-request-url req)))
       (t (url-retrieve-synchronously (oauth-request-url req)))))))

(defun oauth-fetch-url (access-token url)
  "Wrapper around url-retrieve-synchronously using the the authorized-token
to authenticate.

This is intended for simple get reqests.
Returns a buffer of the xresponse."
  (oauth-url-retrieve access-token url))

(defun oauth-post-url (access-token url post-vars-alist)
  "Wrapper around url-retrieve-synchronously using the the authorized-token
to authenticate.

This is intended for simple post reqests.
Returns a buffer of the response."
  (let ((url-request-method "POST")
        (oauth-post-vars-alist post-vars-alist))
    (oauth-url-retrieve access-token url)))

(defun oauth--epoch-string ()
  "Returns a unix epoch timestamp string"
  (format "%d" (ftruncate (float-time (current-time)))))

(defun oauth--make-request (url consumer-key &optional token)
  "Generates a oauth-request object with default values

Most consumers should call this function instead of creating
oauth-request objects directly"
  (oauth-request--create :url url
                         :token token
                         :params `(("oauth_consumer_key" . ,consumer-key)
                                   ("oauth_timestamp" . ,(oauth--epoch-string))
                                   ("oauth_nonce" . ,(sasl-unique-id))
                                   ("oauth_callback" . ,oauth-callback-url)
                                   ("oauth_version" . "1.0"))))

;; HMAC-SHA1 specific code
(defun oauth--sign-request-hmac-sha1 (req secret)
  "Adds signature and signature_method to req.

This function is destructive"
  (let ((token (oauth-request-token req)))
    (push '("oauth_signature_method" . "HMAC-SHA1")
          (oauth-request-params req))
    (when token
      (push `("oauth_token" . ,(oauth-t-token token))
            (oauth-request-params req)))
    (push `("oauth_signature" . ,(oauth--build-signature-hmac-sha1 req secret))
          (oauth-request-params req)))
  req)

(defun oauth--build-signature-hmac-sha1 (req secret)
  "Returns the signature for the given request object"
  (let* ((token (oauth-request-token req))
         (key (concat secret "&" (when token (oauth-t-token-secret token))))
         (message (oauth--build-signature-basestring-hmac-sha1 req))
         (unibyte-key (encode-coding-string key 'utf-8 t))
         (unibyte-message (encode-coding-string message 'utf-8 t)))
    (base64-encode-string (hmac 'sha1 unibyte-key unibyte-message 'binary))))

(defun oauth--build-signature-basestring-hmac-sha1 (req)
  "Returns the base string for the hmac-sha1 signing function"
  (let ((base-url (oauth--extract-base-url req))
        (params (append
                 (oauth--extract-url-params req)
                 (copy-sequence (oauth-request-params req)))))
    (concat
     (oauth-request-method req) "&"
     (url-hexify-string base-url) "&"
     (url-hexify-string
      (mapconcat
       (lambda (pair)
         (concat (car pair) "=" (url-hexify-string (cdr pair))))
       (sort params
             (lambda (a b) (string< (car a) (car b))))
       "&")))))

(defun oauth--extract-base-url (req)
  "Returns just the base url.

For example: http://example.com?param=1 returns http://example.com"
  (let ((url (oauth-request-url req)))
    (if (string-match "\\([^?]+\\)" url)
        (match-string 1 url)
      url)))

(defun oauth--extract-url-params (req)
  "Returns an alist of param name . param value from the url"
  (let ((url (oauth-request-url req)))
    (when (string-match (regexp-quote "?") url)
      (mapcar (lambda (pair)
                `(,(car pair) . ,(cadr pair)))
              (url-parse-query-string (substring url (match-end 0)))))))

(defun oauth--fetch-token (req)
  "Fetches a token based on the given request object"
  (let ((token (oauth-t--create)))
    (set-buffer (oauth--do-request req))
    (goto-char (point-min))
    (let ((linebreak (search-forward "\n\n" nil t nil)))
      (when linebreak
        (delete-region (point-min) linebreak)))
    (goto-char (point-max))
    (let ((line-end (search-backward "\r\n" nil t nil)))
      (when line-end
        (delete-region (point-min) (+ line-end 2))))
    (cl-loop for pair in (mapcar (lambda (str) (split-string str "="))
                                 (split-string
                                  (buffer-substring (point-min) (point-max)) "&"))
             do
             (cond
              ((equal (car pair) "oauth_token_secret")
               (setf (oauth-t-token-secret token) (cadr pair)))
              ((equal (car pair) "oauth_token")
               (setf (oauth-t-token token) (cadr pair)))))
    token))

(defun oauth--do-request (req)
  "Make an http request to url using the request object to generate the oauth
headers. Returns the http response buffer."
  (if oauth-use-curl (oauth--do-request-curl req)
    (oauth--do-request-emacs req)))

(defun oauth--do-request-emacs (req)
  "Make an http request to url using the request object to generate the oauth
headers. Returns the http response buffer.

This function uses the emacs function `url-retrieve' for the http connection."
  (let ((url-request-extra-headers (oauth--request-to-header req))
        (url-request-method (oauth-request-method req)))
    (url-retrieve-synchronously (oauth-request-url req))))

(defun oauth--do-request-curl (req)
  "Make an http request to url using the request object to generate the oauth
headers. Returns the http response buffer.

This function dispatches to an external curl process"

  (let ((url-request-extra-headers (oauth--request-to-header req))
        (url-request-method (oauth-request-method req)))
    (oauth--curl-retrieve (oauth-request-url req))))

(defun oauth--headers-to-curl (headers)
  "Converts header alist (like `url-request-extra-headers') to a string that
can be fed to curl"
  (apply
   'append
   (mapcar
    (lambda (header) `("--header"
                       ,(concat (car header) ": " (cdr header)))) headers)))

(defun oauth--curl-retrieve (url)
  "Retrieve via curl"
  (url-gc-dead-buffers)
  (set-buffer (generate-new-buffer " *oauth-request*"))
  (let ((curl-args `("-s" ,(when oauth-curl-insecure "-k")
                     "-X" ,url-request-method
                     "-i" ,url
                     ,@(when oauth-post-vars-alist
                         (apply
                          'append
                          (mapcar
                           (lambda (pair)
                             (list
                              "-d"
                              (concat (car pair) "="
                                      (url-hexify-string (cdr pair)))))
                           oauth-post-vars-alist)))
                     ,@(oauth--headers-to-curl url-request-extra-headers))))
    (apply 'call-process "curl" nil t nil curl-args))
  (url-mark-buffer-as-dead (current-buffer))
  (current-buffer))

(defun oauth--request-to-header (req)
  "Given a requst will return a alist of header pairs. This can
be consumed by `url-request-extra-headers'."
  (let ((params (copy-sequence (oauth-request-params req))))
    (cons
     (cons
      "Authorization"
      (apply 'concat "OAuth realm=\"\""
             (mapcar
              (lambda (pair)
                (format ", %s=\"%s\""
                        (car pair)
                        (url-hexify-string (cdr pair))))
              (sort params
                    (lambda (a b) (string< (car a) (car b))))))) '())))

(provide 'oauth)

;;; oauth.el ends here
