;;; bookmark-view.el --- Bookmark views -*- lexical-binding: t -*-

;; Author: Daniel Mendler
;; Created: 2020
;; License: GPL-3.0-or-later
;; Version: 0.2
;; Package-Version: 20211019.511
;; Package-Commit: 06e41de8ed7050e70627203c93b6132fec7e88d8
;; Package-Requires: ((emacs "26"))
;; Homepage: https://github.com/minad/bookmark-view

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides commands which allow storing the window
;; configuration (called a view) as an Emacs bookmark. This way the view
;; is automatically persisted and can be restored after restart.

;;; Code:

(require 'bookmark)
(require 'seq)
(eval-when-compile
  (require 'subr-x))

(defgroup bookmark-view nil
  "Bookmark views."
  :group 'convenience
  :prefix "bookmark-view-")

(defcustom bookmark-view-name-format "<count> [%Y-%m-%d %H:%M] <buffers>"
  "Name format used for default name of new view bookmarks."
  :type 'string)

(defcustom bookmark-view-name-regexp "\\`[0-9]+ \\[[ 0-9:-]+\\] "
  "Regexp matching view names that can be popped."
  :type 'string)

(defcustom bookmark-view-filter-function
  #'bookmark-view-filter-default
  "Filter function called for each buffer.
Return t if the current buffer is supposed to be bookmarked."
  :type 'symbol)

(defvar bookmark-view-history nil
  "History of bookmark views used by `bookmark-view-read'.")

(defun bookmark-view-filter-default ()
  "Default filter function called for each buffer.
Return t if the current buffer is supposed to be bookmarked."
  (not (and (eq bookmark-make-record-function #'bookmark-make-record-default)
            (string-match-p "\\` " (buffer-name)))))

(defun bookmark-view--make-record ()
  "Return a new bookmark record for the current buffer, which must not have a backing file."
  (if (and (not buffer-file-name)
           (eq bookmark-make-record-function #'bookmark-make-record-default))
      `(,(bookmark-buffer-name)
        (buffer . ,(buffer-name))
        (handler . ,#'bookmark-view-handler-fallback))
    (bookmark-make-record)))

(defun bookmark-view--buffers (&optional frame)
  "Return list of buffers of FRAME to be bookmarked."
  (seq-filter (lambda (x)
                (with-current-buffer x
                  (funcall bookmark-view-filter-function)))
              (mapcar #'window-buffer (window-list frame 'no-minibuf))))

(defun bookmark-view--get (&optional frame)
  "Get view state of FRAME as a bookmark record."
  (let ((bufs (bookmark-view--buffers)))
    `((buffer . ,(mapcar (lambda (x)
                           (with-current-buffer x
                             (bookmark-view--make-record)))
                         bufs))
      (filename . ,(format "*View[%s]*" (length bufs)))
      (window . ,(window-state-get (frame-root-window frame) 'writable))
      (handler . ,#'bookmark-view-handler))))

(defun bookmark-view--put (state &optional frame)
  "Put view STATE into FRAME, restoring windows and buffers."
  (save-window-excursion
    (dolist (buf (alist-get 'buffer state))
      (condition-case err
          (bookmark-jump buf #'ignore)
        (error (delay-warning 'bookmark-view (format "Error %S when opening %S" err buf))))))
  (window-state-put (alist-get 'window state) (frame-root-window frame)))

(defun bookmark-view-default-name (&optional frame)
  "Default name for current view of FRAME."
  (replace-regexp-in-string
   "<count>"
   (number-to-string
    (1+ (seq-count
         (apply-partially #'string-match-p bookmark-view-name-regexp)
         (bookmark-view-names))))
   (replace-regexp-in-string
    "<buffers>"
    (string-join (sort (mapcar #'buffer-name (bookmark-view--buffers frame))
                       #'string-lessp) " ")
    (let ((system-time-locale "C"))
      (format-time-string bookmark-view-name-format))
    'fixedcase 'literal)
   'fixedcase 'literal))

(defun bookmark-view--group (name transform)
  "Group function for bookmark named NAME.
For TRANSFORM non-nil return transformed bookmark name."
  (cond
   (transform name)
   ((string-match-p bookmark-view-name-regexp name) "Stack")
   (t "Named")))

(defun bookmark-view-read (prompt &optional default)
  "Prompting with PROMPT for bookmarked view. Return DEFAULT if user input is empty."
  (completing-read prompt
                   (let ((names (bookmark-view-names)))
                     (lambda (str pred action)
                       (if (eq action 'metadata)
                           `(metadata (category . bookmark)
                                      (group-function . ,#'bookmark-view--group))
                         (complete-with-action action names str pred))))
                   nil nil nil 'bookmark-view-history default))

;;;###autoload
(defun bookmark-view-names ()
  "Return a list of names of all view bookmarks."
  (bookmark-maybe-load-default-file)
  (mapcar #'car (seq-filter (lambda (x)
                              (eq #'bookmark-view-handler (alist-get 'handler (cdr x))))
                            bookmark-alist)))

;;;###autoload
(defun bookmark-view-handler-fallback (bm)
  "Handle buffer bookmark BM, used for buffers without file."
  (let* ((bm (bookmark-get-bookmark-record bm))
         (name (alist-get 'buffer bm)))
    (unless (get-buffer name)
      (with-current-buffer (get-buffer-create name)
        (insert (format "bookmark-view: Buffer %s not found" name))))))

;;;###autoload
(defun bookmark-view-handler (bm)
  "Handle view bookmark BM."
  ;; Restore the view in the bookmark-after-jump-hook, since
  ;; it must happen after the execution of the display function.
  (letrec ((hook (lambda ()
                   (setq bookmark-after-jump-hook (delq hook bookmark-after-jump-hook))
                   (bookmark-view--put (bookmark-get-bookmark-record bm)))))
    (push hook bookmark-after-jump-hook)))

;;;###autoload
(defun bookmark-view (name)
  "If view bookmark NAME exists, open it, otherwise save current view under the given NAME."
  (interactive (list (bookmark-view-read "View: " (bookmark-view-default-name))))
  (if (assoc name bookmark-alist)
      (bookmark-view-open name)
    (bookmark-view-save name)))

;;;###autoload
(defun bookmark-view-save (name &optional no-overwrite)
  "Save current view under the given NAME.
If NO-OVERWRITE is non-nil push to the bookmark list without overwriting an already existing bookmark."
  (interactive (list (bookmark-view-read "Save view: " (bookmark-view-default-name))))
  (bookmark-store name (bookmark-view--get) no-overwrite)
  (message "View `%s' saved" name))

;;;###autoload
(defun bookmark-view-open (bm)
  "Open view bookmark BM."
  (interactive (list (bookmark-view-read "Open view: ")))
  (bookmark-jump bm #'ignore))

;;;###autoload
(defun bookmark-view-delete (name)
  "Delete view bookmark NAME."
  (interactive (list (bookmark-view-read "Delete view: ")))
  (bookmark-delete name)
  (message "View `%s' deleted" name))

;;;###autoload
(defun bookmark-view-rename (old &optional new)
  "Rename bookmark from OLD name to NEW name."
  (interactive (list (bookmark-view-read "Old view name: ")))
  (bookmark-rename old new))

;;;###autoload
(defun bookmark-view-push ()
  "Save current view as a bookmark with a default name."
  (interactive)
  (let ((name (bookmark-view-default-name)))
    (bookmark-view-save name 'no-overwrite)
    ;; Add to view history to mark the new item as recent
    (add-to-history 'bookmark-view-history name)))

;;;###autoload
(defun bookmark-view-pop ()
  "Pop a view with a name matching `bookmark-view-name-regexp' from the bookmark list."
  (interactive)
  (let ((name (or (seq-find
                   (apply-partially #'string-match-p bookmark-view-name-regexp)
                   (bookmark-view-names))
                  (user-error "View stack is empty"))))
    (bookmark-view-open name)
    (bookmark-view-delete name)))

(provide 'bookmark-view)
;;; bookmark-view.el ends here
