;;; fsbot-data-browser.el --- browse the fsbot database using tabulated-list-mode
;;
;; Filename: fsbot-data-browser.el
;; Description: Browse the fsbot database using tabulated-list-mode
;; Author: Benaiah Mischenko
;; Maintainer: Benaiah Mischenko
;; Created: Thu September 15 2016
;; Version: 0.3
;; Package-Version: 20220830.230
;; Package-Commit: 27455860fec01ca47bf98b85f093cc24b9852bef
;; Package-Requires: ()
;; Last-Updated: Thu September 15 2016
;;           By: Benaiah Mischenko
;;     Update #: 3
;; URL: http://github.com/benaiah/fsbot-data-browser
;; Doc URL: http://github.com/benaiah/fsbot-data-browser
;; Keywords: fsbot, irc, tabulated-list-mode
;; Compatibility: GNU Emacs: 24.4 and up, 25.x
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; This is a simple mode that lets you download and view the fsbot
;; database in tabulated-list-mode.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defvar fsbot-data)

;;;###autoload
(defun fsbot-download-data ()
  "Download fsbot db for viewing. You must do this before you can use `fsbot-view-data'."
  (interactive)
  (url-retrieve
   "http://gnufans.net/~fsbot/data/botbbdb"
   (lambda (&rest _)
     (write-region nil nil "~/.emacs.d/.fsbot-data-raw" nil)
     (message "fsbot data finished downloading")
     (fsbot-load-data))))

(defalias 'fsbot-refresh-data 'fsbot-download-data)

(defun fsbot-slurp-file-into-buffer (filename)
  (insert-file-contents filename)
  (buffer-substring-no-properties (point-min) (point-max)))

(defun fsbot-parse-data ()
  (goto-char 0)
  (let ((ret '()))
    (while (search-forward "[" nil t)
      (push (read-from-string (thing-at-point 'line t)) ret))
    ret))

(defun fsbot-process-notes (notes)
  (if notes
      (let ((real-notes (car (read-from-string notes))))
        (cond ((not real-notes) "nil")
              ((stringp real-notes) real-notes)
              ((and (listp real-notes)
                    (= 1 (length real-notes))
                    (stringp (car real-notes)))
               (car real-notes))
              (t (format "%S" real-notes))))
    "nil"))

(defun fsbot-load-data ()
  (let* ((fsbot-parsed-data
          (with-temp-buffer (fsbot-slurp-file-into-buffer "~/.emacs.d/.fsbot-data-raw")
                            (fsbot-parse-data)))
         (loaded-fsbot-data
          (mapcar (lambda (entry)
                    (let ((key (aref (car entry) 0))
                          (notes (fsbot-process-notes
                                  (cdr (car (aref (car entry) 8))))))
                      `(,key [,key ,notes])))
                  fsbot-parsed-data)))
    (setq fsbot-data loaded-fsbot-data)
    loaded-fsbot-data))

(defun fsbot-get-entry (entry-title)
  (car (cdr (cl-find-if
             (lambda (entry) (string-equal (car entry) entry-title))
             fsbot-data))))

(defun fsbot-get-title-of-entry (entry)
  (elt entry 0))

(defun fsbot-get-text-of-entry (entry)
  (elt entry 1))

(defun fsbot-display-entry (title)
  (interactive (list (completing-read "Fsbot entry: " fsbot-data)))
  (pop-to-buffer "*fsbot entry*")
  (erase-buffer)
  (let ((text (fsbot-get-text-of-entry (fsbot-get-entry title))))
    (insert (format "%s is \n%s" title
                    (let ((text-as-list (car (read-from-string (string-trim text))))
                          (current-entry -1))
                      (if (and (listp text-as-list)
                               (< 0 (length text-as-list)))
                          (string-join (mapcar (lambda (el)
                                                 (cl-incf current-entry)
                                                 (format "[%s]: %s\n" current-entry el))
                                               text-as-list))
                        text))))))

(define-derived-mode fsbot-data-browser-mode tabulated-list-mode
  "Fsbot Data Browser" "Tabulated-list-mode browser for fsbot data."
  (setq tabulated-list-format
        [("Key" 30
          ;; sorting function, for some reason tabulated-list-mode
          ;; defaults to a case-sensitive sort, which we don't want
          (lambda (entry-a entry-b)
            (let ((key-a (downcase (car entry-a)))
                  (key-b (downcase (car entry-b))))
              (string-lessp key-a key-b))))
         ("Notes" 0 nil)])
  (setq tabulated-list-padding 2)
  (setq tabulated-list-sort-key (cons "Key" nil))
  (tabulated-list-init-header))

(defun fsbot-list-data (data)
  (pop-to-buffer "*fsbot data*")
  (fsbot-data-browser-mode)
  (setq truncate-lines t)
  (setq tabulated-list-entries data)
  (tabulated-list-print t))

(defun fsbot-display-entry-at-point ()
  (interactive)
  (fsbot-display-entry (tabulated-list-get-id)))

(define-key fsbot-data-browser-mode-map (kbd "RET") 'fsbot-display-entry-at-point)

;;;###autoload
(defun fsbot-view-data ()
  "View fsbot db. You must call `fsbot-download-data' before this will work."
  (interactive)
  (let ((fsbot-viewable-data (if fsbot-data (copy-tree fsbot-data) (fsbot-load-data))))
    (fsbot-list-data fsbot-viewable-data)))

(provide 'fsbot-data-browser)

;;; fsbot-data-browser.el ends here
