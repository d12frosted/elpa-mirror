;;; org-picklink.el --- Pick a headline link from org-agenda      -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Feng Shu <tumashu@163.com>

;; Author: Feng Shu <tumashu@163.com>
;; Homepage: https://github.com/tumashu/org-picklink
;; Version: 0.1.0
;; Package-Version: 20210210.516
;; Package-Commit: bfdc22b436482752be41c5d6f6f37dca76b1c7c3
;; Package-Requires: ((emacs "24.4"))
;; Keywords: convenience

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

;; * org-picklink's README                        :README:

;; This package contains the command `org-picklink' which pops
;; up a org-agenda window as link chooser, user can
;; pick a headline in this org-agenda window, then insert
;; its link to origin org-mode buffer.

;; [[./snapshots/org-picklink.gif]]

;; The simplest installation method is to call:

;; #+begin_example
;; (define-key org-mode-map "\C-cj" 'org-picklink)
;; #+end_example

;;; Code:
;; * org-picklink's code                         :CODE:
(require 'subr-x)
(require 'org-agenda)

;;;###autoload
(defvar org-picklink-links nil
  "Record all links info.")

(defvar org-picklink-link-type 'headline
  "The link type used to store.")

(defvar org-picklink-enable-breadcrumbs nil)

(defvar org-picklink-breadcrumbs-separator "/"
  "The separator used by org-picklink's breadcrumbs.")

(defvar org-picklink-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap "q" 'org-picklink-quit-window)
    (define-key keymap "i" 'org-picklink-store-link)
    (define-key keymap "b" 'org-picklink-toggle-breadcrumbs)
    (define-key keymap "t" 'org-picklink-set-link-type)
    (define-key keymap (kbd "<return>") 'org-picklink-store-link-and-quit-window)
    keymap)
  "Keymap for org picklink mode.")

(defvar org-picklink-buffer nil
  "The buffer calling `org-picklink'.")

;;;###autoload
(defun org-picklink-store-link (&optional breadcrumbs)
  "Store id link of current headline.

If BREADCRUMBS is t, breadcurmbs will be included in link
description."
  (interactive "P")
  (let ((org-agenda-show-outline-path nil)
        (selected-string
         (when mark-active
           (buffer-substring-no-properties
            (region-beginning) (region-end)))))
    (deactivate-mark)
    (org-with-point-at (or (org-get-at-bol 'org-hd-marker)
		           (org-agenda-error))
      (let* ((id (org-id-get (point) t))
             (attach-dir (org-attach-dir t))
             (breadcrumbs
              (when (or breadcrumbs
                        org-picklink-enable-breadcrumbs)
                (let ((s (org-format-outline-path
                          (org-get-outline-path)
                          (1- (frame-width))
                          nil org-picklink-breadcrumbs-separator)))
                  (if (eq "" s) "" (concat s org-picklink-breadcrumbs-separator)))))
             (item (or selected-string
                       (concat breadcrumbs
                               (org-entry-get (point) "ITEM"))))
             (link
              (cl-case org-picklink-link-type
                (headline (list :link (concat "id:" id) :description item :type "id"))
                (attach (list :link attach-dir :description (concat item "(ATTACH)") :type "file")))))
        (if (member link org-picklink-links)
            (message "This link has been stored, ignore it!")
          (message "Store link: [[%s][%s]]"
                   (concat (substring (plist-get link :link) 0 9) "...")
                   (plist-get link :description))
          (push link org-picklink-links))))
    (org-agenda-next-item 1)))

(defun org-picklink-toggle-breadcrumbs ()
  "Toggle org picklink breadcrumbs."
  (interactive)
  (setq org-picklink-enable-breadcrumbs
        (not org-picklink-enable-breadcrumbs))
  (if org-picklink-enable-breadcrumbs
      (message "org-picklink: breadcrumbs is enabled.")
    (message "org-picklink: breadcrumbs is disabled.")))

(defun org-picklink-set-link-type ()
  "Set the link type"
  (interactive)
  (setq org-picklink-link-type
        (intern (completing-read "Link type: " '(headline attach))))
  (message "org-picklink: use %s link type." org-picklink-link-type))

(defun org-picklink-grab-word ()
  "Grab word at point, which used to build search string."
  (buffer-substring
   (point)
   (save-excursion
     (skip-syntax-backward "w_")
     (point))))

;;;###autoload
(defun org-picklink-quit-window ()
  "Quit org agenda window and insert links to org mode buffer."
  (interactive)
  (setq header-line-format nil)
  (setq org-picklink-link-type 'headline)
  (setq org-picklink-enable-breadcrumbs nil)
  (org-picklink-mode -1)
  (let ((org-agenda-sticky t))
    (org-agenda-quit))
  (if (not (bufferp org-picklink-buffer))
      (message "org-picklink-buffer is not a valid buffer")
    (switch-to-buffer org-picklink-buffer)
    (setq org-picklink-links
          (reverse org-picklink-links))
    ;; When a link is found at point, insert ", "
    (when (save-excursion
            (let* ((end (point))
                   (begin (line-beginning-position))
                   (string (buffer-substring-no-properties
                            begin end)))
              (and (string-match-p "]]$" string)
                   (not (string-match-p ", *$" string)))))
      (insert ", "))
    (dolist (link org-picklink-links)
      (org-insert-link nil (plist-get link :link) (plist-get link :description))
      (pop org-picklink-links)
      (when org-picklink-links
        (cond ((org-in-item-p)
               (call-interactively #'org-insert-item))
              (t (insert " ")))))))

;;;###autoload
(defun org-picklink-store-link-and-quit-window ()
  "Store link then quit org agenda window."
  (interactive)
  (call-interactively 'org-picklink-store-link)
  (org-picklink-quit-window))

;;;###autoload
(defun org-picklink (&optional search-tag)
  "Open org agenda window as a link selector.

if region is actived, ‘org-agenda’ will search string
in region and replace it with selected link.

When SEARCH-TAG is t, use `org-tags-view' instead
of `org-search-view'.

This command only useful in org mode buffer."
  (interactive "P")
  (if (not (derived-mode-p 'org-mode))
      (message "org-picklink works only in org-mode!")
    (setq org-picklink-buffer (current-buffer))
    (let ((org-agenda-sticky t)
          (org-agenda-window-setup 'current-window)
          (search-string
           (when mark-active
             (buffer-substring-no-properties
              (region-beginning) (region-end))))
          (string-at-point
           (org-picklink-grab-word)))
      ;; Call org-agenda
      (when (and search-string (> (length search-string) 0))
        (delete-region (region-beginning) (region-end)))
      (if search-tag
          (org-tags-view nil search-string)
        (if search-string
            (org-search-view nil search-string)
          (org-search-view nil string-at-point t)))
      ;; Update `header-line-format'
      (with-current-buffer (get-buffer org-agenda-buffer-name)
        (org-picklink-mode 1)
        (setq header-line-format
              (format
               (substitute-command-keys
                (concat
                 "## "
                 "`\\[org-picklink-store-link]':Store Link  "
                 "`\\[org-picklink-quit-window]':Quit  "
                 "`\\[org-picklink-store-link-and-quit-window]':Store and Quit  "
                 "`\\[org-picklink-toggle-breadcrumbs]':Breadcrumbs  "
                 "`\\[org-picklink-set-link-type]':Link Type "
                 "##"))
               (buffer-name org-picklink-buffer)))))))

(define-minor-mode org-picklink-mode
  "org picklink mode"
  nil " org-picklink")

(provide 'org-picklink)

;; Local Variables:
;; coding: utf-8-unix
;; End:

;;; org-picklink.el ends here
