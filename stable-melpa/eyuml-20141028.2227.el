;;; eyuml.el --- Write textual uml diagram from emacs using yuml.me

;; Copyright (C) 2014 Anthony HAMON

;; Author: Anthony HAMON <hamon.anth@gmail.com>
;; URL: http://github.com/antham/eyuml
;; Package-Version: 20141028.2227
;; Package-Commit: 2f259c201c6cc63ee608f75cd85c1ae27f9d2532
;; Version: 0.1.0
;; Package-Requires: ((request "0.2.0") (s "1.8.0"))
;; Keywords: uml

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

;; Refer to yuml.me site to understand how to represent uml diagram with text

;; You get three functions (for every sort of diagram) that you can map :

;; (global-set-key (kbd "C-c a") 'eyuml-create-activity-diagram)
;; (global-set-key (kbd "C-c c") 'eyuml-create-class-diagram)
;; (global-set-key (kbd "C-c u") 'eyuml-create-usecase-diagram)

;;; Code:

(require 'request)
(require 's)

;;;###autoload
(defgroup eyuml nil
  "Write textual uml diagram using yuml.me.")

(defcustom eyuml-document-output-format "png"
  "Define document output format."
  :group 'eyuml
  :type '(choice (const :tag "jpg" "jpg")
                 (const :tag "pdf" "pdf")
                 (const :tag "png" "png")
                 (const :tag "svg" "svg")))

(defun eyuml-check-buffer-is-tied-to-file ()
  "Ensure buffer is tied to a file."
  (unless (buffer-file-name)
    (error "You need to save this buffer in a file first")))

(defun eyuml-create-url (type)
  "Create url from buffer to fetch document, TYPE could be class,usecase or activity."
  (concat (concat "http://yuml.me/diagram/plain/" type "/")
          (url-hexify-string (s-trim
                              (buffer-substring-no-properties
                               (point-min)
                               (point-max)))) "." eyuml-document-output-format))


(defun eyuml-create-file-name ()
  "Create filename from current buffer name and defined format."
  (concat (buffer-file-name) "." eyuml-document-output-format))

(defun eyuml-create-document (type)
  "Fetch remote document, TYPE could be class,usecase or activity."
  (eyuml-check-buffer-is-tied-to-file)
  (request (eyuml-create-url type)
           :parser 'buffer-string
           :success (cl-function
                     (lambda (&key data &allow-other-keys)
                       (when data
                         (with-temp-file
                             (eyuml-create-file-name)
                           (insert data)))))))

;;;###autoload
(defun eyuml-create-class-diagram ()
  "Create class diagram."
  (interactive)
  (eyuml-create-document "class"))

;;;###autoload
(defun eyuml-create-activity-diagram ()
  "Create activity diagram."
  (interactive)
  (eyuml-create-document "activity"))

;;;###autoload
(defun eyuml-create-usecase-diagram ()
  "Create usecase diagram."
  (interactive)
  (eyuml-create-document "usecase"))

(provide 'eyuml)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; eyuml.el ends here
