;;; gsnip.el --- A gitlab snippet client          -*- lexical-binding: t -*-

;; Copyright (C) 2020  Wang Kai

;; Author: Wang Kai <kaiwkx@gmail.com>
;; Keywords: extensions, tools
;; Package-Version: 20220206.1526
;; Package-Commit: 4d473b726b3f3b6bb7d1b5f66a9d368588ce0f86
;; URL: https://github.com/kaiwk/gitlab-snippet
;; Package-Requires: ((emacs "26") (aio "1.0") (log4e "0.3.3"))
;; Version: 0.1.0

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

;; gsnip.el is an unofficial Gitlab Snippet client.
;;
;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'json)
(require 'subr-x)
(require 'parse-time)
(require 'url-http)

(require 'aio)
(require 'log4e)
(log4e:deflogger "gsnip" "%t [%l] %m" "%H:%M:%S" '((fatal . "fatal")
                                                   (error . "error")
                                                   (warn  . "warn")
                                                   (info  . "info")
                                                   (debug . "debug")
                                                   (trace . "trace")))
(setq log4e--log-buffer-gsnip "*gsnip-log*")

;;;###autoload
(defun gsnip-toggle-debug ()
  "Toggle gitlab-snippet debug."
  (interactive)
  (if (gsnip--log-debugging-p)
      (progn
        (gsnip--log-set-level 'info)
        (gsnip--log-disable-debugging)
        (message "gsnip disable debug"))
    (progn
      (gsnip--log-set-level 'debug)
      (gsnip--log-enable-debugging)
      (message "gsnip enable debug"))))


;;; Gitlab Snippet API

(defvar gsnip-private-token nil "Gitlab private token.")
(defvar gsnip-url "https://gitlab.com/" "Gitlab url.")
(defvar gsnip--user-snippets nil "Gitlab user snippets.")
(defvar-local gsnip-id nil
  "A buffer-local value to identify current buffer's snippet-id.")
(defvar url-http-end-of-headers)

(defun gsnip--api (suffix-path)
  "Generate Gitlab Snippet API wit SUFFIX-PATH."
  (concat gsnip-url "api/v4/snippets/" suffix-path))

(defconst gsnip--buffer-name "*gitlab-snippets*")

(aio-defun gsnip--fetch-user-snippets ()
  "Fetch user snippets."
  (let* ((url-request-method "GET")
         (url-request-extra-headers
          `(("PRIVATE-TOKEN" . ,gsnip-private-token)))
         (res (aio-await (aio-url-retrieve (gsnip--api "")))))
    (with-current-buffer (cdr res)
      (set-buffer-multibyte t)
      (json-read-from-string
       (decode-coding-string
        (string-trim (buffer-substring-no-properties
                      url-http-end-of-headers
                      (point-max)))
        'utf-8)))))

(aio-defun gsnip--fetch-raw (snippet-id)
  "Fetch snippet raw content by SNIPPET-ID"
  (gsnip--debug "fetch raw snippet-id: %s" snippet-id)
  (let* ((url-request-method "GET")
         (url-request-extra-headers
          `(("PRIVATE-TOKEN" . ,gsnip-private-token)))
         (snippet (seq-find (lambda (s)
                              (let-alist s (string= (number-to-string .id) snippet-id)))
                            gsnip--user-snippets))
         (res (let-alist snippet
                (aio-await (aio-url-retrieve (gsnip--api (concat (number-to-string .id) "/raw")))))))
    (with-current-buffer (cdr res)
      (set-buffer-multibyte t)
      (decode-coding-string
       (string-trim (buffer-substring-no-properties
                     url-http-end-of-headers
                     (point-max)))
       'utf-8))))

(aio-defun gsnip--put-snippet (snippet-id snippet)
  "Update snippet by SNIPPET-ID with SNIPPET, and it will be `json-encode' like below:

{
    \"title\":\"a snippet for files backup\",
    \"file_name\":\"run_backup.py\",
    \"description\":\"blah blah blah\",
    \"content\":\"some python code here\",
    \"visibility\":\"private|internal|public\"
}"
  (gsnip--debug "put raw snippet-id: %s" snippet-id)
  (message "Updating %s..." snippet-id)
  (let* ((url-request-method "PUT")
         (url-request-extra-headers
          `(("PRIVATE-TOKEN" . ,gsnip-private-token)
            ("Content-Type" . "application/json")))
         (url-request-data
          (encode-coding-string (json-encode snippet) 'utf-8))
         (res (aio-await (aio-url-retrieve (gsnip--api snippet-id)))))
    (with-current-buffer (cdr res)
      (let ((status-code (url-http-parse-response)))
        (if (= status-code 200)
            (message "Update %s success!" snippet-id)
          (message "Update %s failed, status code: %s" snippet-id status-code))))))

(aio-defun gsnip--post-snippet (snippet)
  "Post SNIPPET, and it will be `json-encode' like below:

{
    \"title\":\"a snippet for files backup\",
    \"file_name\":\"run_backup.py\",
    \"description\":\"blah blah blah\",
    \"content\":\"some python code here\",
    \"visibility\":\"private|internal|public\"
}"
  (gsnip--debug "post snippet: %s" snippet)
  (message "Posting...")
  (let* ((fname (let-alist snippet .file_name))
         (url-request-method "POST")
         (url-request-extra-headers
          `(("PRIVATE-TOKEN" . ,gsnip-private-token)
            ("Content-Type" . "application/json")))
         (url-request-data
          (encode-coding-string (json-encode snippet) 'utf-8))
         (res (aio-await (aio-url-retrieve (gsnip--api "")))))
    (with-current-buffer (cdr res)
      (set-buffer-multibyte t)
      (let* ((status-code (url-http-parse-response))
             (svr-snippet (json-read-from-string
                           (decode-coding-string
                            (string-trim (buffer-substring-no-properties
                                          url-http-end-of-headers
                                          (point-max)))
                            'utf-8)))
             (snippet-id (let-alist svr-snippet .id))
             (snippet-url (let-alist svr-snippet .web_url)))
        (if (= status-code 201)
            (prog1 snippet-url
              (message "Post %s(id=%s) success!" fname snippet-id))
          (message "Post %s failed, status code: %s" fname status-code))))))

(aio-defun gsnip--delete-snippet (snippet-id)
  "Delete snippet by SNIPPET-ID."
  (gsnip--debug "delete snippet: %s" snippet-id)
  (message "Deleting...")
  (let* ((url-request-method "DELETE")
         (url-request-extra-headers
          `(("PRIVATE-TOKEN" . ,gsnip-private-token)
            ("Content-Type" . "application/json")))
         (res (aio-await (aio-url-retrieve (gsnip--api snippet-id)))))
    (with-current-buffer (cdr res)
      (let ((status-code (url-http-parse-response)))
        (if (= status-code 204)
            (message "Delete %s success!" snippet-id)
          (message "Delete %s failed, status code: %s" snippet-id status-code))))))


(defun gsnip--make-tabulated-headers (header-names rows)
  "Calculate headers width.
Column width calculated by picking the max width of every cell
under that column and the HEADER-NAMES. HEADER-NAMES are a list
of header name, ROWS are a list of vector, each vector is one
row."
  (let ((widths
         (seq-reduce
          (lambda (acc row)
            (cl-mapcar
             (lambda (a col) (+ (max a (length col)) 1))
             acc
             (append row '())))
          rows
          (seq-map #'length header-names))))
    (vconcat
     (cl-mapcar
      (lambda (col size) (list col size nil))
      header-names widths))))

(defun gsnip--make-tabulated-rows ()
  "Generate tabulated list rows from `gsnip--user-snippets'.
Return a list of rows, each row is a vector:
\([<Id> <Created> <Visibility> <Filename> <Title> <Description>] ...)"
  (cl-loop for snippet across gsnip--user-snippets
           collect
           (let-alist snippet
             (vector (number-to-string .id)
                     (format-time-string
                      "%m/%d/%Y %H:%M"
                      (parse-iso8601-time-string .created_at))
                     .visibility .file_name .title (or .description "")))))

(aio-defun gsnip-refresh ()
  "Refresh Gitlab user snippets."
  (interactive)
  (setq gsnip--user-snippets (aio-await (gsnip--fetch-user-snippets)))
  (let* ((header-names `("Id" "Created" "Visibility" "Filename" "Title" "Description"))
         (rows (gsnip--make-tabulated-rows))
         (headers (gsnip--make-tabulated-headers header-names rows)))
    (with-current-buffer (get-buffer-create gsnip--buffer-name)
      (gsnip--snippets-mode)
      (setq tabulated-list-format headers)
      (setq tabulated-list-entries
            (cl-mapcar
             (lambda (i x) (list i x))
             (number-sequence 0 (1- (length rows)))
             rows))
      (tabulated-list-init-header)
      (tabulated-list-print t))))

;;;###autoload(autoload 'gsnip "gsnip" "" t nil)
(aio-defun gsnip ()
  "Show Gitlab snippets list."
  (interactive)
  (aio-await (gsnip-refresh))
  (switch-to-buffer gsnip--buffer-name))

(aio-defun gsnip--show-current-snippet ()
  "Show current entry snippet. Get current entry by using `tabulated-list-get-entry'."
  (interactive)
  (let* ((entry (tabulated-list-get-entry))
         (snippet-id (aref entry 0))
         (buf-name (format "*gsnip:%s*/%s" snippet-id (gsnip--snippet-filename snippet-id)))
         (raw (aio-await (gsnip--fetch-raw snippet-id))))
    (with-current-buffer (get-buffer-create buf-name)
      (erase-buffer)
      (insert raw)
      (gsnip--debug "insert raw: \n%s" raw)
      (set-buffer-modified-p nil)
      (let ((fmode (assoc-default (file-name-extension buf-name t) auto-mode-alist #'string-match-p)))
        (if fmode (funcall fmode)))
      (gsnip-mode t)
      (setq gsnip-id snippet-id))
    (switch-to-buffer-other-window buf-name)))

(defun gsnip--snippet-filename (snippet-id)
  "Get snippet filename with SNIPPET-ID."
  (let* ((snippet (seq-find (lambda (s) (let-alist s (string= (number-to-string .id) snippet-id)))
                            gsnip--user-snippets))
         (filename (let-alist snippet .file_name)))
    filename))


;;; gsnip--snippets-mode

(aio-defun gsnip-yank ()
  "Yank current entry's snippet."
  (interactive)
  (let* ((snippet-id (aref (tabulated-list-get-entry) 0))
         (raw (aio-await (gsnip--fetch-raw snippet-id))))
    (kill-new raw)
    (message "Snippet saved!")))

(aio-defun gsnip-yank-link ()
  "Yank current entry's snippet web link."
  (interactive)
  (let ((snippet-id (aref (tabulated-list-get-entry) 0)))
    (kill-new (let-alist (seq-find
                          (lambda (s) (let-alist s (string= (number-to-string .id) snippet-id)))
                          gsnip--user-snippets)
                .web_url))
    (message "Snippet link saved!")))

(aio-defun gsnip-edit-meta ()
  "Edit current entry's title and description."
  (interactive)
  (let* ((snippet-id (aref (tabulated-list-get-entry) 0))
         (title (aref (tabulated-list-get-entry) 4))
         (description (aref (tabulated-list-get-entry) 5))
         (new-title (read-from-minibuffer "Title: " title))
         (new-description (read-from-minibuffer "Description: " description)))
    (aio-await (gsnip--put-snippet snippet-id `((title . ,new-title) (description . ,new-description))))
    (aio-await (gsnip-refresh))
    (message "Save title and description success!")))

;;;###autoload(autoload 'gsnip-region "gsnip" "" t nil)
(aio-defun gsnip-region (begin end &optional visibility)
  "Post marked region from BEGIN to END with VISIBILITY. Default VISIBILITY is internal."
  (interactive "r")
  (deactivate-mark)
  (let* ((file (or (buffer-file-name) (buffer-name)))
         (fname (file-name-nondirectory file))
         (snippet-url (aio-await (gsnip--post-snippet
                                  `((title . ,fname)
                                    (file_name . ,fname)
                                    (content . ,(buffer-substring-no-properties begin end))
                                    (visibility . ,(or visibility "internal")))))))
    (kill-new snippet-url)
    (aio-await (gsnip-refresh))))

;;;###autoload(autoload 'gsnip-region-private "gsnip" "" t nil)
(aio-defun gsnip-region-private (begin end)
  "Post marked region from BEGIN to END with private visibility."
  (interactive "r")
  (aio-await (gsnip-region begin end "private")))

;;;###autoload(autoload 'gsnip-region-public "gsnip" "" t nil)
(aio-defun gsnip-region-public (begin end)
  "Post marked region from BEGIN to END with public visibility."
  (interactive "r")
  (aio-await (gsnip-region begin end "public")))

(aio-defun gsnip-delete ()
  "Delete snippet."
  (interactive)
  (let* ((snippet-id (aref (tabulated-list-get-entry) 0))
         (confirm-delete (yes-or-no-p (format "Delete snippet %s?" snippet-id))))
    (when confirm-delete
      (aio-await (gsnip--delete-snippet snippet-id))
      (aio-await (gsnip-refresh)))))

(defvar gsnip--snippets-mode-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (suppress-keymap map)
      (define-key map (kbd "RET") #'gsnip--show-current-snippet)
      (define-key map "n" #'next-line)
      (define-key map "p" #'previous-line)
      (define-key map "q" #'quit-window)
      (define-key map "G" #'gsnip-refresh)
      (define-key map "Y" #'gsnip-yank)
      (define-key map "y" #'gsnip-yank-link)
      (define-key map "d" #'gsnip-delete)
      (define-key map "e" #'gsnip-edit-meta)))
  "Keymap for `gsnip--snippets-mode'.")

(define-derived-mode gsnip--snippets-mode
  tabulated-list-mode "Gitlab Snippet"
  "Major mode for browsing a list of problems."
  (setq-local tabulated-list-padding 1)
  :group 'gsnip)
(add-hook 'gsnip--snippets-mode-hook #'hl-line-mode)


;;; gsnip-mode

(defvar gsnip-mode-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (define-key map [remap save-buffer] 'gsnip-mode-save-buffer)
      (define-key map [remap write-file] 'gsnip-mode-write-file)))
  "Keymap for command `gsnip-mode'.")

(aio-defun gsnip-mode-save-buffer ()
  "Save snippet."
  (interactive)
  (let ((content (with-current-buffer (buffer-name)
                   (save-restriction
                     (widen)
                     (buffer-substring-no-properties (point-min) (point-max))))))
    (aio-await (gsnip--put-snippet gsnip-id `((content . ,content)))))
  (aio-await (gsnip-refresh)))

(aio-defun gsnip-mode-write-file ()
  "Rename snippet name."
  (interactive)
  (let ((new-name (read-from-minibuffer "File name: " (gsnip--snippet-filename gsnip-id))))
    (aio-await (gsnip--put-snippet gsnip-id `((file_name . ,new-name)))))
  (aio-await (gsnip-refresh)))

(define-minor-mode gsnip-mode
  "Minor mode for buffers containing gitlab snippets"
  :lighter " gsnip"
  :map 'gsnip-mode-map)

(provide 'gsnip)

;;; gsnip.el ends here
