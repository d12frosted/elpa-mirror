;;; org-unique-id.el --- Create unique IDs for org headers -*- lexical-binding: t -*-

;; Author: Lucien Cartier-Tilet <lucien@phundrak.com>
;; Maintainer: Lucien Cartier-Tilet <lucien@phundrak.com>
;; Version: 0.4.1
;; Package-Version: 20220907.821
;; Package-Commit: c3a0908ff2123c8786735f3c6f35e905efea2ef6
;; Package-Requires: ((emacs "25.1") (org "9.3"))
;; Homepage: https://labs.phundrak.com/phundrak/org-unique-id
;; Keywords: convenience


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
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

;; org-unique-id is a utility package for org-mode users that are
;; tired dealing with random org IDs for their headers’ anchor that
;; change on each org to HTML exports among others.  This package
;; creates meaningful custom IDs for org headers that won’t change
;; unless the user modifies or removes them manually.
;;
;; In order to be enabled, this package’s `org-unique-id-maybe'
;; function must be hooked to `before-save-hook', and the string
;; \\='unique-id:t\\=' must be present in an \\='#+OPTIONS:\\=' line
;; in the buffer.
;;
;; If the \\='unique-id:t\\=' string is found, then it will create a
;; slug of the current header (and if there are, its parent headers)
;; and it will add a unique string suffix generated with a UUID
;; generator to ensure all IDs are unique.
;;
;; Here is an example of an org-mode file without the
;; \\='unique-id:t\\=' option after save:
;;
;;     #+title: Test file
;;     * Test level 1
;;     ** Test level 2
;;     * Test level 1
;;
;; And here is the same org-mode file but with the option atop its
;; content:
;;
;;     ,#+title: Test file
;;     ,#+options: unique-id:t
;;     ,* Test level 1
;;     :PROPERTIES:
;;     :CUSTOM_ID: Test-level-1-zmb40t305kj0
;;     :END:
;;     ,** Test level 2
;;     :PROPERTIES:
;;     :CUSTOM_ID: Test-level-1-Test-level-2-spn40t305kj0
;;     :END:
;;     ,* Test level 1
;;     :PROPERTIES:
;;     :CUSTOM_ID: Test-level-1-1nx40t305kj0
;;     :END:
;;
;; Of course the last part of the custom ID might differ for you, but
;; once it is generated, org-unique-id will not modify it or
;; regenerate it unless you delete it yourself, hence ensuring a
;; constant ID for your org exports.

;;; Code:

(require 'org-id)
(require 'message)

(defgroup org-unique-id ()
  "Create unique IDs for org headers."
  :group 'org
  :prefix "org-unique-id"
  :link '(url-link :tag "Gitea" "https://labs.phundrak.com/phundrak/org-unique-id")
  :link '(url-link :tag "Github" "https://github.com/Phundrak/org-unique-id"))

(defcustom org-unique-id-prefix ""
  "Prefix for your org IDs."
  :group 'org-unique-id
  :type  'string
  :safe  #'stringp)

(defun org-unique-id--new (&optional prefix)
  "Create a new globally unique ID.

An ID consists of two parts separated by a colon:
- a prefix
- a unique part which will be created according to `org-id-method'.

PREFIX can specify the prefix we want, the default is given by
the variable `org-unique-id-prefix'."
  (let* ((prefix (if prefix
                     prefix
                   org-unique-id-prefix))
         (etime (org-reverse-string (org-id-time-to-b36)))
         (postfix (if org-id-include-domain
                      (concat "@" (message-make-fqdn))
                    "")))
    (concat prefix "-" (car (split-string (concat etime postfix) "-")))))

;;;###autoload
(defun org-unique-id-get (&optional pom create prefix)
  "Get the CUSTOM_ID property of the entry at point-or-marker POM.

If POM is nil, refer to the entry at point.  If the entry does
not have an CUSTOM_ID, the function returns nil.  However, when
CREATE is non nil, create a CUSTOM_ID if none is present already.
PREFIX will be passed through to `org-unique-id--new'.  In any
case, the CUSTOM_ID of the entry is returned."
  (interactive)
  (org-with-point-at pom
    (let* ((orgpath (mapconcat #'identity (org-get-outline-path) "-"))
           ;; Get heading text
           (heading (if (string-empty-p orgpath)
                        (org-get-heading t t t t)
                      (concat orgpath "-" (org-get-heading t t t t))))
           ;; Remove non-alphanum, hyphens, and underscore
           (heading (replace-regexp-in-string "[^[:alnum:]\\-_]" ""  heading))
           ;; Replace repeated dashes or underscores with a single dash
           (heading (replace-regexp-in-string "[_-]+"            "-" heading))
           ;; Remove leading and trailing dashes and underscores
           (heading (replace-regexp-in-string "^[_-]+\\|[_-]+$"  ""  heading))

           (id (org-entry-get nil "CUSTOM_ID")))
      (cond
       ((and id
             (stringp id)
             (string-match "\\S-" id)) id)
       (create (setq id (org-unique-id--new (concat prefix heading)))
               (org-entry-put pom "CUSTOM_ID" id)
               (org-id-add-location id
                                    (buffer-file-name (buffer-base-buffer)))
               id)))))

;;;###autoload
(defun org-unique-id ()
  "Add a CUSTOM_ID to all headers missing one.

Only adds ids if the \\='unique-id\\=' option is set to t in the
file somewhere, i.e. #+OPTIONS: unique-id:t"
  (interactive)
  (save-excursion
    (widen)
    (goto-char (point-min))
    (org-map-entries (lambda () (org-unique-id-get (point) t)))))

;;;###autoload
(defun org-unique-id-maybe ()
  "Execute `org-unique-id' if in an org buffer and if enabled.

This function executes `org-unique-id' when the buffer’s major
mode is `org-mode', when the buffer is not read-only, and if
\\='unique-id:t\\' is found in an #+OPTIONS line."
  (interactive)
  (when (and (eq major-mode 'org-mode)
             (not buffer-read-only)
             (save-excursion
               (goto-char (point-min))
               (let ((case-fold-search t))
                 (re-search-forward "^#\\+OPTIONS:.*unique-id:t" (point-max) t))))
    (org-unique-id)))

(provide 'org-unique-id)

;;; org-unique-id.el ends here
