;;; gitlab-snip-helm.el --- Gitlab snippets api helm package                  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Fermin Munoz

;; Author: Fermin MF <fmfs@posteo.net>
;; Created: 13 Abril 2020
;; Version: 0.0.2
;; Package-Version: 20200427.2014
;; Package-Commit: 782df679e33646db29e07508311bc8e8624b484e
;; Keywords: tools,files,convenience

;; URL: https://gitlab.com/sasanidas/gitlab-snip-helm
;; Package-Requires: ((emacs "25") (dash "2.12.0") (helm "3.2"))
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package manage gitlab snippets with the help of the helm framework.

;;; Code:

(require 'dash)
(require 'helm)
(require 'json)

(defgroup gitlab-snip-helm nil
  "Basic IDE group declaration"
  :prefix "gitlan-snip-helm-"
  :group 'development)

(defcustom gitlab-snip-helm-user-token ""
  "This is the API required token.
https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html."
  :group 'gitlab-snip-helm
  :type 'string)

(defcustom gitlab-snip-helm-visibility "public"
  "Snippets visibility."
  :group 'gitlab-snip-helm
  :type '(choice (const :tag "Snippet can be accessed without any authentication." "public")
		 (const :tag "Snippet is visible for any logged in user." "internal")
		 (const :tag "Snippet is visible only to the snippet creator." "private")))

(defcustom gitlab-snip-helm-server "https://gitlab.com"
  "Gitlab server to save the snippets."
  :group 'gitlab-snip-helm
  :type 'string)



(defun gitlab-snip-helm-save ()
  "Create a snippet from the region.
Send it to the GitLab server at `gitlab-snip-helm-server'."
  (interactive)
  (let* ((snippet--name (read-from-minibuffer "Insert snippet name: "))
	 (snippet--description (read-from-minibuffer "Insert the snippet description: "))
	 (snippet--text
	  (json-encode (let* ((pos1 (region-beginning)) (pos2 (region-end)))(filter-buffer-substring pos1 pos2)))))
    (let
	((url-request-method "POST")
	 (url-request-extra-headers
	  (list (cons "Content-Type"  "application/json")
		(cons "Private-Token"  gitlab-snip-helm-user-token)))
	 (url-request-data (concat
			    "{\"title\": \"" snippet--name " \",
                         \"content\": "snippet--text",
                         \"description\": \"" snippet--description"\",
                         \"file_name\": \"" (buffer-name) "\",
                         \"visibility\": \""gitlab-snip-helm-visibility"\" }")))
      (url-retrieve-synchronously (concat gitlab-snip-helm-server "/api/v4/snippets")))))


(defun gitlab-snip-helm--action-insert (snippet-id)
  "Insert the selected snippet in the current buffer.
It requires SNIPPET-ID as parameter."
  (with-current-buffer (let
			   ((url-request-extra-headers
			     (list (cons "Private-Token" gitlab-snip-helm-user-token))))
			 (url-retrieve-synchronously (concat gitlab-snip-helm-server "/api/v4/snippets/" snippet-id "/raw")))
    (goto-char (point-min))
    (re-search-forward "^$")
    (delete-region (point) (point-min))
    (buffer-string)))

(defun gitlab-snip-helm--action-get-snippets ()
  "Get all the user snippets."
  (with-current-buffer
      (let
	  ((url-request-extra-headers
	    (list (cons "Private-Token" gitlab-snip-helm-user-token))))
	(url-retrieve-synchronously (concat gitlab-snip-helm-server "/api/v4/snippets")))
    (json-read)))

(defun gitlab-snip-helm-insert ()
  "Insert the selected snippet in the current buffer."
  (interactive)
  (let* ((helm-source-user-snippets
	  (helm-build-sync-source "gitlab-snip"
	    :candidates (-map (lambda (x)
				(cdr (nth 1 x)))
			      (gitlab-snip-helm--action-get-snippets))
	    :action '(("Insert" . (lambda (selected) (insert (let*
								 ((snippet--id (car
										(-non-nil
										 (-map (lambda (x)
											 (if (string-equal selected (cdr (nth 1 x)) )
											     (number-to-string (cdr (nth 0 x)))))
										       (gitlab-snip-helm--action-get-snippets))))))
							       (gitlab-snip-helm--action-insert snippet--id)))))))))
    (helm :sources (list  helm-source-user-snippets)
	  :buffer "*helm gitlab-snip*")))

(provide 'gitlab-snip-helm)
;;; gitlab-snip-helm.el ends here
