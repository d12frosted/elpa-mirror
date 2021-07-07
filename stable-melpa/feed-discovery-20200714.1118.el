;;; feed-discovery.el --- Discover feed url by RSS/Atom autodiscovery  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Hiroki YAMAKAWA

;; Author:  Hiroki YAMAKAWA <s06139@gmail.com>
;; URL: https://github.com/HKey/feed-discovery
;; Package-Version: 20200714.1118
;; Package-Commit: 12fcd1a28fe7c8c46c74e32f395ec631d45ec739
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1") (dash "2.16.0"))

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

;; This package allows you to discover feed urls from a website url by
;; RSS/Atom autodiscovery.

;; You can copy a feed url by `feed-discovery-copy-feed-url' command.
;; The command discover feed urls from input url and copy one of them.

;;; Code:

(require 'dom)
(require 'url-expand)
(require 'ffap)
(require 'dash)

(defconst feed-discovery-mime-types '("application/rss+xml"
                                      "application/atom+xml")
  "MIME types of autodiscovery.")

(defun feed-discovery--feed-link-p (element)
  "Non-nil if ELEMENT is an autodiscovery link element.
ELEMENT is a dom list."
  (and (eq (dom-tag element) 'link)
       (equal (dom-attr element 'rel) "alternate")
       (member (dom-attr element 'type) feed-discovery-mime-types)
       (dom-attr element 'href)))

(defun feed-discovery--find-base-url (dom)
  "Find base url from DOM."
  (-some--> dom
    (dom-by-tag it 'base)
    (prog1 it (cl-assert (= 1 (length it))))
    (car it)
    (dom-attr it 'href)))

(defun feed-discovery--discover-feeds-in-region (start end &optional base)
  "Discover feeds from html in a region of current buffer.
START and END are the range of the region.
BASE is a base url."
  (let* ((dom
          ;; NOTE: no libxml version is needed?
          (libxml-parse-html-region start end))
         (base-url (or base (feed-discovery--find-base-url dom))))
    (-some--> dom
      ;; Do not filter by head element because the link elements are placed
      ;; in body element on some pages,
      ;; e.g. "https://www.youtube.com/channel/CHANNEL_ID".
      ;; (dom-by-tag it 'head)
      (dom-by-tag it 'link)
      (-filter #'feed-discovery--feed-link-p it)
      (--map (dom-attr it 'href) it)
      (--map (if base-url (url-expand-file-name it base-url) it) it))))

(defun feed-discovery-discover-feeds (url)
  "Discover feeds from URL."
  (with-temp-buffer
    (url-insert-file-contents url)
    (feed-discovery--discover-feeds-in-region (point-min) (point-max) url)))

;;;###autoload
(defun feed-discovery-copy-feed-url (url)
  "Copy one url of feeds discovered from URL."
  (interactive
   (list (completing-read "URL: "
                          nil nil nil
                          (ffap-url-at-point))))
  (let ((feeds (feed-discovery-discover-feeds url)))
    (if (null feeds)
        (message "No feed discovered from %s" url)
      (--> (completing-read "Copy feed URL: " feeds nil t)
           (kill-new it)))))

(provide 'feed-discovery)
;;; feed-discovery.el ends here

;; Local Variables:
;; eval: (when (fboundp 'flycheck-mode) (flycheck-mode 1))
;; eval: (when (fboundp 'flycheck-package-setup) (flycheck-package-setup))
;; byte-compile-error-on-warn: t
;; End:
