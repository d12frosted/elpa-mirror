;;; org-present-remote.el --- A web-based remote control for org-present  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Duncan Bayne

;; Author: Duncan Bayne <duncan@bayne.id.au>
;; Package-Version: 20191206.533
;; Package-X-Original-Version: 0.1
;; Package-Requires: ((org-present "9") (elnode "0.9") (emacs "25"))
;; Package-Commit: dc3be74c544efc4723f5f64f54b4c74b523f0bbd
;; URL: https://gitlab.com/duncan-bayne/org-present-remote
;; Keywords: comm, docs

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; ;; org-present-remote adds a simple, mobile-friendly web remote
;; control for moving between slides in
;; [[https://github.com/rlister/org-present][org-present]].

;;; Code:

(require 'elnode)
(require 'org-present)

;;; Code:

(add-hook 'org-present-after-navigate-functions 'org-present-remote--remote-set-title)

;; the HTML displayed in the remote control web page
(defvar org-present-remote--html-template
  "<!doctype html>
   <html lang='en-AU'>
     <head>
       <meta charset='utf-8' />
       <title>%s</title> <!-- presentation name -->
       <style>
         h1 {
           font-size: 9vmin;
         }
         h2 {
           font-size: 7vmin;
         }
         body {
           font-size: 5vmin;
         }
         .next {
           float: right;
         }
         .prev {
           float: left;
         }
         .logo {
           text-align: center;
         }
         .next, .prev {
           font-size: 12vmin;
         }
         img.icon {
           height: 160px;
         }
       </style>
     </head>
     <body>
       <div class='next'><a href='/next'>Next</a></div>
       <div class='prev'><a href='/prev'>Prev</a></div>
       <div class='logo'><a href='http://orgmode.org/'><img class='icon' src='http://orgmode.org/img/org-mode-unicorn-logo.png' alt='org-mode' /></a></div>
       <hr>
       <h1>%s</h1> <!-- presentation name -->
       <h2>%s</h2> <!-- slide title -->
     </body>
   </html>")

;; the buffer used by the remote
(defvar org-present-remote--remote-buffer)

;; the title of the remote page
(defvar org-present-remote--remote-title "UNKNOWN")

;; which remote control routes should be hooked up to which handlers
(defvar org-present-remote--routes
  '(("^.*//prev$" . org-present-remote--prev-handler)
    ("^.*//next$" . org-present-remote--next-handler)
    ("^.*//$" . org-present-remote--default-handler)))

(defun org-present-remote--html ()
  "Build the page HTML from the template and selected variables."
  (format org-present-remote--html-template
          (org-present-remote--html-escape (buffer-name org-present-remote--remote-buffer))
          (org-present-remote--html-escape (buffer-name org-present-remote--remote-buffer))
          (org-present-remote--html-escape org-present-remote--remote-title)))

(defun org-present-remote--prev-handler (httpcon)
  "Call ‘org-present-prev’ when someone GETs /prev.

HTTPCON is the HTTP connection used to request the move to
previous.

Returns the remote control page, updated with the correct
heading."
  (with-current-buffer org-present-remote--remote-buffer (org-present-prev))
  (elnode-http-start httpcon 200 '("Content-type" . "text/html"))
  (elnode-http-return httpcon (org-present-remote--html)))

(defun org-present-remote--next-handler (httpcon)
  "Call ‘org-present-next’ when someone GETs /next.

HTTPCON is the HTTP connection used to request the move to
next.

Returns the remote control page, updated with the correct
heading."
  (with-current-buffer org-present-remote--remote-buffer (org-present-next))
  (elnode-http-start httpcon 200 '("Content-type" . "text/html"))
  (elnode-http-return httpcon (org-present-remote--html)))

(defun org-present-remote--default-handler (httpcon)
  "Return the remote control page when someone gets /.

HTTPCON is the HTTP connection used to request the remote control page."
  (elnode-http-start httpcon 200 '("Content-type" . "text/html"))
  (elnode-http-return httpcon (org-present-remote--html)))

(defun org-present-remote--root-handler (httpcon)
  "Create a dispatcher using org-present-remote routes.

HTTPCON is the HTTP connection used by the request."
  (elnode-hostpath-dispatcher httpcon org-present-remote--routes))

(defun org-present-remote--html-escape (str)
  "Escape significant HTML characters in 'str'.

STR is the string to escape.

Shamelessly lifted from https://github.com/nicferrier/elnode/blob/master/examples/org-present.el"
  (replace-regexp-in-string
   "<\\|\\&"
   (lambda (src)
     (cond
      ((equal src "&") "&amp;")
      ((equal src "<")  "&lt;")))
   str))

(defun org-present-remote--remote-set-title (name heading)
  "Set the title to display in the remote control.

NAME is the name of the presentation buffer.
HEADING is the current heading within that buffer."
  (setq org-present-remote--remote-title heading))

(defun org-present-remote--remote-on (host)
  "Turn the presentation remote control on.

HOST is the host to which to bind (e.g. \"localhost\")"
  (interactive "sStart remote control for this buffer on host: ")
  (setq elnode-error-log-to-messages nil)
  (elnode-stop 8009)
  (setq org-present-remote--remote-buffer (current-buffer))

  (unless (boundp 'org-present-after-navigate-functions)
    (error "Abnormal hook org-present-after-navigate-functions is not bound.  Are you using a recent build of org-present?"))

  (elnode-start 'org-present-remote--root-handler :port 8009 :host host))

(defun org-present-remote--remote-off ()
  "Turn the presentation remote control off."
  (interactive)
  (elnode-stop 8009)
  (setq org-present-remote--remote-buffer nil))

(provide 'org-present-remote)
;;; org-present-remote.el ends here
