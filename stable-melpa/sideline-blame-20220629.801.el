;;; sideline-blame.el --- Show blame messages with sideline  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Shen, Jen-Chieh

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Maintainer: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/emacs-sideline/sideline-blame
;; Package-Version: 20220629.801
;; Package-Commit: b0db4abe5c1c74e15c0844f60a94e8bcb1e29d11
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (sideline "0.1.0") (vc-msg "1.1.1"))
;; Keywords: convenience blame

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
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package displays blame information,
;;
;; 1) Add sideline-blame to sideline backends list,
;;
;;   (setq sideline-backends-right '(sideline-blame))
;;
;; 2) Then enable sideline-mode in the target buffer,
;;
;;   M-x sideline-mode
;;
;; This package uses vc-msg, make sure your project uses one of the following
;; version control system:
;;
;;   * Git
;;   * Mercurial
;;   * Subversion
;;   * Perforce
;;

;;; Code:

(require 'cl-lib)
(require 'subr-x)

(require 'sideline)
(require 'vc-msg)

(defgroup sideline-blame nil
  "Show blame messages with sideline."
  :prefix "sideline-blame-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/emacs-sideline/sideline-blame"))

(defcustom sideline-blame-author-format "%s, "
  "Format string for author name."
  :type 'string
  :group 'sideline-blame)

(defcustom sideline-blame-datetime-format "%b %d %Y %H:%M:%S "
  "Format string for datetime."
  :type 'string
  :group 'sideline-blame)

(defcustom sideline-blame-commit-format "◉ %s"
  "Format string for commit message."
  :type 'string
  :group 'sideline-blame)

(defcustom sideline-blame-uncommitted-author-name "Unknown"
  "Message for commits where you are author."
  :type 'string
  :group 'sideline-blame)

(defcustom sideline-blame-uncommitted-message "Uncommitted changes"
  "Message for uncommitted lines."
  :type 'string
  :group 'sideline-blame)

(defface sideline-blame
  '((t :foreground "#7a88cf"
       :background nil
       :italic t))
  "Face for blame info."
  :group 'sideline-blame)

;;;###autoload
(defun sideline-blame (command)
  "Backend for sideline.

Argument COMMAND is required in sideline backend."
  (cl-case command
    (`candidates (cons :async #'sideline-blame--display))
    (`face 'sideline-blame)))

(defun sideline-blame--get-message ()
  "Return the blame message."
  (when-let*
      ((plugin (vc-msg-find-plugin))
       (current-file (funcall vc-msg-get-current-file-function))
       (executer (plist-get plugin :execute))
       (formatter (plist-get plugin :format))
       (commit-info (and current-file
                         (funcall executer
                                  current-file
                                  (funcall vc-msg-get-line-num-function)
                                  (funcall vc-msg-get-version-function))))
       (id (plist-get commit-info :id)))
    (let* ((uncommitted (zerop (string-to-number id)))
           (author (if uncommitted sideline-blame-uncommitted-author-name
                     (plist-get commit-info :author)))
           (time (string-to-number (plist-get commit-info :author-time)))
           (summary (if uncommitted sideline-blame-uncommitted-message
                      (plist-get commit-info :summary))))
      (concat (format sideline-blame-author-format author)
              (format-time-string sideline-blame-datetime-format time)
              (format sideline-blame-commit-format summary)))))

(defun sideline-blame--display (callback &rest _)
  "Execute CALLBACK to display with sideline."
  (when-let ((msg (sideline-blame--get-message)))
    (funcall callback (list msg))))

(provide 'sideline-blame)
;;; sideline-blame.el ends here
