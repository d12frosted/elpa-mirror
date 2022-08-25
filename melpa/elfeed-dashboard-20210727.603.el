;;; elfeed-dashboard.el --- An extensible frontend for elfeed using org-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Manoj Kumar Manikchand

;; Author: Manoj Kumar Manikchand <manojm321@protonmail.com>
;; URL: https://github.com/Manoj321/elfeed-dashboard
;; Package-Version: 20210727.603
;; Package-Commit: b143f8453aed2053e8fc6f05cef6233797408546
;; Keywords: convenience
;; Package-Requires: ((emacs "25.1")(elfeed "3.3.0"))
;; Version: 0.0.0

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;; For a quick demo, open the elfeed-dashboard.org file provided
;;; with this repo and enable elfeed-dashboard-mode to activate it.

;;; Code:
(require 'elfeed-search)
(require 'org-element)
(eval-when-compile (require 'subr-x))

(defvar elfeed-dashboard--elfeed-update-timer nil)
(defvar elfeed-dashboard--buf nil)

(defvar elfeed-dashboard-mode-map (make-sparse-keymap)
  "Keymap for `elfeed-dashboard-mode'.")

(defvar elfeed-dashboard-file "elfeed-dashboard.org")

(declare-function elfeed-org "elfeed-org")

;;;###autoload
(define-derived-mode elfeed-dashboard-mode org-mode "Dashboard"
  "Base mode for Dashboard modes.

\\{elfeed-dashboard-mode-map}"
  :group 'elfeed-dashboard
  (setq elfeed-dashboard--buf (current-buffer))
  (setq buffer-read-only t)
  (elfeed-dashboard-parse-keymap))

(defun elfeed-dashboard ()
  "Main function."
  (interactive)
  (setq elfeed-dashboard--buf (find-file elfeed-dashboard-file))
  (with-current-buffer elfeed-dashboard--buf
    (elfeed-dashboard-mode)
    (elfeed-dashboard-update-links)))

(defun elfeed-dashboard-edit ()
  "Edit dashboard."
  (interactive)
  (setq elfeed-dashboard-mode-map (make-sparse-keymap))
  (setq buffer-read-only nil)
  (org-mode))

(defun elfeed-dashboard-query (query)
  "Set the search filter to QUERY and call elfeed."
  (elfeed-search-set-filter query)
  (elfeed)
  (goto-char (point-min)))

(defun elfeed-dashboard-update ()
  "Fetch new feeds, Optionally try reading `elfeed-org' configuration."
  (interactive)
  (if (fboundp 'elfeed-org)
      (elfeed-org))
  (unless elfeed-dashboard--elfeed-update-timer
    (elfeed-update)
    (setq elfeed-dashboard--elfeed-update-timer
          (run-with-timer 1 1 (lambda ()
                                (if (> (elfeed-queue-count-total) 0)
                                    (message "elfeed: %d jobs pending.." (elfeed-queue-count-total))
                                  (cancel-timer elfeed-dashboard--elfeed-update-timer)
                                  (setq elfeed-dashboard--elfeed-update-timer nil)
                                  (elfeed-dashboard-update-links)
                                  (message "elfeed: Updated!")))))))

(defun elfeed-dashboard--get-keymap (key)
  "Return the right keymap depending on the number of chars in the KEY.

Assumes a max KEY length of 2."
  (if (> (length key) 2)
      (user-error "Key exceeds a max length of 2: %s" key))
  (if (eq (length key) 1)
      elfeed-dashboard-mode-map
    ;; 2 letter key
    (let* ((prefix-key (substring key 0 1))
           (binding (local-key-binding (kbd prefix-key))))
      (unless binding
        (define-key elfeed-dashboard-mode-map (kbd prefix-key) (make-sparse-keymap)))
       (key-binding (kbd prefix-key)))))

(defun elfeed-dashboard-parse-keymap ()
  "Install key binding defined as KEYMAP:VALUE.

VALUE is composed of \"keybinding | function-call\" with
keybidning begin a string describing a key sequence and a call to
an existing function. For example, to have 'q' to kill the
current buffer, the syntax would be:

#+KEYMAP: q | kill-current-buffer

This can be placed anywhere in the org file even though I advise
to group keymaps at the same place."

  (org-element-map (org-element-parse-buffer) 'keyword
    (lambda (keyword)
      (when (string= (org-element-property :key keyword) "KEYMAP")
        (let* ((value (org-element-property :value keyword))
               (key   (string-trim (nth 0 (split-string value "|"))))
               (call  (string-trim (nth 1 (split-string value "|"))))
               (map (elfeed-dashboard--get-keymap key))
               (suffix-key (if (eq (length key) 1)
                               key
                             (substring key 1 2))))
          (define-key map (kbd suffix-key)
            (eval (car (read-from-string
                        (format "(lambda () (interactive) (%s))" call))))))))))

(defun elfeed-dashboard-query-count (query)
  "Return the number of feeds returned by the QUERY."
  (let* ((count 0)
         (filter (elfeed-search-parse-filter query))
         (func (byte-compile (elfeed-search-compile-filter filter))))
    (with-elfeed-db-visit (entry feed)
      (when (funcall func entry feed count)
        (setf count (1+ count))))
    count))

(defun elfeed-dashboard-update-link (link)
  "Update LINK of the format elfeed:query description with count.

Ex: [[elfeed:flag:unread +emacs][---]].  If the descriptions
string(---) doesn't have enough space then the count will be
trimmed and the last digit will be replace with +"

  (let* ((path  (org-element-property :path link))
         (query (string-trim path))
         (beg   (org-element-property :contents-begin link))
         (end   (org-element-property :contents-end link))
         (size  (- end beg)))
    (if (> size 0)
        (let* ((count (elfeed-dashboard-query-count query))
               (output (format (format "%%%dd" size) count))
               (modified (buffer-modified-p))
               (inhibit-read-only t))
          (save-excursion
            (delete-region beg end)
            (goto-char beg)
            (insert (if (<= (length output) size)
                        output
                      (concat (substring output 0 (- size 1)) "+"))))
          (set-buffer-modified-p modified)))))

(defun elfeed-dashboard-update-links (&rest _)
  "Update content of all links."
  (interactive)
  (with-current-buffer elfeed-dashboard--buf
    (org-element-map (org-element-parse-buffer) 'link
      (lambda (link)
        (when (string= (org-element-property :type link) "elfeed")
          (elfeed-dashboard-update-link link))))))

(provide 'elfeed-dashboard)
;;; elfeed-dashboard.el ends here
