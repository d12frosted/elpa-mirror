;;; dashboard-hackernews.el --- Display Hacker News on dashboard -*- lexical-binding: t; -*-

;; Copyright (C) 2018 by Hayato KAJIYAMA

;; Author:  Hayato KAJIYAMA <kaji1216@gmail.com>
;; URL: https://github.com/hyakt/emacs-dashboard-hackernews
;; Package-Version: 20220516.1809
;; Package-Commit: dd5f8ec998d7b7bf162b4eb72474b683b8aa0a14
;; Version: 0.0.2
;; Package-Requires: ((emacs "24") (dashboard "1.2.5") (request "0.3.0"))

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

;; Display Hacker News on dashboard.

;;; Code:

(require 'request)
(require 'dashboard)
(require 'dashboard-widgets)

(add-to-list 'dashboard-item-generators '(hackernews . dashboard-hackernews-insert))
(add-to-list 'dashboard-items '(hackernews) t)

(defvar dashboard-hackernews-items ())

(defconst dashboard-hackernews-api-version "v0"
  "Currently supported version of the Hacker News API.")

(defconst dashboard-hackernews-api-top-format
  (format "https://hacker-news.firebaseio.com/%s/topstories.json"
          dashboard-hackernews-api-version)
  "Format of targeted Hacker News API URLs.")

(defconst dashboard-hackernews-site-item-format
  (format "https://hacker-news.firebaseio.com/%s/item"
          dashboard-hackernews-api-version)
  "Format of Hacker News website item URLs.")

(defun dashboard-hackernews-get-ids (callback)
  "Get hackernews ids, and execute CALLBACK function."
  (request
   dashboard-hackernews-api-top-format
   :sync t
   :parser 'json-read
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (funcall callback data)))))

(defun dashboard-hackernews-get-item (id callback)
  "Get hackernews article from ID, and execute CALLBACK function."
  (request
   (format "%s/%s.json" dashboard-hackernews-site-item-format id)
   :parser 'json-read
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (funcall callback data)))))

(defun dashboard-hackernews-insert-list (list-display-name list)
  "Render LIST-DISPLAY-NAME and items of LIST."
  (when (car list)
    (dashboard-insert-heading list-display-name)
    (mapc (lambda (el)
            (insert "\n    ")
            (widget-create 'push-button
                           :action `(lambda (&rest ignore)
                                      (browse-url ,(cdr (assoc 'url el))))
                           :mouse-face 'highlight
                           :follow-link "\C-m"
                           :button-prefix ""
                           :button-suffix ""
                           :format "%[%t%]"
                           (format "[%3d] %s" (cdr (assoc 'score el)) (decode-coding-string (cdr (assoc 'title el)) 'utf-8))))
          list)))

(defun dashboard-hackernews-insert (list-size)
  "Add the list of LIST-SIZE items from hackernews."
  (dashboard-hackernews-get-ids
   (lambda (ids)
     (dotimes (i list-size)
       (dashboard-hackernews-get-item
        (elt ids i) (lambda (item) (push item dashboard-hackernews-items))))))
  (dashboard-hackernews-insert-list "Hackernews:"
                                    (dashboard-subseq dashboard-hackernews-items list-size)))

(provide 'dashboard-hackernews)
;;; dashboard-hackernews.el ends here
