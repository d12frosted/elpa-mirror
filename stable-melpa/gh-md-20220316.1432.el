;;; gh-md.el --- Render markdown using the Github api  -*- lexical-binding: t; -*-

;; Copyright (C) 2014 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/gh-md.el
;; Package-Version: 20220316.1432
;; Package-Commit: e721fd5e41e682f47f2dd4ce26ef2ba28c7fa0b5
;; Keywords: convenience
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.3"))

;; This file is NOT part of GNU Emacs.

;;; License:

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
;; [![Travis build status](https://travis-ci.org/emacs-pe/gh-md.el.png?branch=master)](https://travis-ci.org/emacs-pe/gh-md.el)

;; Render markdown using the [Github API](https://developer.github.com/v3/markdown/).

;; Usage:
;;
;; After install `gh-md.el' you can use the functions
;; `gh-md-render-region' and `gh-md-render-buffer' to generate a
;; preview of the markdown content of a buffer.
;;
;; ![gh-md.el screenshot](screenshot.png)
;;
;; Note:
;;
;; If you get an error on the **Messages** buffer similar to
;; `peculiar error: "connect" host, "api.github.com" :service,443`,
;; then you might need to run this on your terminal:
;;
;; ```
;; git config --global --unset http.proxy
;; git config --global --unset https.proxy
;; ```

;;; Code:
(eval-when-compile
  (require 'url-http)
  (defvar url-http-end-of-headers))

(require 'json)
(require 'shr)
(require 'eww nil 'noerror)

;; `shr-render-region' for Emacs 24.3 and below.
(eval-and-compile
  (unless (fboundp 'shr-render-region)
    (defun shr-render-region (begin end &optional buffer)
      "Display the HTML rendering of the region between BEGIN and END."
      (interactive "r")
      (unless (fboundp 'libxml-parse-html-region)
        (error "This function requires Emacs to be compiled with libxml2"))
      (with-current-buffer (or buffer (current-buffer))
        (let ((dom (libxml-parse-html-region begin end)))
          (delete-region begin end)
          (goto-char begin)
          (shr-insert-document dom))))))

(defgroup gh-md nil
  "Render markdown using the github api."
  :prefix "gh-md-"
  :group 'applications)

(defcustom gh-md-use-gfm nil
  "Render using Github Flavored Markdown (GFM) by default ."
  :type 'boolean
  :group 'gh-md)

(defcustom gh-md-context nil
  "The repository context used to render markdown."
  :type 'string
  :safe 'stringp
  :group 'gh-md)

(defcustom gh-md-css-path nil
  "Path to css used output."
  :type 'string
  :safe 'stringp
  :group 'gh-md)

(defcustom gh-md-extra-header nil
  "Extra header used when converting to html."
  :type 'string
  :safe 'stringp
  :group 'gh-md)

(defvar gh-md-apiurl "https://api.github.com/markdown")
(defvar gh-md-buffer-name "*gh-md*")

(defun gh-md--json-payload (begin end &optional mode)
  "Build a json payload for the Github markdown api.

From BEGIN to END points, using a rendering MODE."
  (let ((text (buffer-substring-no-properties begin end))
        (mode (if gh-md-use-gfm "gfm" (or mode "markdown"))))
    ;; encode payload to fix 400 response from github if
    ;; text contains unicode characters - nikita-d.
    (encode-coding-string (json-encode `((text . ,text)
                                         (mode . ,mode)
                                         (context . ,gh-md-context))) 'utf-8)))

(defun gh-md--generate-html (content)
  "Generate base html with CONTENT."
  (mapconcat 'identity
             `("<!doctype html>"
               "<html>"
               "<head>"
               "<meta charset=\"utf-8\">"
               "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, minimal-ui\">"
               ,(and gh-md-css-path (format "<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"%s\">" gh-md-css-path))
               ,(and gh-md-extra-header gh-md-extra-header)
               "<style>"
               "body {"
               "  min-width: 200px;"
               "  max-width: 790px;"
               "  margin: 0 auto;"
               "  padding: 30px;"
               "}"
               "</style>"
               "</head>"
               "<body>"
               "<div class=\"markdown-body\">"
               ,content
               "</div>"
               "</body>"
               "</html>")
             "\n"))

(defun gh-md--export-file-name (&optional buffer)
  "Generate a export file name from BUFFER."
  (concat (file-name-sans-extension (or (buffer-file-name buffer)
                                        (buffer-name buffer)))
          ".html"))

(defun gh-md--callback (status &optional output-buffer export)
  "Callback used to render the response.

Checks if STATUS is not erred OUTPUT-BUFFER and EXPORT."
  (if (plist-get status :error)
      (message (error-message-string (plist-get status :error)))
    (let* ((response (with-current-buffer (current-buffer)
                       (goto-char url-http-end-of-headers)
                       (buffer-substring (point) (point-max))))
           (content (decode-coding-string response 'utf-8))
           (html (gh-md--generate-html content)))
      (with-current-buffer output-buffer
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert html)
          (if export
              (save-buffer)
            (shr-render-region (point-min) (point-max))
            (and (fboundp 'eww-mode) (eww-mode))
            (goto-char (point-min))
            (display-buffer (current-buffer))))))))

;;;###autoload
(defalias 'gh-md-render-region #'gh-md-convert-region)

;;;###autoload
(defun gh-md-convert-region (begin end &optional export)
  "Show a preview the markdown from a region from BEGIN to END.

EXPORT writes a file."
  (interactive "r")
  (let ((url-request-method "POST")
        (url-request-data (gh-md--json-payload begin end))
        (output-buffer (if export
                           (find-file-noselect (read-string "Export to file: " (gh-md--export-file-name)))
                         (get-buffer-create gh-md-buffer-name))))
    (url-retrieve gh-md-apiurl #'gh-md--callback (list output-buffer export) 'silent)))

;;;###autoload
(defun gh-md-render-buffer ()
  "Render the markdown content from BUFFER."
  (interactive)
  (gh-md-convert-region (point-min) (point-max)))

;;;###autoload
(defun gh-md-export-region (begin end)
  "Export to a file the markdown content from region BEGIN to END."
  (interactive "r")
  (gh-md-convert-region begin end 'export))

;;;###autoload
(defun gh-md-export-buffer ()
  "Export to a file the markdown content from BUFFER."
  (interactive)
  (gh-md-convert-region (point-min) (point-max) 'export))

(provide 'gh-md)

;;; gh-md.el ends here
