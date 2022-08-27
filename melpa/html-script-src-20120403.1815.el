;;; html-script-src.el --- Insert <script src=".."> for popular JavaScript libraries

;; Copyright (C) 2010 Johan Andersson

;; Author: Johan Andersson <johan.rejeep@gmail.com>
;; Maintainer: Johan Andersson <johan.rejeep@gmail.com>
;; Version: 0.0.2
;; Package-Version: 20120403.1815
;; Package-Commit: 0efeed7ab948e48128e6f1a7ddff17ef2951e1c2
;; Keywords: tools, convenience
;; URL: http://github.com/rejeep/html-script-src

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Inserts a script tag for HTML and HAML documents with a URL to a
;; given JavaScript library taken from: http://scriptsrc.net/

;; To use this, make sure that this file is in Emacs load-path:
;;   (add-to-list 'load-path "/path/to/directory/or/file")
;;
;; Require it:
;;   (require 'html-script-src)
;;
;; Then in your HTML or HAML file, interactively call the function
;; `html-script-src'.


;;; Code:


(defvar html-script-src-completion-fn
  (if ido-mode 'ido-completing-read 'completing-read)
  "Function to use for library completion.")

(defvar html-script-src-cache nil
  "Caches all library names and url.")


(defconst html-script-src-re
  "<textarea id=\"fe_text_\\(.+\\)\".*class=\"fetext\".*>\\(.+\\)</textarea>"
  "Regular expression matching a JavaScript library in the HTML source.")

(defconst html-script-src-scriptsrc-url "http://scriptsrc.net/"
  "URL to Script Src website.")

(defconst html-script-src-haml-script-format
  "%%script{:src => \"%s\", :type => \"text/javascript\", :charset => \"utf-8\"}"
  "Format string for HAML script tag.")

(defconst html-script-src-html-script-format
  "<script src=\"%s\" type=\"text/javascript\" charset=\"utf-8\"></script>"
  "Format string for HTML script tag.")


;;;###autoload
(defun html-script-src (arg)
  "Insert a script tag for a JavaScript library. With prefix argument,
cache is omitted."
  (interactive "P")
  (if arg (html-script-src-clear-cache))
  (let* ((libraries (html-script-src-libraries))
         (library (html-script-src-completing-read (mapcar 'car libraries))))
    (html-script-src-insert-tag (cdr (assoc library libraries)))))

(defun html-script-src-clear-cache ()
  "Clears the cache."
  (setq html-script-src-cache nil))

(defun html-script-src-completing-read (libraries)
  "Read a JavaScript library from LIBRARIES in the minibuffer, with completion."
  (funcall html-script-src-completion-fn "Library: " libraries nil t))

(defun html-script-src-libraries ()
  "Return a list of all JavaScript names and URLs."
  (or html-script-src-cache
      (let ((buffer (html-script-src-fetch)))
        (with-current-buffer buffer
          (setq html-script-src-cache (html-script-src-parse)))
        (kill-buffer buffer)))
  html-script-src-cache)

(defun html-script-src-parse ()
  "Parse the Script Src website and return all JavaScript libraries as a list."
  (goto-char (point-min))
  (let ((libraries))
    (while (re-search-forward html-script-src-re nil t)
      (add-to-list 'libraries
                   (cons
                    (match-string-no-properties 1)
                    (match-string-no-properties 2))))
    libraries))

(defun html-script-src-fetch ()
  "Fetches the HTML source for the Script Src website."
  (let ((url-request-method "GET")
        (url-request-extra-headers nil)
        (url-mime-accept-string "*/*")
        (url (url-generic-parse-url html-script-src-scriptsrc-url)))
    (url-retrieve-synchronously url)))

(defun html-script-src-insert-tag (url)
  "Insert a tag for URL."
  (insert (html-script-src-tag url)))

(defun html-script-src-tag (url)
  "Return a formatted tag string with URL."
  (let ((format (html-script-src-tag-format)))
    (format format url)))

(defun html-script-src-tag-format ()
  "Return tag format depending on mode."
  (if (eq major-mode 'haml-mode)
      html-script-src-haml-script-format
    html-script-src-html-script-format))


(provide 'html-script-src)

;;; html-script-src.el ends here
