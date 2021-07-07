;;; github-search.el --- Clone repositories by searching github

;; Copyright (C) 2016 Ivan Malison

;; Author: Ivan Malison <IvanMalison@gmail.com>
;; Keywords: github search clone api gh magit vc tools
;; Package-Version: 20190624.436
;; Package-Commit: b73efaf19491010522b09db35bb0f1bad1620e63
;; URL: https://github.com/IvanMalison/github-search
;; Version: 0.0.1
;; Package-Requires: ((magit "0.8.1") (gh "1.0.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides functions to clone github repositories that
;; are selected from queries to the github search api.

;;; Code:
(require 'gh-search)
(require 'magit-remote)
(require 'cl-lib)

(defvar github-search-repo-format-function 'github-search-string-for-repo)
(defvar github-search-user-format-function 'github-search-string-for-user)
(defvar github-search-get-clone-url-function 'github-search-get-clone-url)
(defvar github-search-get-target-directory-for-repo-function
  'github-search-prompt-for-target-directory)
(defvar github-search-clone-repository-function
  'github-search-default-clone-repository-function)
(defvar github-search-page-limit 1)

(defun github-search-default-clone-repository-function (repo directory)
  (magit-clone-regular repo directory nil))

(defun github-search-format-repository (repo)
  (cons (funcall github-search-repo-format-function repo) repo))

(defun github-search-format-user (user)
  (cons (funcall github-search-user-format-function user) user))

(defun github-search-for-completion (search-string &optional page-limit)
  (let* ((search-api (make-instance gh-search-api))
         (search-response (gh-search-repos search-api search-string page-limit))
         (repos (oref search-response :data)))
    (mapcar 'github-search-format-repository repos)))

(defun github-search-users-for-completion (search-string &optional page-limit)
  (let* ((search-api (make-instance gh-search-api))
         (search-response (gh-search-users search-api search-string page-limit))
         (users (oref search-response :data)))
    (mapcar 'github-search-format-user users)))

(defun github-search-get-repos-from-user-for-completion (user)
  (let* ((repo-api (make-instance gh-repos-api))
         (repo-response (gh-repos-user-list repo-api (oref user :login)))
         (repos (oref repo-response :data)))
    (mapcar 'github-search-format-repository repos)))

(defun github-search-string-for-repo (repository)
  (let ((owner (oref repository :owner)))
    (format "%s/%s"
            (if owner (oref owner :login) "owner-not-found")
            (oref repository :name))))

(defun github-search-string-for-user (user)
  (oref user :login))

(defun github-search-get-clone-url (repository)
  (oref repo :ssh-url))

(defun github-search-select-user-from-search-string (search-string)
  (github-search-select-candidate "Select a user: "
   (github-search-users-for-completion search-string github-search-page-limit)))

(defun github-search-select-candidate (prompt candidates)
  (let ((selection (completing-read prompt candidates)))
    (cdr (assoc selection candidates))))

(defun github-search-prompt-for-target-directory (repo)
  (let* ((remote-url (funcall github-search-get-clone-url-function repo))
         (input-target (read-directory-name
                        "Clone to: " nil nil nil
                        (and (string-match "\\([^./]+\\)\\(\\.git\\)?$" remote-url)
                             (match-string 1 remote-url)))))
    (if (file-exists-p input-target) (concat input-target (oref repo :name))
      input-target)))

(defun github-search-get-target-directory-for-repo (repo)
  (funcall github-search-get-target-directory-for-repo-function repo))

(defun github-search-select-and-clone-repo-from-repos (repos-for-completion)
  (github-search-do-repo-clone
   (github-search-select-candidate "Select a repo: " repos-for-completion)))

(defun github-search-do-repo-clone (repo)
  (let ((remote-url (funcall github-search-get-clone-url-function repo))
		(target-directory (github-search-get-target-directory-for-repo repo)))
    (funcall github-search-clone-repository-function remote-url target-directory)))

;;;###autoload
(defun github-search-user-clone-repo (search-string)
  "Query github using SEARCH-STRING and clone the selected repository."
  (interactive
   (list (read-from-minibuffer "Enter a github user search string: ")))
  (let* ((user (github-search-select-user-from-search-string search-string))
         (user-repos (github-search-get-repos-from-user-for-completion user)))
    (github-search-select-and-clone-repo-from-repos user-repos)))

;;;###autoload
(defun github-search-clone-repo (search-string)
  "Query github using SEARCH-STRING and clone the selected repository."
  (interactive
   (list (read-from-minibuffer "Enter a github search string: ")))
  (let* ((repos (github-search-for-completion search-string
                                              github-search-page-limit)))
    (github-search-select-and-clone-repo-from-repos repos)))

(provide 'github-search)
;;; github-search.el ends here
