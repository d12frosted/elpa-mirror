;;; org-ivy-search.el --- Full text search for org files powered by ivy -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2023 Huming Chen

;; Author: Huming Chen <chenhuming@gmail.com>
;; URL: https://github.com/beacoder/org-ivy-search
;; Package-Version: 20230111.334
;; Package-Commit: 47eaa5c91a107c4867af8cba17cb1195353a39cb
;; Version: 0.1.2
;; Created: 2021-03-12
;; Keywords: convenience, tool, org
;; Package-Requires: ((emacs "25.1") (ivy "0.10.0") (org "0.10.0"))

;; This file is not part of GNU Emacs.

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
;;
;; Full text search for org files powered by ivy
;;
;; Below are commands you can use:
;; `org-ivy-search-view'

;;; Change Log:
;;
;; 0.1.1 Use insert-file-contents to support chinese word.
;; 0.1.2 Don't limit search view by org outline level

;;; Code:

(require 'ivy)
(require 'org-agenda)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Definition
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar org-ivy-search-index-to-item-alist nil
  "The alist to store mapping from ivy-index to agenda-item.")

(defvar org-ivy-search-window-configuration nil
  "The window configuration to be restored upon closing the buffer.")

(defvar org-ivy-search-selected-window nil
  "The currently selected window.")

(defvar org-ivy-search-created-buffers ()
  "List of newly created buffers.")

(defvar org-ivy-search-previous-buffers ()
  "List of buffers created before opening org-ivy-search.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; steal from ag/dwim-at-point
(defun org-ivy-search--dwim-at-point ()
  "If there's an active selection, return that.
Otherwise, get the symbol at point, as a string."
  (cond ((use-region-p)
         (buffer-substring-no-properties (region-beginning) (region-end)))
        ((symbol-at-point)
         (substring-no-properties
          (symbol-name (symbol-at-point))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun org-ivy-search-view (&optional keyword)
  "Incremental `org-search-view' with initial-input KEYWORD."
  (interactive (list (org-ivy-search--dwim-at-point)))
  (let ((org-ivy-search-window-configuration (current-window-configuration))
        (org-ivy-search-selected-window (frame-selected-window))
        (org-ivy-search-created-buffers ())
        (org-ivy-search-previous-buffers (buffer-list)))
    (advice-add 'ivy-previous-line :after #'org-ivy-search-iterate-action)
    (advice-add 'ivy-next-line :after #'org-ivy-search-iterate-action)
    (add-hook 'minibuffer-exit-hook #'org-ivy-search-quit)
    (ivy-read "Org ivy search: " #'org-ivy-search-function
              :initial-input keyword
              :dynamic-collection t
              :caller #'org-ivy-search-view
              :action #'org-ivy-search-action)))

(defun org-ivy-search-visit-agenda-location (agenda-location)
  "Visit agenda location AGENDA-LOCATION."
  (when-let ((temp-split (split-string agenda-location ":"))
             (file-name (car temp-split))
             (line-nb-str (cadr temp-split))
             (line-nb (string-to-number line-nb-str))
             (is-valid-file (file-exists-p file-name))
             (is-valid-nb (integerp line-nb)))
    (find-file-read-only-other-window file-name)
    (with-no-warnings (goto-line line-nb)
                      (pulse-momentary-highlight-region (line-beginning-position) (line-end-position)))
    (unless (member
             (buffer-name (window-buffer))
             (mapcar (function buffer-name) org-ivy-search-previous-buffers))
      (add-to-list 'org-ivy-search-created-buffers (window-buffer)))))

(defun org-ivy-search-action (agenda-location)
  "Go to AGENDA-LOCATION."
  (when-let ((location (get-text-property 0 'location agenda-location)))
    (org-ivy-search-visit-agenda-location location)))

;; modified from org-search-view
(defun org-ivy-search-function (string)
  "Show all entries in agenda files that contain STRING."
  (or (ivy-more-chars)
      (progn
        ;; use fuzzy matching
        (setq string (replace-regexp-in-string " +" ".*" string))
        (let (files rtnall index file ee beg beg1 end txt rtn)
          (catch 'exit
            (setq files (org-agenda-files))
            ;; Uniquify files.  However, let `org-check-agenda-file' handle non-existent ones.
            (setq files (cl-remove-duplicates
                         (append files org-agenda-text-search-extra-files)
                         :test (lambda (a b)
                                 (and (file-exists-p a)
                                      (file-exists-p b)
                                      (file-equal-p a b))))
                  rtnall nil index 0 org-ivy-search-index-to-item-alist nil)
            ;; loop agenda files to find matched one
            (while (setq file (pop files))
              (setq ee nil)
              (catch 'nextfile
                (org-check-agenda-file file)
                ;; search matched text
                (with-temp-buffer
                  (insert-file-contents file)
                  (with-syntax-table (org-search-syntax-table)
                    (let ((case-fold-search t))
                      (widen)
                      (goto-char (point-min))
                      (unless (or (org-at-heading-p)
                                  (outline-next-heading))
                        (throw 'nextfile t))
                      (goto-char (max (point-min) (1- (point))))
                      ;; real match happens here
                      (while (re-search-forward string nil t)
                        (org-back-to-heading t)
                        (skip-chars-forward "* ")
                        (setq beg (point-at-bol)
                              beg1 (point)
                              end (progn
                                    (outline-next-heading)
                                    (point)))
                        (goto-char beg)
                        ;; save found text and its location
                        (setq txt
                              (propertize (buffer-substring-no-properties beg1 (point-at-eol))
                                          'location (format "%s:%d" file (line-number-at-pos beg))))
                        ;; save in map
                        (push (cons index txt) org-ivy-search-index-to-item-alist)
                        ;; save as return value
                        (push txt ee)
                        (goto-char (1- end))
                        (setq index (1+ index)))))))
              (setq rtn (nreverse ee))
              (setq rtnall (append rtnall rtn)))
            rtnall)))))

(defun org-ivy-search-iterate-action (&optional arg)
  "Preview agenda content while looping agenda, ignore ARG."
  (save-selected-window
    (when-let ((ignore arg)
               (is-map-valid org-ivy-search-index-to-item-alist)
               (item-found (assoc ivy--index org-ivy-search-index-to-item-alist))
               (item-content (cdr item-found))
               (location (get-text-property 0 'location item-content)))
      (org-ivy-search-visit-agenda-location location))))

(defun org-ivy-search-quit ()
  "Quit `org-ivy-search'."
  (let ((configuration org-ivy-search-window-configuration)
        (selected-window org-ivy-search-selected-window))
    (advice-remove 'ivy-previous-line #'org-ivy-search-iterate-action)
    (advice-remove 'ivy-next-line #'org-ivy-search-iterate-action)
    (remove-hook 'minibuffer-exit-hook #'org-ivy-search-quit)
    (set-window-configuration configuration)
    (select-window selected-window)
    (mapc 'kill-buffer-if-not-modified org-ivy-search-created-buffers)
    (setq org-ivy-search-created-buffers ())))


(provide 'org-ivy-search)
;;; org-ivy-search.el ends here
