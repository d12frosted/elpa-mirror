;;; company-emojify.el --- Company completion for Emojify  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Shen, Jen-Chieh
;; Created date 2021-07-16 13:41:28

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Company completion for Emojify
;; Keyword: emoji company emojify
;; Version: 0.1.0
;; Package-Version: 20210718.424
;; Package-Commit: 5cc4bd886c1fc373eb1642ab0f0ba33de4f5d3d2
;; Package-Requires: ((emacs "26.1") (company "0.8.0") (emojify "1.2.1") (ht "2.0"))
;; URL: https://github.com/jcs-elpa/company-emojify

;; This file is NOT part of GNU Emacs.

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
;;
;; Company completion for Emojify
;;

;;; Code:

(require 'cl-lib)

(require 'company)
(require 'emojify)
(require 'ht)

(defgroup company-emojify nil
  "Company completion for Emojify."
  :prefix "company-emojify-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/company-emojify"))

(defcustom company-emojify-emoji-styles emojify-emoji-styles
  "Styles same with variable `emojify-emoji-styles' but limit to this package."
  :type '(set
          (const :tag "Display only ascii emojis" ascii)
          (const :tag "Display only github emojis" github)
          (const :tag "Display only unicode codepoints" unicode))
  :group 'company-emojify)

(defcustom company-emojify-annotation 'image
  "Option to display emoji in annotation."
  :type '(choice (const :tag "Don't display" nil)
                 (const :tag "Display with unicode" unicode)
                 (const :tag "Display with image" image))
  :group 'company-emojify)

(defcustom company-emojify-document t
  "If non-nil, display emoji information."
  :type 'boolean
  :group 'company-emojify)

;;
;; (@* "Core" )
;;

(defun company-emojify--display-image-p ()
  "Return non-nil, if we can display image."
  (and (display-graphic-p) (eq company-emojify-annotation 'image)))

(defun company-emojify--display-image (file selected)
  "Display emoji icon in annotation.

FILE is the emoji png file.  If SELECTED is non-nil means the current candidate
is the selected one."
  (let ((image-file (expand-file-name file (emojify-image-dir)))
        bkg dfw icon-size spec)
    (when (file-exists-p image-file)
      (setq bkg (face-attribute (if selected
                                    'company-tooltip-selection
                                  'company-tooltip)
                                :background)
            dfw (default-font-width)
            icon-size (cond
                       ((integerp company-icon-size)
                        company-icon-size)
                       ;; XXX: Also consider smooth scaling, e.g. using
                       ;; (aref (font-info (face-font 'default)) 2)
                       ((and (consp company-icon-size)
                             (eq 'auto-scale (car company-icon-size)))
                        (let ((base-size (cdr company-icon-size))
                              (dfh (default-font-height)))
                          (min
                           (if (> dfh (* 2 base-size))
                               (* 2 base-size)
                             base-size)
                           (* 2 dfw)))))
            spec (list 'image
                       :file image-file
                       :type 'png
                       :width icon-size
                       :height icon-size
                       :ascent 'center
                       :background (unless (eq bkg 'unspecified)
                                     bkg)))
      (propertize "-" 'display spec))))

(defun company-emojify--annotation (candidate)
  "Return annotation for CANDIDATE."
  (when company-emojify-annotation
    (let* ((display-with-image (company-emojify--display-image-p))
           (type (if display-with-image "image" "unicode"))
           (data (emojify-get-emoji candidate))
           (display (when (hash-table-p data) (ht-get data type)))
           (selected (equal (nth company-selection company-candidates) candidate)))
      (if display
          (if display-with-image
              (or (company-emojify--display-image display selected) "")
            display)
        ""))))

(defun company-emojify--candidates ()
  "Return a list of valid candidates."
  (let ((user (when (hash-table-p emojify--user-emojis) (ht-keys emojify--user-emojis)))
        (const (when (hash-table-p emojify-emojis) (ht-keys emojify-emojis))))
    (cl-remove-if-not
     (lambda (candidate)
       (let* ((data (emojify-get-emoji candidate))
              (style (ht-get data "style")))
         (memq (intern style) company-emojify-emoji-styles)))
     (append user const))))

(defun company-emojify--doc-buffer (candidate)
  "Return document for CANDIDATE."
  (company-doc-buffer
   (if company-emojify-document
       (let* ((data (emojify-get-emoji candidate))
              (name (ht-get data "name"))
              (style (ht-get data "style")))
         (format "%s (%s)" name style))
     "")))

;;
;; (@* "Entry" )
;;

;;;###autoload
(defun company-emojify (command &optional arg &rest ignored)
  "Company backend for Emojify.

Arguments COMMAND, ARG and IGNORED are standard arguments from `company-mode`."
  (interactive (list 'interactive))
  (emojify-create-emojify-emojis)
  (cl-case command
    (interactive (company-begin-backend 'company-emojify))
    (prefix (company-grab "\:[a-zA-Z0-9-_+]*"))
    (candidates (company-emojify--candidates))
    (annotation (company-emojify--annotation arg))
    (doc-buffer (company-emojify--doc-buffer arg))))

(provide 'company-emojify)
;;; company-emojify.el ends here
