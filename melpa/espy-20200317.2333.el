;;; espy.el --- Emacs Simple Password Yielder -*- lexical-binding: t -*-

;; Author: Sebastian Wålinder <s.walinder@gmail.com>
;; URL: https://github.com/walseb/espy
;; Package-Version: 20200317.2333
;; Package-Commit: 2c01be937a5e5bde62921684a0b27300705fb4e0
;; Version: 1.0
;; Package-Requires: ((emacs "24"))
;; Keywords: convenience

;; espy.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; espy.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To espy is to see something at a distance which is what this package is about.
;; This package allows users to fetch a  user and password from a file
;; without visiting it. It gathers all headers containing passwords or
;; usernames as defined by `espy-header-prefix' and `espy-pass-prefix' and
;; presents them to the user. The choosen password gets added to the kill ring.
;;
;; For example using a file with the content of
;; (with no whitespace before any prefix)
;;
;;    *** Header1
;;    user: User1
;;    pass: Password1
;;
;; and running
;;
;;    (espy-get-pass)
;;
;; would result in one entry `Header1' being selectable. Choosing this entry
;; would result in `Password1' being copied to the kill-ring

;;; Code:

(defgroup espy nil
  "Emacs Simple Password Yielder"
  :group 'tools
  :link '(url-link "https://github.com/walseb/espy"))

(defcustom espy-clipboard-command nil
  "If non-nil,  run `espy-clipboard-command' on espy-get results.

If nil, copy espy-get results to killring.
Espy runs the command as a standard shell command in this order:
`espy-clipboard-command' + password-or-user-string"
  :group 'espy)

(defcustom espy-password-file "~/password.org.gpg"
  "The file to pull passwords from."
  :group 'espy)

(defcustom espy-header-prefix "*"
  "A single letter string prefixing password headings.

Expected to be in beginning of line and repeated 1 or more times before a
whitespace followed by a password or username in the password file."
  :group 'espy
  :type 'regexp)

(defcustom espy-user-prefix "user:"
  "A string prefixing passwords.

Expected to be in beginning of line"
  :group 'espy
  :type 'regexp)

(defcustom espy-pass-prefix "pass:"
  "A string prefixing passwords.

Expected to be in beginning of line"
  :group 'espy
  :type 'regexp)


(defun espy-get-headers-with-content (content-prefix)
  "Fetches all headers containing a password in a file.

CONTENT-PREFIX is the prefix expect before content."
  (with-temp-buffer
    (insert-file-contents espy-password-file)
    (goto-char (point-min))
    ;; Search for user selected header
    (let* ((found-headers (list)))
      (while
	  (ignore-errors
	    ;; Go to next header in case last header had more than 1 password
	    (re-search-forward (concat "^" espy-header-prefix "+\s"))
	    (re-search-forward (concat "^" content-prefix))
	    (re-search-backward (concat "^" espy-header-prefix "+\s"))
	    ;; Search-backward puts the cursor at column position 0, fix this
	    (re-search-forward "\s"))
	;; Push header string to list
	(push (buffer-substring-no-properties (point) (line-end-position)) found-headers))
      found-headers)))

(defun espy-get-content (prompt-string content-prefix)
  "Scans `espy-password-file' and prompts user for all headers with content.

Content is defined by text beginning with CONTENT-PREFIX and ending in the heading name.
`PROMPT-STRING' is displayed among prompt.
After the user has selected a entry it is copied to the kill ring
or a command is run on it as defined by `espy-clipboard-command'."
  (with-temp-buffer
    (insert-file-contents espy-password-file)
    (goto-char (point-min))
    ;; Go to selected heading
    (re-search-forward
     (concat espy-header-prefix " "
	     (completing-read prompt-string (espy-get-headers-with-content content-prefix))
	     "$"))
    ;; Go to heading password
    (re-search-forward (concat "^" content-prefix "\s"))
    (buffer-substring-no-properties (point) (line-end-position))))

;;;###autoload
(defun espy-get-user ()
  "Prompts user for user name to copy to killring."
  (interactive)
  (if espy-clipboard-command
      (shell-command (concat espy-clipboard-command (espy-get-content "Get user: " espy-user-prefix)))
    (kill-new (espy-get-content "Get user: " espy-user-prefix))))

;;;###autoload
(defun espy-get-pass ()
  "Prompts user for password to copy to killring."
  (interactive)
  (if espy-clipboard-command
      (shell-command (concat espy-clipboard-command (espy-get-content "Get password: " espy-pass-prefix)))
    (kill-new (espy-get-content "Get password: " espy-pass-prefix))))

(provide 'espy)

;;; espy.el ends here
