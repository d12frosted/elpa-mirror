;;; declutter.el --- Read html content and (some) paywall sites without clutter
;;; -*- indent-tabs-mode: nil -*-

;; Copyright (c) 2019-2021 Sanel Zukan
;;
;; Author: Sanel Zukan <sanelz@gmail.com>
;; URL: http://www.github.com/sanel/declutter
;; Package-Version: 20210904.2039
;; Package-Commit: e08195e2f5691ad0ec9090d7edf550608e13fcfa
;; Version: 0.2.0
;; Keywords: html, hypermedia, terminals
;; Package-Requires: ((emacs "25.1"))

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

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Allows reading sites without clutter.  Uses outline.com service or lynx for actual work.

;;; Installation:

;; Copy it to your load-path and run with:
;; M-: (require 'declutter)

;;; Usage:

;; M-x declutter

;;; Code:

(require 'json)
(require 'shr)
(require 'eww)  ; maybe load it lazily

(defgroup declutter nil
  "Declutter web sites."
  :prefix "declutter-"
  :group 'applications)

(defcustom declutter-outline-api-url "https://api.outline.com/v3/parse_article?source_url="
  "Outline service, used to get cleaned content."
  :type 'string
  :group 'declutter)

(defcustom declutter-user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.75 Safari/537.36"
  "Custom user agent."
  :type 'string
  :group 'declutter)

(defcustom declutter-engine 'outline
  "Engine used to visit and render URL.
Values are 'outline for using outline.com service, 'lynx for using local lynx
installation or 'rdrview for https://github.com/eafer/rdrview."
  :type 'symbol
  :group 'declutter)

(defcustom declutter-engine-path nil
  "Path for engine program.
If lynx or rdrview was used as rendering engine, this will be the path
to the application binary.  If set to nil but the engine is lynx or
rdrview, it will call them as is, assuming they are in PATH."
  :type 'string
  :group 'declutter)

(defun declutter-fetch-url (url referer jsonp)
  "Try to get content from given URL.
If JSONP is true, parse it to json list.  REFERER is necessary for outline.com."
  (with-temp-buffer
    (let ((url-request-extra-headers (if referer
                                       (list (cons "Referer" referer))))
          (url-user-agent (concat "User-Agent: " declutter-user-agent "\r\n")))
      (url-insert-file-contents url)
      (if jsonp
        ;; TODO: support for native JSON (https://emacs.stackexchange.com/a/38482)
        (let ((json-false :false))
          (json-read))
        ;; extract actual content
        (buffer-substring-no-properties (point-min) (point-max))))))

(defun declutter-get-html-from-outline (url)
  "Construct properl URL and call outline.com service.
Expects json response and retrieve html part from it."
  (let* ((full-url (concat declutter-outline-api-url (url-hexify-string url)))
         (response (declutter-fetch-url full-url "https://outline.com/" t)))
    (cdr
     (assoc 'html (assoc 'data response)))))

(defun declutter-render-content (content htmlp)
  "Render in *declutter* buffer.
Assuming CONTENT is html string, render it in named buffer as html
or just display it, depending if HTMLP was set to true."
  (with-current-buffer (pop-to-buffer "*declutter*")
    (save-excursion
      (erase-buffer)
      (insert content)
      ;; shr-render-buffer will start own *html* buffer, so use shr-render-region
      (when htmlp
        (shr-render-region (point-min) (point-max))))))

(defun declutter-url-outline (url)
  "Use Outline API to declutter URL."
  (let ((content (declutter-get-html-from-outline url)))
    (if (not content)
      (message "Zero reply from outline.com. This usually means it wasn't able to render the article.")
      (declutter-render-content content t))))

(defun declutter-url-lynx (url)
  "Use lynx to declutter URL."
  (let* ((agent (if declutter-user-agent
                    (concat "-useragent=\"" declutter-user-agent "\"")))
         (path (or declutter-engine-path "lynx"))
         (content (shell-command-to-string (concat path " " agent " -dump " url))))
    (if (not content)
      (message "No content from lynx")
      (declutter-render-content content nil))))

(defun declutter-url-rdrview (url)
  "Use rdrview to declutter URL."
  (let* ((path (or declutter-engine-path "rdrview"))
         (content (shell-command-to-string (concat path " -A \"" declutter-user-agent "\" -H " url))))
    (if (not content)
      (message "No content from rdrview")
      (declutter-render-content content t))))

(defun declutter-eww-readable ()
  "Call 'eww-readable' in *declutter* buffer."
  (unwind-protect
      (progn
        (eww-readable)
        ;; declutter is using fundamental-mode
        (fundamental-mode))
    (remove-hook 'eww-after-render-hook #'declutter-eww-readable)))

(defun declutter-url-eww (url)
  "Use eww (Emacs builtin web browser) to decluter URL."
  ;; This function is loading eww and with eww-after-render-hook will call eww-readable.
  ;; Sadly, eww doesn't have easy way to render html with eww-readable due many stateful
  ;; operations, so calling declutter-fetch-url and passing content to eww/eww-readable
  ;; does not work.
  (let (;; declutter-fetch-url is not used here, so we must set user agent for eww.
        (url-user-agent (concat "User-Agent: " declutter-user-agent "\r\n")))
    (pop-to-buffer "*declutter*")
    ;; switch to eww-mode or eww will pop out own buffer
    (eww-mode)
    (add-hook 'eww-after-render-hook #'declutter-eww-readable)
    (eww url)))

(defun declutter-url (url)
  "Depending on declutter-engine variable, call appropriate functions."
  (cond
   ((eq 'outline declutter-engine) (declutter-url-outline url))
   ((eq 'lynx declutter-engine) (declutter-url-lynx url))
   ((eq 'rdrview declutter-engine) (declutter-url-rdrview url))
   ((eq 'eww declutter-engine) (declutter-url-eww url))
   (t (message "Unknown decluttering engine. Use 'outline, 'lynx or 'rdrview."))))

(defun declutter-get-url-under-point ()
  "Try to figure out is there any URL under point.
Returns nil if none."
  (let ((url (get-text-property (point) 'shr-url)))
       (if url
           url
           (browse-url-url-at-point))))

(defun declutter-under-point ()
  "Declutters URL under point."
  (interactive)
  (let ((url (declutter-get-url-under-point)))
    (if url
        (declutter-url url)
        (message "No URL under point"))))

;;;###autoload
(defun declutter (url)
  "Read URL and declutter it, using outline.com service."
  (interactive
   (let* ((url    (declutter-get-url-under-point))
          (prompt (if url
                      (format "URL (default: %s): " url)
                      "URL: ")))
     (list
      (read-string prompt nil nil url))))
  (declutter-url url))

(provide 'declutter)

;;; declutter.el ends here
