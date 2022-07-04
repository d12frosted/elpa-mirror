;;; twtxt.el --- A twtxt client for Emacs

;; SPDX-License-Identifier: GPL-3.0

;; Author: DEADBLACKCLOVER <deadblackclover@protonmail.com>
;; Version: 0.1
;; Package-Version: 20220628.309
;; Package-Commit: eb9efa19086fcae343353f6a5e88c3377fd06dd4
;; URL: https://github.com/deadblackclover/twtxt-el
;; Package-Requires: ((emacs "25.1") (request "0.2.0"))

;; Copyright (c) 2020, DEADBLACKCLOVER.

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; twtxt is a decentralised, minimalist microblogging service for hackers.

;; You want to get some thoughts out on the internet in a convenient and
;; slick way while also following the gibberish of others? Instead of
;; signing up at a closed and/or regulated microblogging platform, getting
;; your status updates out with twtxt is as easy as putting them in a
;; publicly accessible text file.  The URL pointing to this file is your
;; identity, your account.  twtxt then tracks these text files, like a
;; feedreader, and builds your unique timeline out of them, depending on
;; which files you track.  The format is simple, human readable, and
;; integrates well with UNIX command line utilities.

;; Usage:
;; View your timeline `M-x twtxt-timeline`
;; Post a status update `M-x twtxt-post`

;;; Code:
(require 'cl-lib)
(require 'request)

(defgroup twtxt nil
  "A twtxt client for Emacs."
  :group 'twtxt)

(defcustom twtxt-file "~/twtxt"
  "Path to twtxt file."
  :type 'file
  :group 'twtxt)

(defcustom twtxt-following nil
  "Following list."
  :type '(repeat (list (string :tag "Name")
		       (string :tag "URL")))
  :group 'twtxt)

(defvar twtxt-timeline-list nil
  "Timeline list.")

(defvar twtxt-username ""
  "Temporary storage of username.")

(defun twtxt-get-datetime ()
  "Getting date and time according to RFC 3339 standard."
  (concat (format-time-string "%Y-%m-%dT%T")
	  ((lambda (x)
	     (concat (substring x 0 3) ":" (substring x 3 5)))
	   (format-time-string "%z"))))

(defun twtxt-parse-text (text)
  "Convert TEXT to list post."
  (split-string text "\n"))

(defun twtxt-replace-tab (str)
  "Replacing tabs with line breaks in STR."
  (replace-regexp-in-string "\t" "\n" str))

(defun twtxt-sort-post (list)
  "Sorting posts in LIST."
  (sort list #'string>))

(defun twtxt-append-username (text)
  "Append username in TEXT."
  (mapcar (lambda (item)
	    (concat twtxt-username "\t" item))
	  (twtxt-parse-text text)))

(defun twtxt-push-text (text)
  "Concatenate the resulting TEXT with the current list."
  (setq twtxt-timeline-list (append twtxt-timeline-list (twtxt-append-username text))))

(defun twtxt-fetch (url)
  "Getting text by URL."
  (progn (request url
	   :parser 'buffer-string
	   :success (cl-function (lambda
				   (&key
				    data
				    &allow-other-keys)
				   (twtxt-push-text data))))))

(defun twtxt-fetch-list ()
  "Getting a list of texts."
  (mapc (lambda (item)
	  (setq twtxt-username (concat "[[" (car (cdr item)) "][" (car item) "]]"))
	  (twtxt-fetch (car (cdr item)))) twtxt-following))

(defun twtxt-timeline-buffer (data)
  "Create buffer and DATA recording."
  (switch-to-buffer (get-buffer-create "*twtxt-timeline*"))
  (mapc (lambda (item)
	  (insert (twtxt-replace-tab item))
	  (insert "\n\n")) data)
  (org-mode)
  (goto-char (point-min)))

(defun twtxt-timeline ()
  "View your timeline."
  (interactive)
  (twtxt-fetch-list)
  (twtxt-timeline-buffer (twtxt-sort-post twtxt-timeline-list))
  (setq twtxt-timeline-list nil))

(defun twtxt-post (post)
  "POST a status update."
  (interactive "sPost:")
  (append-to-file (concat (twtxt-get-datetime) "\t" post "\n") nil twtxt-file))

(provide 'twtxt)
;;; twtxt.el ends here
