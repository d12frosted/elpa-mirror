;;; adafruit-wisdom.el --- Get/display adafruit.com quotes

;; Author: Neil Okamoto <neil.okamoto+melpa@gmail.com>
;; Version: 0.3.0
;; Package-Version: 20200217.306
;; Package-Commit: a9314331ba6ea846be9e1f7bded1e2e0ab70cd8e
;; Keywords: games
;; URL: https://github.com/gonewest818/adafruit-wisdom.el
;; Package-Requires: ((emacs "25.1") (request "0.3.1"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; I've always enjoyed the engineering quotes found at the footer of
;; each page on adafruit.com ... now you can too!  This code is
;; derived from Dave Pearson's dad-joke.el, except adafruit.com
;; publishes their quotes as rss so we have to deal with that.

;;; Code:

(require 'dom)
(require 'request)
(require 'xml)

(defconst adafruit-wisdom-quote-url "https://www.adafruit.com/feed/quotes.xml"
  "URL for the RSS quote feed served on adafruit.com.")

(defconst adafruit-wisdom-cache-file
  (if (featurep 'no-littering)
      (with-no-warnings
        (require 'no-littering)
        (no-littering-expand-var-file-name "adafruit-wisdom.cache"))
    (locate-user-emacs-file "adafruit-wisdom.cache"))
  "Location for the local copy of the quotes file.
When `no-littering' is available put the cache file in the
specified var directory.  Otherwise the default location for the
cache file is `user-emacs-directory'.")

(defconst adafruit-wisdom-cache-ttl (* 3600.0 24.0) ; 24 hours
  "Time-to-live for the local cache file.")

(defun adafruit-wisdom-cached-get ()
  "Retrieves RSS from adafruit.com, or from cache if TTL hasn't expired.
Returns the parsed XML."
  (let* ((mtime (nth 5 (file-attributes adafruit-wisdom-cache-file)))
         (age   (and mtime (- (float-time (current-time))
                              (float-time mtime)))))
    (if (and age (< age adafruit-wisdom-cache-ttl))
        (with-temp-buffer
          (insert-file-contents adafruit-wisdom-cache-file)
          (xml-parse-region (point-min) (point-max)))
      (with-temp-file adafruit-wisdom-cache-file
        (let ((resp (request adafruit-wisdom-quote-url
                      :type "GET"
                      :sync t
                      :timeout 15
                      :parser 'buffer-string)))
          (set-buffer-file-coding-system 'no-conversion)
          (insert (request-response-data resp))
          (xml-parse-region (point-min) (point-max)))))))

;;;###autoload
(defun adafruit-wisdom-select ()
  "Select a quote at random and return as a string.

Parse assuming the following RSS format:
     ((rss (channel (item ...) (item ...) (item ...) ...)))
where each item contains:
     (item (title nil \"the quote\") ...)
and we  need just \"the quote\"."
  (let* ((items (dom-by-tag (adafruit-wisdom-cached-get) 'item))
         (pick  (nth (random (length items)) items))
         (title (dom-text (car (dom-by-tag pick 'title)))))
    title))

;;;###autoload
(defun adafruit-wisdom (&optional arg)
  "Display one of Adafruit's quotes in the minibuffer.
If ARG is non-nil the joke will be inserted into the current
buffer rather than shown in the minibuffer."
  (interactive "P")
  (let ((quote (adafruit-wisdom-select)))
    (if (null quote)
        (error "Couldn't retrieve a quote from adafruit")
      (if arg
          (insert quote)
        (message quote))
      t)))

(provide 'adafruit-wisdom)

;;; adafruit-wisdom.el ends here
