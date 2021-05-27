;;; helm-google.el --- Emacs Helm Interface for quick Google searches

;; Copyright (C) 2014-2018, Steckerhalter

;; Author: steckerhalter
;; Package-Requires: ((helm "0"))
;; Package-Version: 20210527.900
;; Package-Commit: 27834161391c350ef790062391cb7eab1d59fb62
;; URL: https://framagit.org/steckerhalter/helm-google
;; Keywords: helm google search browse searx

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Emacs Helm Interface for quick Google searches

;;; Code:

(require 'helm)
(require 'helm-net)
(require 'json)

(defgroup helm-google '()
  "Customization group for `helm-google'."
  :link '(url-link "https://framagit.org/steckerhalter/helm-google")
  :group 'convenience
  :group 'comm)

(defcustom helm-google-default-engine 'google
  "The default engine to use.
See `helm-google-engines' for available engines."
  :type 'symbol
  :group 'helm-google)

(defcustom helm-google-actions
  '(("Browse URL" . browse-url)
    ("Browse URL with EWW" . (lambda (candidate)
                               (eww-browse-url candidate)))
    ("Copy URL to clipboard" . (lambda (candidate)
                                 (kill-new  candidate)))
    ("Browse URL with webkit xwidget" . (lambda (candidate)
                                          (xwidget-webkit-browse-url candidate))))
  "List of actions for helm-google sources."
  :group 'helm-google
  :type '(alist :key-type string :value-type function))

(defcustom helm-google-engines
  '((google . "https://encrypted.google.com/search?ie=UTF-8&oe=UTF-8&q=%s")
    (searx . "https://searx.dk/?engines=google&format=json&q=%s"))
  "Alist of search engines.
Each element is a cons-cell (ENGINE . URL).
`%s' is where the search terms are inserted in the URL."
  :group 'helm-google
  :type '(alist :key-type symbol :value-type string))

(defcustom helm-google-idle-delay 0.5
  "Time to wait when idle until query is made."
  :type 'integer
  :group 'helm-google)

(defvar helm-google-input-history nil)
(defvar helm-google-pending-query nil)

(defun helm-google--process-html (html)
  (replace-regexp-in-string
   "\n" ""
   (with-temp-buffer
     (insert html)
     (if (fboundp 'html2text)
         (html2text)
       (shr-render-region (point-min) (point-max)))
     (buffer-substring-no-properties (point-min) (point-max)))))

(defmacro helm-google--with-buffer (buf &rest body)
  (declare (doc-string 3) (indent 2))
  `(with-current-buffer ,buf
     (set-buffer-multibyte t)
     (goto-char url-http-end-of-headers)
     (prog1 ,@body
       (kill-buffer ,buf))))

(defun helm-google--parse-google (buf)
  "Parse the html response from Google."
  (helm-google--with-buffer buf
      (let (results result)
        (while (re-search-forward "class=\"kCrYT\"><a href=\"/url\\?q=\\(.*?\\)&amp;sa" nil t)
          (setq result (plist-put result :url (match-string-no-properties 1)))
          (re-search-forward "BNeawe vvjwJb AP7Wnd\">\\(.*?\\)</div>" nil t)
          (setq result (plist-put result :title (helm-google--process-html (match-string-no-properties 1))))
          ;; This check is necessary because of featured results
          (if (looking-at "</h3>")
              (progn
                (re-search-forward "BNeawe s3v9rd" nil t)
                (re-search-forward "BNeawe s3v9rd" nil t)
                (re-search-forward "\">\\(.*?\\)</div>" nil t)
                (setq result (plist-put result :content (helm-google--process-html (match-string-no-properties 1))))))
          (add-to-list 'results result t)
          (setq result nil))
        results)))

(defun helm-google--parse-searx (buf)
  "Parse the json response from Searx."
  (let ((json-object-type 'plist)
        (json-array-type 'list))
    (plist-get (helm-google--with-buffer buf (json-read)) :results)))

(defun helm-google--response-buffer-from-search (text search-url)
  (let ((url-mime-charset-string "utf-8")
        (url (format search-url (url-hexify-string text))))
    (url-retrieve-synchronously url t)))

(defun helm-google--search (text engine)
  "Fetch the response buffer and parse it with the corresponding
parsing function."
  (let* ((search-url (or (and (eq engine 'google)
                              (boundp 'helm-google-url) ;support legacy variable
                              helm-google-url)
                         (alist-get engine helm-google-engines)))
         (buf (helm-google--response-buffer-from-search text search-url))
         (results (funcall (intern (format "helm-google--parse-%s" engine)) buf)))
    results))

(defun helm-google-search (&optional engine)
  "Query the search engine, parse the response and fontify the candidates."
  (let* ((engine (or engine helm-google-default-engine))
         (results (helm-google--search helm-pattern engine)))
    (mapcar (lambda (result)
              (let ((cite (plist-get result :cite)))
                (cons
                 (concat
                  (propertize
                   (plist-get result :title)
                   'face 'font-lock-variable-name-face)
                  "\n"
                  (plist-get result :content)
                  "\n"
                  (when cite
                    (concat
                     (propertize
                      cite
                      'face 'link)
                     "\n"))
                  (propertize
                   (url-unhex-string
                    (plist-get result :url))
                   'face (if cite 'glyphless-char 'link)))
                 (plist-get result :url))))
            results)))


(defun helm-google-engine-string ()
  (capitalize
   (format "%s" helm-google-default-engine)))

;;;###autoload
(defun helm-google (&optional engine search-term)
  "Web search interface for Emacs."
  (interactive)
  (let ((input (or search-term (when (use-region-p)
                                 (buffer-substring-no-properties
                                  (region-beginning)
                                  (region-end)))))
        (helm-google-default-engine (or engine helm-google-default-engine)))
    (helm :sources `((name . ,(helm-google-engine-string))
                     (action . helm-google-actions)
                     (candidates . helm-google-search)
                     (requires-pattern)
                     (nohighlight)
                     (multiline)
                     (match . identity)
                     (volatile))
          :prompt (concat (helm-google-engine-string) ": ")
          :input input
          :input-idle-delay helm-google-idle-delay
          :buffer "*helm google*"
          :history 'helm-google-input-history)))

;;;###autoload
(defun helm-google-searx (&optional search-term)
  "Explicitly use Searx for the web search."
  (interactive)
  (helm-google 'searx search-term))

;;;###autoload
(defun helm-google-google (&optional search-term)
  "Explicitly use Google for the web search."
  (interactive)
  (helm-google 'google search-term))

(add-to-list 'helm-google-suggest-actions
             '("Helm-Google" . (lambda (candidate)
                                 (helm-google nil candidate))))

(provide 'helm-google)

;;; helm-google.el ends here
