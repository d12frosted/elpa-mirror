;;; github-explorer.el --- Explore a GitHub repository on the fly -*- lexical-binding: t -*-

;; Copyright (C) 2019 Giap Tran <txgvnn@gmail.com>

;; Author: Giap Tran <txgvnn@gmail.com>
;; URL: https://github.com/TxGVNN/github-explorer
;; Package-Version: 20210825.1440
;; Package-Commit: cd1186fb6ca7728c1cf2478ad3878a6401c65246
;; Version: 1.0.0
;; Package-Requires: ((emacs "25"))
;; Keywords: comm

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; M-x github-explorer "txgvnn/github-explorer"

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'graphql)
(require 'hi-lock)

(defgroup github nil
  "Major mode of GitHub configuration file."
  :group 'languages
  :prefix "github-explorer-")

(defcustom github-explorer-hook nil
  "*Hook run by `github-explorer'."
  :type 'hook
  :group 'github)

(defcustom github-explorer-name "GitHub"
  "*Modeline of `github-explorer'."
  :type 'string
  :group 'github)

(defvar github-explorer-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "o") 'github-explorer-at-point)
    (define-key keymap (kbd "RET") 'github-explorer-at-point)
    (define-key keymap (kbd "n") 'next-line)
    (define-key keymap (kbd "p") 'previous-line)
    keymap)
  "Keymap for GitHub major mode.")

(defface github-explorer-directory-face
  '((t (:inherit font-lock-function-name-face)))
  "Face for a directory.")

(defvar github-explorer-repository nil)
(defvar github-explorer-buffer-temp nil)

(defun github-explorer-util-package-try-get-package-url ()
  "Try and get single a package url under point.

From URL `https://github.com/akshaybadola/emacs-util'
`util/package-try-get-package-url'."
  (when (and (eq major-mode 'package-menu-mode))
    (let ((pkg-desc (tabulated-list-get-id (point))))
      (when (and pkg-desc (package-desc-extras pkg-desc))
        (message (cdr (assq :url (package-desc-extras  pkg-desc))))
        (cdr (assq :url (package-desc-extras  pkg-desc)))))))

(defun github-explorer-repo-from-url (url)
  "Get repo user/name from url."
  (string-join (last (split-string url "/") 2) "/"))

;;;###autoload
(defun github-explorer (&optional repo)
  "Go REPO github."
  (interactive (list (or (and (thing-at-point 'url t)
                              (github-explorer-repo-from-url (thing-at-point 'url t)))
                         (and (eq major-mode 'org-mode)
                              (eq (org-element-type (org-element-context)) 'link)
                              (github-explorer-repo-from-url
                               (org-element-property :raw-link (org-element-context))))
                         (and (eq major-mode 'package-menu-mode)
                              (github-explorer-repo-from-url (util/package-try-get-package-url)))
                         (thing-at-point 'symbol))))
  (let ((repo (read-string "Repository: " repo)))
    (url-retrieve (format "https://api.github.com/repos/%s/git/trees/HEAD:?recursive=1" repo)
                  (lambda (arg)
                    (cond
                     ((equal :error (car arg))
                      (message arg))
                     (t
                      (with-current-buffer (current-buffer)
                        (goto-char (point-min))
                        (re-search-forward "^$")
                        (delete-region (+ 1 (point)) (point-min))
                        (goto-char (point-min))
                        (let* ((paths (remove nil
                                              (mapcar (lambda (x)
                                                        (if (equal (cdr (assoc 'type x)) "blob")
                                                            (cdr (assoc 'path x))))
                                                      (cdr (assoc 'tree (json-read))))))
                                      (path (completing-read "Find file: " paths)))
                          (if (eq (length path) 0)
                              (github-explorer--tree repo (format "https://api.github.com/repos/%s/git/trees/%s"
                                                                  repo "HEAD") "/")
                            (github-explorer--raw repo (format "/%s" path)))))))))))

(defun github-explorer-at-point()
  "Go to path in buffer GitHub tree."
  (interactive)
  (let (url path (pos 0) matches repo base-path item)
    (setq item (get-text-property (line-beginning-position) 'invisible))
    (setq url (cdr (assoc 'url item)))
    (setq path (cdr (assoc 'path item)))

    (setq repo (buffer-name))
    (while (string-match ":\\(.+\\)\\*" repo pos)
      (setq matches (concat (match-string 0 repo)))
      (setq pos (match-end 0)))
    (setq base-path (substring matches 1 (- (length matches) 1)))
    (setq repo (car (split-string base-path ":")))
    (setq path (format "%s%s"  (car (cdr (split-string base-path ":"))) path))
    (if (string= (cdr (assoc 'type item)) "tree")
        (setq path (concat path "/")))
    (message "%s" path)
    (if (string= (cdr (assoc 'type item)) "tree")
        (github-explorer--tree repo url path)
      (github-explorer--raw repo path))))

(defun github-explorer--tree (repo url path)
  "Get trees by URL of PATH github.
This function will create *GitHub:REPO:* buffer"
  (setq github-explorer-buffer-temp (format "*%s:%s:%s*" github-explorer-name repo path))
  (url-retrieve url
                (lambda (arg)
                  (cond
                   ((equal :error (car arg))
                    (message arg))
                   (t
                    (with-current-buffer (current-buffer)
                      (let (github-explorer-object)
                        (goto-char (point-min))
                        (re-search-forward "^$")
                        (delete-region (point) (point-min))
                        (goto-char (point-min))
                        (setq github-explorer-object (json-read))
                        (with-current-buffer (get-buffer-create github-explorer-buffer-temp)
                          (read-only-mode -1)
                          (erase-buffer)
                          (github-explorer--render-object github-explorer-object)
                          (goto-char (point-min))
                          (github-explorer-mode)
                          (setq-local github-explorer-repository repo)
                          (switch-to-buffer (current-buffer))))))))))

(defun github-explorer--raw (repo path)
  "Get raw of PATH in REPO github."
  (let (url)
    (setq url (format "https://raw.githubusercontent.com/%s/HEAD%s" repo path))
    (setq github-explorer-buffer-temp (format "*%s:%s:%s*" github-explorer-name repo path))
    (url-retrieve url
                  (lambda (arg)
                    (cond
                     ((equal :error (car arg))
                      (message arg))
                     (t
                      (with-current-buffer (current-buffer)
                        (let (data)
                          (goto-char (point-min))
                          (re-search-forward "^$")
                          (delete-region (+ 1 (point)) (point-min))
                          (goto-char (point-min))
                          (setq data (buffer-string))
                          (with-current-buffer (get-buffer-create github-explorer-buffer-temp)
                            (insert data)
                            (pop-to-buffer (current-buffer))
                            (goto-char (point-min))
                            (setq-local github-explorer-repository repo))))))))))

(defun github-explorer-apply-auto-mode (&rest _)
  "Apply auto-mode for buffer GitHub.
pop-to-buffer(BUFFER-OR-NAME &OPTIONAL ACTION NORECORD)"
  (unless buffer-file-name
    (if (string-match-p (regexp-quote (format "*%s:" github-explorer-name)) (buffer-name))
        (let ((buffer-file-name (substring (buffer-name) 0 -1))) ;; remove * ending
          (set-auto-mode t)))))
(advice-add 'pop-to-buffer :after #'github-explorer-apply-auto-mode)

(defun github-explorer--item-path (item)
  "Get the path for an ITEM from GitHub."
  (cdr (assoc 'path item)))

(defun github-explorer--item-type (item)
  "Get the type for an ITEM from GitHub."
  (cdr (assoc 'type item)))

(defun github-explorer--render-object (github-explorer-object)
  "Render the GITHUB-EXPLORER-OBJECT."
  (let ((trees (cdr (assoc 'tree github-explorer-object))))
	(cl-loop
	 for item across trees
	 for path = (github-explorer--item-path item)

	 if (string= (github-explorer--item-type item) "blob")
	 do (insert (format "  |----- %s" path))
	 else do
	 (insert (format "  |--[+] %s" path))
	 (left-char (length path))
	 (put-text-property (point) (+ (length path) (point)) 'face 'github-explorer-directory-face)

	 do
	 (put-text-property (line-beginning-position) (1+ (line-beginning-position)) 'invisible item)
	 (end-of-line)
	 (insert "\n"))))

(define-derived-mode github-explorer-mode special-mode github-explorer-name
  "Major mode for exploring GitHub repository on the fly"
  (setq buffer-auto-save-file-name nil
        buffer-read-only t))

(defun github-build-graphql (variable-query)
  "Build Graphql query.
VARIABLE-QUERY"
  (list
   (cons "query"
         (graphql-query
          (:arguments
           (($query . String!))
           (search
            :arguments
            ((query . ($ query)))
            (results limitHit
                     (results
                      ... on (FileMatch
                              (file name path)
                              (lineMatches preview lineNumber offsetAndLengths))))))))
   (cons "variables" (list (cons "query" variable-query)))))

(defun github-explorer-search (&optional prefix)
  "Using sourcegraph to search pattern.
If PREFIX is set, prompt repo"
  (interactive "P")
  (let ((repo
         (if (or (not github-explorer-repository) (and github-explorer-repository prefix))
             (read-string "Repository: ")
           github-explorer-repository))
        (query (read-string "Query: ")))
    (github-explorer-search-f repo query)))

(defun github-explorer-search-f (&optional repo query)
  "Search QUERY in REPO by using Sourcegraph API."
  (let ((url-request-method (encode-coding-string "POST" 'us-ascii))
        (url-request-extra-headers '())
        (url-request-data (json-encode (github-build-graphql (format "repo:^github.com/%s$ %s" repo query))))
        (url-mime-charset-string (url-mime-charset-string)))
    (url-retrieve "https://sourcegraph.com/.api/graphql"
                  #'github-explorer-search-response
                  (append (list repo query)))))

(defun github-explorer-search--write (data)
  "Parse graphql DATA into current buffer."
  (dolist (linematch (cdr (car (cdr (cdr (car (cdr (car (cdr (car data))))))))))
    (insert (cdr (car (cdr (cdr (car linematch))))))
    (insert "\n")
    (dolist (line  (cdr (car (cdr linematch))))
      (insert (format "%s:" (cdr (assoc 'lineNumber line))))
      (insert (make-string (car (car (cdr(assoc 'offsetAndLengths line)))) #x20))
      (insert (cdr(assoc 'preview line)))
      (insert "\n"))))

(defun github-explorer-search-response (status repo query)
  "Render the response(STATUS) of searching QUERY in REPO."
  (if (= (point-min) (point-max))
      (signal (car (plist-get status :error)) (cdr (plist-get status :error)))
    (when (buffer-live-p (current-buffer))
      (with-current-buffer (current-buffer)
        (goto-char (point-min))
        (re-search-forward "^$")
        (delete-region (point) (point-min))
        (goto-char (point-min))
        (let* ((json-object-type 'alist)
               (json-array-type 'list)
               (data (json-read))
               (bufname (format "*%s:%s?%s*" github-explorer-name repo query)))
          (with-current-buffer (get-buffer-create bufname)
            (github-explorer-search--write data)
            (hi-lock-set-pattern query font-lock-keyword-face nil nil t nil)
            (read-only-mode 1)
            (setq-local github-explorer-repository repo)
            (switch-to-buffer (current-buffer))))))))

;; (github-explorer-search-f "github.com/txgvnn/github-explorer" "defun")

(provide 'github-explorer)
;;; github-explorer.el ends here
