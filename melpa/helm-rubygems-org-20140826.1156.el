;;; helm-rubygems-org.el --- Use helm to search rubygems.org -*- lexical-binding: t -*-

;; Copyright (C) 2014 Chad Albers

;; Author: Chad Albers <calbers@neomantic.com>
;; Maintainer: Chad Albers <calbers@neomantic.com>
;; URL: https://github.com/neomantic/helm-rubygems-org
;; Created: 25th August 2014
;; Version: 0.0.1
;; Keywords: ruby, rubygems, gemfile, helm
;; Package-Requires: ((emacs "24") (helm "1.6.3") (cl-lib "0.5"))

;; This file is NOT part of GNU Emacs.

;;; License:

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
;; A helm interface to rubygems.org
;;
;; Requirements:
;; * The helm package - https://github.com/emacs-helm/helm
;; * A rubygems.org account and the account's API key
;;
;; Setup:
;; API Key management.  Choose one of the three.
;; * Store the rubygems.org API key in its recommended YAML file
;;   at ~.gem/credentials
;; * Add the key to the helm-rubygems-org customization group
;; * setq helm-rubygems-org-api-key to the key or file path
;;
;; Usage:
;; M-x helm-rubygems-org, and then type gem name
;;
;; Wait for rubygems.org response...it is sometimes slow.
;;
;; Select the gem in the helm list, and press return to save
;; a Gemfile compatible string to the kill ring; e.g.,
;; "gem guard-rackunit, '~> 1.0.0'".  Or press the tab key and see
;; a list of other helm actions

;; Detailed documentation can be found here:
;; https://github.com/neomantic/helm-rubygems-org
;;
;;; Code:

(require 'helm)
(require 'json)
(require 'url)
(require 'cl-lib)

(defgroup helm-rubygems-org nil
  "Customizations for search online for rubygems"
  :group 'helm)

(defcustom helm-rubygems-org-api-key "~/.gem/credentials"
  "The API Key file or key value issued by rubygems.org."
  :group 'helm-rubygems-org
  :type '(choice (file   :tag "Rubygems.org credential file: ~/.gem/credentials")
		 (string :tag "API Key")))

(defun helm-rubygems-org-candidate-view (gem-candidate)
  "Given a deserialized JSON gem representation GEM-CANDIDATE, show a description of the gem in a new buffer."
  (let* ((name (rubygems-org-gem-descriptor 'name gem-candidate))
	 (buffer-name
	  (format "*rubygems.org: %s*" name)))
    (if (get-buffer buffer-name)
	(switch-to-buffer buffer-name)
      (progn
	(generate-new-buffer buffer-name)
	(with-current-buffer
	    buffer-name
	  (insert (format "%s %s" name
			  (rubygems-org-gem-descriptor 'version gem-candidate)))
	  (newline 2)
	  (insert (rubygems-org-gem-descriptor 'info gem-candidate))
	  (fill-paragraph)
	  (newline 2)
	  (insert "Click to copy to kill ring: ")
	  (insert-button (rubygems-org-candidate-gemfile-format gem-candidate)
			 'action (lambda (button)
				   (helm-rubygems-org-candidate-to-kill-ring gem-candidate))
			 'follow-link t
			 'point (point)
			 'buffer (current-buffer))
	  (newline 2)
	  (cl-loop for link-pair in
		   '(("Project Page" . project_uri)
		     ("Homepage" . homepage_uri)
		     ("Source Code" . source_code_uri))
		   do
		   (let ((uri (rubygems-org-gem-descriptor (cdr link-pair) gem-candidate)))
		     (if uri
			 (progn
			   (insert-button (car link-pair)
					  'action (lambda (button)
						    (helm-browse-url uri))
					  'follow-link t
					  'point (point)
					  'buffer (current-buffer))
			   (insert "  ")))))
	  (setq buffer-read-only t))
	(switch-to-buffer buffer-name)))))

(defun rubygems-org-search (search-term api-key)
  "Given the string SEARCH-TERM and the API-KEY, return a parsed JSON list of results."
  (cl-flet ((get-page (page-number)
		      (with-current-buffer
			  (let ((url-mime-accept-string  "application/json")
				(url-request-extra-headers
				 (list (cons "Authorization" api-key))))
			    (url-retrieve-synchronously
			     (concat "https://rubygems.org/api/v1/"
				     (format "search?query=%s&page=%d"
					     (url-hexify-string search-term) page-number))))
			(goto-char (+ 1 url-http-end-of-headers))
			(json-read))))
    (cl-loop for page-number from 1 to 3
	     for candidates = (get-page page-number)
	     until (eq (length candidates) 0)
	     append (mapcar (lambda (candidate)
			      candidate)
			    candidates))))

(defun rubygems-org-gem-descriptor (descriptor gem-candidate)
  "Return the value descriptor by the DESCRIPTOR symbol for parsed rubygems.org resource representation GEM-CANDIDATE."
  (let ((descriptor-cell (assoc descriptor gem-candidate)))
    (if descriptor-cell
	(cdr descriptor-cell)
      nil)))

(defun rubygems-org-candidate-gemfile-format (gem-candidate)
  "Given a GEM-CANDIDATE (deserialized JSON representation), return a string suitable for inclusion in a Gemfile; gem '<gem name>', '~> <version>'."
  (format "gem '%s', '~> %s'"
	  (rubygems-org-gem-descriptor 'name gem-candidate)
	  (rubygems-org-gem-descriptor 'version gem-candidate)))

(defun helm-rubygems-org-candidate-to-kill-ring (gem-candidate)
  "Given a GEM-CANDIDATE (deserialized JSON representation), populates the `kill-ring' with a string suitable for including an a Gemfile."
  (let ((formatted (rubygems-org-candidate-gemfile-format gem-candidate)))
    (kill-new formatted)
    (message formatted)))

(defun helm-rubygems-org-candidate-browse-to-project (gem-candidate)
  "Opens a browser to project_uri of the GEM-CANDIDATE."
  (helm-browse-url
   (rubygems-org-gem-descriptor 'project_uri gem-candidate)))

(defun helm-rubygems-org-candidate-browse-to-source (gem-candidate)
  "Opens a browser to source_code_uri of then GEM-CANDIDATE."
  (let ((source-code-uri (rubygems-org-gem-descriptor
			  'source_code_uri gem-candidate)))
    (if source-code-uri
	(helm-browse-url source-code-uri)
      (helm-rubygems-org-candidate-browse-to-project gem-candidate))))

(defun helm-rubygems-org-api-key-derive (key-or-file)
  "Return API key used to authenticate requests, given KEY-OR-FILE - a string or a path to the rubygems.org YAML credentials file."
  (cond
   ((eq key-or-file nil)
    (error "Missing rubygems API key; please customize group helm-rubygems-org"))
   ((file-exists-p key-or-file)
    (if (file-readable-p key-or-file)
	(with-temp-buffer
	  (insert-file-contents key-or-file)
	  (forward-line)
	  (let ((data-line (buffer-string)))
	    (if (eq (string-match ":rubygems_api_key: \\([a-z1-9]+\\)" data-line) nil)
		(error "Unable to detect API key in %s" key-or-file)
	      (match-string 1 data-line))))
      (error "The file %s is not readable" key-or-file)))
   ((and (char-or-string-p key-or-file) ;; if it looks like an API key
	 (eq (length key-or-file) 32)
	 (eq (string-match "[a-z1-9]+" key-or-file) 0))
    key-or-file)
   (t
    (error "Missing rubygems API key; please customize group helm-rubygems-org"))))

(defun helm-rubygems-org-search ()
  "Return a list of gem candidates suitable for helm."
  (mapcar (lambda (gem-candidate)
	    (cons (format "%s ~> %s"
			  (rubygems-org-gem-descriptor 'name gem-candidate)
			  (rubygems-org-gem-descriptor 'version gem-candidate))
		  gem-candidate))
	  (rubygems-org-search
	   helm-pattern
	   (helm-rubygems-org-api-key-derive helm-rubygems-org-api-key))))

;;;###autoload
(defvar helm-rubygems-org-search-source
  '((name . "Rubygems.org")
    (candidates . helm-rubygems-org-search)
    (volatile)
    (delayed)
    (requires-pattern . 2)
    (action . (("Copy Gemfile require" .       helm-rubygems-org-candidate-to-kill-ring)
	       ("View Description" .           helm-rubygems-org-candidate-view)
	       ("Browse source code project" . helm-rubygems-org-candidate-browse-to-source)
	       ("Browse on rubygems.org" .     helm-rubygems-org-candidate-browse-to-project)))))

;;;###autoload
(defun helm-rubygems-org ()
  "List Rubygems."
  (interactive)
  (helm :sources 'helm-rubygems-org-search-source :buffer "*helm-rubygems*"))

(provide 'helm-rubygems-org)
;;; helm-rubygems-org.el ends here
