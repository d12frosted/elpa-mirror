;;; helm-orgcard.el --- browse the orgcard by helm -*- lexical-binding: t -*-

;; Description: browse the orgcard by helm.
;; Author: Yuhei Maeda <yuhei.maeda_at_gmail.com>
;; Maintainer: Yuhei Maeda
;; Copyright (C) 2015 Yuhei Maeda all rights reserved.
;; Created: :2013-06-05
;; Version: 0.2
;; Package-Version: 20220721.756
;; Package-Commit: d58d35627bb1714bb2cb095f696706b6881233ed
;; Keywords: convenience, helm, org
;; URL: https://github.com/emacs-jp/helm-orgcard
;; Package-Requires: ((helm-core "3.6.0"))

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

;; Put the helm-orgcard.el to your
;; load-path.
;; Add to init.el:
;; (require 'helm-orgcard)
;;
;; Original version is anything-orgcard, and port to helm.
;; https://gist.github.com/kiwanami/1345100
;;


;;; Code:

(require 'helm-core)

(defgroup helm-orgcard nil
  "Browse the orgcard by helm"
  :group 'org)

(defcustom hoc-lang-selector 'en
  "Select orgcard language. English or Japanese."
  :type '(choice
          (const :tag "English" en)
          (const :tag "Japanese" ja))
  :group 'helm-orgcard)

(defvar hoc-orgcard-url '((en  "http://orgmode.org/orgcard.txt")
                           (ja  "http://orgmode.jp/orgcard-ja.txt"))
  "URL to the orgcard.")

(defvar hoc-orgcard-file '((en  "~/.emacs.d/orgcard.txt")
                           (ja  "~/.emacs.d/orgcard.ja.txt"))
  "Path to the orgcard.")

(defun hoc-try-file ()
  "[internal] Check the local file. If it does not exist, this
function retrieves from the URL."
  (let ((file (expand-file-name
               (cadr (assoc hoc-lang-selector hoc-orgcard-file))))
        (url (cadr (assoc hoc-lang-selector hoc-orgcard-url))))
  (unless (file-exists-p file)
    (let ((buf (url-retrieve-synchronously url)))
      (when buf
        (with-current-buffer buf
          (write-file file))
        (kill-buffer buf))))
  (unless (file-exists-p file)
    (error "Can not get the orgcard file!"))))

(defun hoc-readline ()
  "[internal] read a line."
  (buffer-substring-no-properties
   (line-beginning-position)
   (line-end-position)))

(defun hoc-create-sources ()
  "[internal] create an helm source for orgcard."
  (let (heads
        cur-title
        cur-subtitle
        cur-records
        (file (expand-file-name
               (cadr (assoc hoc-lang-selector hoc-orgcard-file)))))
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (forward-line 4) ; skip title
      (while
          (let ((line (hoc-readline)))
            (cond
             ((equal "" line) nil)     ; do nothing
             ((equal ?= (aref line 0)) ; header
              (when cur-title          ; flush records
                (push
                 `((name . ,cur-title)
                   (candidates ,@cur-records)
                   (action
                    . (("Echo" . hoc-echo-action))))
                 heads))
              (forward-line 1)
              (setq cur-title (hoc-readline))
              (setq cur-records nil cur-subtitle nil)
              (forward-line 1))
             ((equal ?- (aref line 0)) ; subtitle
              (forward-line 1)
              (setq cur-subtitle (concat (hoc-readline) "# " ))
              (forward-line 1))
             (t                        ; normal line
              (push (concat cur-subtitle line) cur-records)))
            (forward-line 1)
            (not (eobp)))))
    (when cur-title ; flush the last records
      (push
       `((name . ,cur-title)
         (candidates ,cur-records)
         (action . (("Echo" . hoc-echo-action))))
       heads))
    (reverse heads)))

(defun hoc-echo-action (entry)
  "[internal] popup an entry of orgcard."
  (message entry)
  ;;(popup-tip entry)
  nil)

;;;###autoload
(defun helm-orgcard ()
  "Anything command for orgcard."
  (interactive)
  (hoc-try-file)
  (helm (hoc-create-sources)))

(provide 'helm-orgcard)
;;; helm-orgcard.el ends here
