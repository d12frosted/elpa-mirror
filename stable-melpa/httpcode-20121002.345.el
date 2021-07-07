;;; httpcode.el --- explains the meaning of an HTTP status code
;;
;; Copyright (C) 2011  Ruslan Spivak
;;
;; Author: Ruslan Spivak <ruslan.spivak@gmail.com>
;; URL: http://github.com/rspivak/httpcode.el
;; Package-Version: 20121002.345
;; Package-Commit: a45e735082b09477cd704a99294d336cdbeb12ba
;; Version: 0.1
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.
;;
;;; Commentary:
;;
;; Explain the meaning of an HTTP status code. Copy httpcode.el to your
;; load-path and add to your .emacs:
;;
;;   (require 'httpcode)
;;
;; Then run it with M-x hc
;;
;;; Code goes here:

(defconst http-codes
  '((100 ("Continue" "Request received, please continue"))
    (101 ("Switching Protocols"
          "Switching to new protocol; obey Upgrade header"))

   (200 ("OK" "Request fulfilled, document follows"))
   (201 ("Created" "Document created, URL follows"))
   (202 ("Accepted" "Request accepted, processing continues off-line"))
   (203 ("Non-Authoritative Information" "Request fulfilled from cache"))
   (204 ("No Content" "Request fulfilled, nothing follows"))
   (205 ("Reset Content" "Clear input form for further input."))
   (206 ("Partial Content" "Partial content follows."))

   (300 ("Multiple Choices" "Object has several resources -- see URI list"))
   (301 ("Moved Permanently" "Object moved permanently -- see URI list"))
   (302 ("Found" "Object moved temporarily -- see URI list"))
   (303 ("See Other" "Object moved -- see Method and URL list"))
   (304 ("Not Modified" "Document has not changed since given time"))
   (305 ("Use Proxy"
         "You must use proxy specified in Location to access this resource."))
   (307 ("Temporary Redirect" "Object moved temporarily -- see URI list"))

   (400 ("Bad Request" "Bad request syntax or unsupported method"))
   (401 ("Unauthorized" "No permission -- see authorization schemes"))
   (402 ("Payment Required" "No payment -- see charging schemes"))
   (403 ("Forbidden" "Request forbidden -- authorization will not help"))
   (404 ("Not Found" "Nothing matches the given URI"))
   (405 ("Method Not Allowed"
         "Specified method is invalid for this resource."))
   (406 ("Not Acceptable" "URI not available in preferred format."))
   (407 ("Proxy Authentication Required"
         "You must authenticate with this proxy before proceeding."))
   (408 ("Request Timeout" "Request timed out; try again later."))
   (409 ("Conflict" "Request conflict."))
   (410 ("Gone" "URI no longer exists and has been permanently removed."))
   (411 ("Length Required" "Client must specify Content-Length."))
   (412 ("Precondition Failed" "Precondition in headers is false."))
   (413 ("Request Entity Too Large" "Entity is too large."))
   (414 ("Request-URI Too Long" "URI is too long."))
   (415 ("Unsupported Media Type" "Entity body in unsupported format."))
   (416 ("Requested Range Not Satisfiable" "The client has asked for a portion of the file, but the server cannot supply that portion. For example, if the client asked for a part of the file that lies beyond the end of the file."))
   (417 ("Expectation Failed" "Expect condition could not be satisfied."))
   (418 ("I'm a teapot" "The HTCPCP server is a teapot"))
   (420 ("Enhance Your Calm (Twitter)" "Not part of the HTTP standard, but returned by the Twitter Search and Trends API when the client is being rate limited. Other services may wish to implement the 429 Too Many Requests response code instead."))
   (422 ("Unprocessable Entity (WebDAV)" "The request was well-formed but was unable to be followed due to semantic errors"))
   (424 ("Failed Dependency (WebDAV)" "The request failed due to failure of a previous request."))
   (426 ("Precondition Required" "The origin server requires the request to be conditional. Intended to prevent the 'lost update' problem, where a client GETs a resource's state, modifies it, and PUTs it back to the server, when meanwhile a third party has modified the state on the server, leading to a conflict."))
   (429 ("Too Many Requests" "The user has sent too many requests in a given amount of time.\nIntended for use with rate limiting schemes."))
   (431 ("Request Header Fields Too Large" "The server is unwilling to process the request because either an individual header field, or all the header fields collectively, are too large."))

   (500 ("Internal Server Error" "Server got itself in trouble"))
   (501 ("Not Implemented" "Server does not support this operation"))
   (502 ("Bad Gateway" "Invalid responses from another server/proxy."))
   (503 ("Service Unavailable"
         "The server cannot process the request due to a high load"))
   (504 ("Gateway Timeout"
         "The gateway server did not receive a timely response"))
   (505 ("HTTP Version Not Supported" "Cannot fulfill request."))
   (511 ("Network Authentication Required" "The client needs to authenticate to gain network access. Intended for use by intercepting proxies used to control access to the network (e.g. 'captive portals' used to require agreement to Terms of Service before granting full Internet access via a Wi-Fi hotspot)."))
   ))

;;;###autoload
(defun hc (code)
  "Display the meaning of an HTTP status code"
  (interactive "nEnter HTTP code: ")
  (let ((found (assoc code http-codes)))
    (if found
        (let ((description (car (cdr found))))
          (message
           "Status code %d\nMessage: %s\nCode explanation: %s"
           code (car description) (car (cdr description))))
      (message "No description found for code: %d" code))
    ))

(provide 'httpcode)

;;; httpcode.el ends here
