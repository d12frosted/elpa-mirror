;;; notmuch-maildir.el --- Visualize maildirs as a tree  -*- lexical-binding: t -*-

;; Copyright (C) 2020 Free Software Foundation, Inc.

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://git.sr.ht/~tarsius/notmuch-maildir
;; Keywords: mail
;; Package-Version: 20210615.1513
;; Package-Commit: fd0e2199da746906eca080d4ca5bca17068cdce5

;; Package-Requires: ((emacs "26") (notmuch "0.30"))

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package can visualize maildirs hierarchically in Notmuch's
;; hello buffer.  Call `notmuch-maildir-inject-section' to enable
;; this.

;;; Code:

(require 'notmuch)

(defvar notmuch-maildir-separator-regexp "[-.]")
(defvar notmuch-maildir-nosplit-regexp "[[@]")

(defun notmuch-hello-insert-maildirs ()
  "Insert the maildir tree section."
  (widget-insert "Maildirs:\n\n")
  (let ((default-directory (notmuch-maildir--mail-root)))
    (dolist (dir (notmuch-maildir--list-directories))
      (let* ((parts  (mapcan
                      (lambda (part)
                        (if (string-match-p notmuch-maildir-nosplit-regexp part)
                            (list part)
                          (split-string part notmuch-maildir-separator-regexp)))
                      (split-string dir "[/\\]")))
             (depth  (1- (length parts)))
             (name   (car (last parts)))
             (string (concat (make-string (* 2 depth) ?\s) name)))
        (if (notmuch-maildir-p dir)
            (let* ((query  (format "folder:%s" dir))
                   (unread (read (car (process-lines
                                       notmuch-command "count"
                                       (concat query " tag:unread")))))
                   (total  (read (car (process-lines
                                       notmuch-command "count"
                                       query))))
                   (widget-push-button-prefix "")
                   (widget-push-button-suffix ""))
              (widget-create 'push-button
                             :notify #'notmuch-hello-widget-search
                             :notmuch-search-terms query
                             string)
              (widget-insert (make-string (max 0 (- 30 (current-column))) ?\s))
              (widget-insert (propertize (format " [%s/%s]" unread total) 'face
                                         (if (zerop unread) 'default 'bold))))
          (widget-insert (propertize string 'face 'bold)))
        (widget-insert "\n")))))

(defun notmuch-maildir-p (directory)
  (file-accessible-directory-p (expand-file-name "new" directory)))

(defun notmuch-maildir--mail-root ()
  (car (or (process-lines "notmuch" "config" "get" "database.mail_root")
           (process-lines "notmuch" "config" "get" "database.path"))))

(defun notmuch-maildir--list-directories (&optional directory)
  (setq directory (file-name-as-directory (or directory default-directory)))
  (mapcar (let ((offset (length directory)))
            (lambda (dir)
              (substring dir offset)))
          (notmuch-maildir--list-directories-1 directory)))

(defun notmuch-maildir--list-directories-1 (directory)
  (mapcan (lambda (dir)
            (and (file-accessible-directory-p dir)
                 (if (notmuch-maildir-p dir)
                     (list dir)
                   (cons dir (notmuch-maildir--list-directories-1 dir)))))
          (directory-files directory t "^[^.]")))

;;;###autoload
(defun notmuch-maildir-inject-section ()
  "Inject `notmuch-hello-insert-maildirs' into `notmuch-hello-sections'."
  (unless (member 'notmuch-hello-insert-maildirs notmuch-hello-sections)
    (let ((cons (member 'notmuch-hello-insert-footer notmuch-hello-sections)))
      (setcdr cons (cons (car cons) (cdr cons)))
      (setcar cons 'notmuch-hello-insert-maildirs))))

;;; _
(provide 'notmuch-maildir)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; notmuch-maildir.el ends here
