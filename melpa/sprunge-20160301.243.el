;;; sprunge.el --- Upload pastes to sprunge.us

;; Copyright (C) Tom Jakubowski

;; Author: Tom Jakubowski
;; Version: 0.1.1
;; Package-Requires: ((request "0.2.0") (cl-lib "0.5"))
;; Keywords: tools

;; This file is NOT part of GNU Emacs.

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
;;
;; Upload pastes to sprunge.us.
;;
;; See the documentation for `sprunge-buffer' and `sprunge-region' for more
;; information.

;;; Code:

(require 'cl-lib)
(require 'request)

(defgroup sprunge nil
  "Customization for sprunge package."
  :group 'sprunge)

(defcustom sprunge-url
  "http://sprunge.us/"
  "URL of sprunge.us."
  :group 'sprunge
  :type 'string)

(defun sprunge--upload-text-sync (text)
  "Upload TEXT to sprunge.us asynchronously.  Return the URL of the paste."
  (let ((sprunge-return nil))
    (request sprunge-url
             :type "POST"
             :files `(("sprunge" . ("" :data ,text)))
             :parser 'buffer-string
             :sync t
             :success (cl-function
                       (lambda (&key data &allow-other-keys)
                         (setq sprunge-return
                               (replace-regexp-in-string "[ \t\n\r]*\\'" ""  data))))
             :error (cl-function
                     (lambda (&key error-thrown &allow-other-keys)
                       (error "Sprunge upload error: %S" error-thrown))))
    sprunge-return))

;;;###autoload
(defun sprunge-buffer (&optional buffer)
  "Upload a paste from the current buffer, or BUFFER.

Copies the new paste's URL to the kill ring and prints the URL to
the messages list."
  (interactive)
  (let ((buf (or buffer (current-buffer))))
    (with-current-buffer buf
      (let ((paste-url (sprunge--upload-text-sync (buffer-string))))
        (kill-new paste-url)
        (message "%s" paste-url)))))

;;;###autoload
(defun sprunge-region ()
  "Upload a paste from the active region.

Copies the new paste's URL to the kill ring and prints the URL to
the messages list."
  (interactive)
  (when (region-active-p)
    (let ((paste-url (sprunge--upload-text-sync
                        (buffer-substring (region-beginning) (region-end)))))
      (kill-new paste-url)
      (message "%s" paste-url))))

(provide 'sprunge)

;;; sprunge.el ends here
