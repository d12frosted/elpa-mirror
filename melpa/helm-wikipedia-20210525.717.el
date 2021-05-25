;;; helm-wikipedia.el --- Wikipedia suggestions -*- lexical-binding: t -*-

;; Authors: Thierry Volpiatto, Adam Porter, et al
;; Copyright (C) 2012 ~ 2018 Thierry Volpiatto <thierry.volpiatto@gmail.com>

;; Package-Requires: ((helm "3.6") (emacs "25.1"))
;; Package-Version: 20210525.717
;; Package-Commit: c242c74efaeda2ffbafd281ee6bceae1a42507bb
;; URL: https://github.com/emacs-helm/helm-wikipedia
;; Version: 1.0

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
;; Helm interface to wikipedia suggestions.

;;; Code:

(require 'json)

(require 'helm-net)

(defcustom helm-wikipedia-suggest-url
  "https://en.wikipedia.org/w/api.php?action=opensearch&search=%s"
  "Url used for looking up Wikipedia suggestions.
This is a format string, don't forget the `%s'."
  :type 'string
  :group 'helm-net)

(defcustom helm-wikipedia-summary-url
  "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&titles=%s&exintro=1&explaintext=1&redirects=1"
  "URL for getting the summary of a Wikipedia topic.
This is a format string, don't forget the `%s'."
  :type 'string
  :group 'helm-net)

(defcustom helm-wikipedia-input-idle-delay 0.6
  "`helm-input-idle-delay' used for helm-wikipedia."
  :type 'float
  :group 'helm-net)

(declare-function json-read-from-string "json" (string))
(defun helm-wikipedia-suggest-fetch ()
  "Fetch Wikipedia suggestions and return them as a list."
  (require 'json)
  (let ((request (format helm-wikipedia-suggest-url
                         (url-hexify-string helm-pattern))))
    (helm-net--url-retrieve-sync
     request #'helm-wikipedia--parse-buffer)))

(defun helm-wikipedia--parse-buffer ()
  "Parse wikipedia buffer."
  (goto-char (point-min))
  (when (re-search-forward "^\\[.+\\[\\(.*\\)\\]\\]" nil t)
    (cl-loop for i across (aref (json-read-from-string (match-string 0)) 1)
             collect i into result
             finally return (or result
                                (append
                                 result
                                 (list (cons (format "Search for '%s' on wikipedia"
                                                     helm-pattern)
                                             helm-pattern)))))))

(defvar helm-wikipedia--summary-cache (make-hash-table :test 'equal)
  "A temporary cache for wikipedia summary.")
(defun helm-wikipedia-show-summary (input)
  "Show Wikipedia summary for INPUT in new buffer."
  (interactive)
  (let ((buffer (get-buffer-create "*helm wikipedia summary*"))
        (summary (helm-wikipedia--get-summary input)))
    (with-current-buffer buffer
      (visual-line-mode)
      (erase-buffer)
      (insert summary)
      (pop-to-buffer (current-buffer))
      (goto-char (point-min)))))

(defun helm-wikipedia-persistent-action (candidate)
  "Run PA on CANDIDATE for wikipedia source."
  (unless (string= (format "Search for '%s' on wikipedia"
                           helm-pattern)
                   (helm-get-selection nil t))
    (message "Fetching summary from Wikipedia...")
    (let ((buf (get-buffer-create "*helm wikipedia summary*"))
          (result (helm-wikipedia--get-summary candidate)))
      (with-current-buffer buf
        (erase-buffer)
        (setq cursor-type nil)
        (insert result)
        (fill-region (point-min) (point-max))
        (goto-char (point-min)))
      (display-buffer buf))))

(defun helm-wikipedia--get-summary (input)
  "Return Wikipedia summary for INPUT as string.
Follows any redirections from Wikipedia, and stores results in
`helm-wikipedia--summary-cache'."
  (let (result)
    (while (progn
             (setq result (or (gethash input helm-wikipedia--summary-cache)
                              (puthash input
                                       (helm-wikipedia--fetch-summary input)
                                       helm-wikipedia--summary-cache)))
             (when (and result
                        (listp result))
               (setq input (cdr result))
               (message "Redirected to %s" input)
               t)))
    (unless result
      (error "Error when getting summary"))
    result))

(defun helm-wikipedia--fetch-summary (input)
  "Fetch wikipedia summary matching INPUT."
  (let* ((request (format helm-wikipedia-summary-url
                          (url-hexify-string input))))
    (helm-net--url-retrieve-sync
     request #'helm-wikipedia--parse-summary)))

(defun helm-wikipedia--parse-summary ()
  "Return plain-text rendering of article summary.
Read from JSON in HTTP response buffer.  Should be called in
`url-retrieve' response buffer."
  (goto-char (point-min))
  (re-search-forward "\n\n" nil t)
  (let* ((json (json-read))
         (pages (let-alist json
                  .query.pages)))
    (alist-get 'extract (nth 0 pages))))

(defvar helm-wikipedia-map
  (let ((map (copy-keymap helm-map)))
    (define-key map (kbd "<C-return>") 'helm-wikipedia-show-summary-action)
    map)
  "Keymap for `helm-wikipedia-suggest'.")

(defvar helm-source-wikipedia-suggest
  (helm-build-sync-source "Wikipedia Suggest"
    :candidates #'helm-wikipedia-suggest-fetch
    :action '(("Wikipedia" . (lambda (candidate)
                               (helm-search-suggest-perform-additional-action
                                helm-search-suggest-action-wikipedia-url
                                candidate)))
              ("Show summary in new buffer (C-RET)" . helm-wikipedia-show-summary))
    :persistent-action #'helm-wikipedia-persistent-action
    :persistent-help "show summary"
    :match-dynamic t
    :keymap helm-wikipedia-map
    :requires-pattern 3))

(defun helm-wikipedia-show-summary-action ()
  "Exit Helm buffer and call `helm-wikipedia-show-summary' with selected candidate."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-wikipedia-show-summary)))

;;;###autoload
(defun helm-wikipedia-suggest ()
  "Preconfigured `helm' for Wikipedia lookup with Wikipedia suggest."
  (interactive)
  (let ((helm-input-idle-delay helm-wikipedia-input-idle-delay)) 
    (helm :sources 'helm-source-wikipedia-suggest
          :buffer "*helm wikipedia*"
          :input-idle-delay (max 0.4 helm-input-idle-delay))))


(provide 'helm-wikipedia)

;; Local Variables:
;; byte-compile-warnings: (not cl-functions obsolete)
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; helm-wikipedia.el ends here
