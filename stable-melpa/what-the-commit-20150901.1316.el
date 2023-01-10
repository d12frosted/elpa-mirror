;;; what-the-commit.el --- Random commit message generator

;; Copyright (C) 2015 Free Software Foundation, Inc.
;; Author: Dan Barbarito <dan@barbarito.me>
;; Version: 1.0
;; Keywords: git, commit, message
;; URL: http://barbarito.me/
;; Created: 30th August 2015

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

;; This package gets a random commit message from "whatthecommit.com"
;; and adds it to your kill ring

;;; Code:

(defvar url-http-end-of-headers)

(defconst what-the-commit-url "http://whatthecommit.com/index.txt"
  "URL from which to get commit messages.")

(defun what-the-commit--extract-message ()
  "Extract the commit message from the current buffer."
  (goto-char (point-min))
  (goto-char url-http-end-of-headers)
  (forward-line 1)
  (unwind-protect
      (buffer-substring-no-properties (point) (point-max))
    (kill-buffer)))

;;;###autoload
(defun what-the-commit-insert ()
  "Insert a random message from whatthecommit.com at point."
  (interactive)
  (let* ((url-request-method "GET")
         (message (with-current-buffer
                      (url-retrieve-synchronously what-the-commit-url)
                    (what-the-commit--extract-message))))
    (insert message)))

;;;###autoload
(defun what-the-commit ()
  "Add a random commit message from whatthecommit.com to the kill ring."
  (interactive)
  (let ((url-request-method "GET"))
    (url-retrieve what-the-commit-url
                  (lambda (_status)
                    (kill-new (what-the-commit--extract-message))
                    (message "Commit message generated!")))))

(provide 'what-the-commit)
;;; what-the-commit.el ends here
