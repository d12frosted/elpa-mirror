;;; el-secretario-notmuch.el --- Add notmuch inboxes to el-secretario -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2020 Leo
;;
;; Author: Leo Okawa Ericson <http://github/Zetagon>
;; Maintainer: Leo <github@relevant-information.com>
;; Created: September 20, 2020
;; Modified: October 17, 2020
;; Version: 0.0.1
;; Package-Version: 20211214.1851
;; Package-Commit: 99f4d9d38b8e6a5b3f32bd4f6a3c7f68c2523dd9
;; Keywords: convenience mail
;; Homepage: https://git.sr.ht/~zetagon/el-secretario
;; Package-Requires: ((emacs "27.1") (el-secretario "0.0.1") (notmuch "0.3.1"))
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file LICENSE.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; An notmuch source for el-secretario
;;
;;; Code:
(require 'el-secretario-source)
(require 'el-secretario)
(require 'notmuch)

(defclass el-secretario-notmuch-source (el-secretario-source)
  ((query :initarg :query)))

;;;###autoload
(defun el-secretario-notmuch-make-source (query &optional keymap)
  "Convenience macro for creating a source for notmuch mail.
QUERY is a normal notmuch query.
KEYMAP is a keymap to use during review of this source"
  (el-secretario-notmuch-source
   :keymap (or keymap 'el-secretario-source-default-map)
   :query query))

(cl-defmethod el-secretario-source-activate ((obj el-secretario-notmuch-source) &optional backwards)
  "See `el-secretario-source.el'.
OBJ BACKWARDS."
  (with-slots (query) obj
    (notmuch-search (or query "tag:unread")
                    t
                    nil
                    0
                    nil)
    (sit-for 0.1)
    (if backwards
        (notmuch-search-last-thread)
      (notmuch-search-first-thread))
    (el-secretario-notmuch--search-show-thread)
    (el-secretario-activate-keymap)))

(cl-defmethod el-secretario-source-next-item ((_obj el-secretario-notmuch-source))
  "See `el-secretario-source.el'."
  (el-secretario-notmuch-show-next-thread))
(cl-defmethod el-secretario-source-previous-item ((_obj el-secretario-notmuch-source))
  "See `el-secretario-source.el'."
  (el-secretario-notmuch-show-next-thread t))

;;
;; The logic for detecting when to call next-source or previous-source is quite
;; unintuitive. The text below is the content after calling `notmuch-search'.
;; The cursor is on the first line. `(el-secretario-notmuch--notmuch-show-next-thread t)' will try to
;; go up and fail because `(notmuch-search-previous-thread)' tries to up one
;; line and fails. In that case it returns nil and we should call
;; `el-secretario--previous-source'.
;;
;; The other case is when the cursor is on the second line.
;; `(el-secretario-notmuch--notmuch-show-next-thread)' will succed and place the cursor on the third
;; line. There `el-secretario-notmuch--search-show-thread' will fail because it
;; can't get a thread-id because it isn't on a line with a thread. In that case
;; we call `el-secretario--next-source'
;;
;; 2020-02-13 [1/1]   Sender foo    Subject a           (tagA)
;; 2020-06-08 [1/1]   Sender bar    Subject b           (tagB)
;; End of search results.

(defun el-secretario-notmuch-show-next-thread (&optional previous)
  "Like `notmuch-show-next-thread' but call `el-secretario-notmuch--search-show-thread' instead.

If PREVIOUS is non-nil, move to the previous item in the search
results instead."
  (interactive "P")
  ;; This code is copied and adapted from notmuch.
  (let ((parent-buffer notmuch-show-parent-buffer))
    (notmuch-bury-or-kill-this-buffer)
    (when (buffer-live-p parent-buffer)
      (switch-to-buffer parent-buffer)
      (and (if previous
	       (if (notmuch-search-previous-thread)
                   t
                 (el-secretario--previous-source)
                 nil)
	     (notmuch-search-next-thread))
	   (el-secretario-notmuch--search-show-thread previous)))))


(defun el-secretario-notmuch--search-show-thread (&optional elide-toggle)
  "Wrapper-function around `notmuch-search-show-thread'.

Like `notmuch-search-show-thread' but call
`el-secretario--next-source' if there are no more mail.
Pass ELIDE-TOGGLE to `notmuch-search-show-thread'."
  (interactive "P")
  ;; This code is copied and adapted from notmuch.
  (let ((thread-id (notmuch-search-find-thread-id))
        (subject (notmuch-search-find-subject)))
    (if (> (length thread-id) 0)
        (progn (notmuch-show thread-id
                             elide-toggle
                             (current-buffer)
                             notmuch-search-query-string
                             ;; Name the buffer based on the subject.
                             (concat "*"
                                     (truncate-string-to-width
                                      subject 30 nil nil t)
                                     "*"))
               (el-secretario-activate-keymap))
      (message "End of search results.")
      (el-secretario--next-source))))

(provide 'el-secretario-notmuch)
;;; el-secretario-notmuch.el ends here
