;;; el-secretario-elfeed.el --- Add notmuch email inboxes to el-secretario -*- lexical-binding: t; -*-
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
;; Keywords: convenience
;; Homepage: https://git.sr.ht/~zetagon/el-secretario
;; Package-Requires: ((emacs "27.1") (el-secretario "0.0.1") (elfeed "3.4.1"))
;;
;; This file is not part of GNU Emacs.
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
;;; Commentary:
;;
;; An elfeed source for el-secretario
;;
;;; Code:
(require 'el-secretario-source)
(require 'el-secretario)
(require 'elfeed)

(defclass el-secretario-elfeed-source (el-secretario-source)
  ((query :initarg :query)))
(defvar el-secretario-elfeed-map (let ((km (make-sparse-keymap)))
               (define-key km
                 "n" '("next" . el-secretario-next-item))
               (define-key km
                 "p" '("previous" . el-secretario-previous-item))
               (define-key km
                 "+" '("Add tag" . elfeed-show-tag))
               (define-key km
                 "-" '("Remove tag" . elfeed-show-untag))
               (define-key km
                 "c" '("Org Capture" . org-capture))
               (define-key km
                 "o" '("Open in browser" . elfeed-show-visit))
               km))



;;;###autoload
(defun el-secretario-elfeed-make-source (&optional query keymap)
  "Convenience macro for creating a source for elfeed.
QUERY is a normal elfeed query.
KEYMAP is a keymap to use during review of this source"
  (el-secretario-elfeed-source
   :keymap (or keymap 'el-secretario-elfeed-map)
   :query query))

(cl-defmethod el-secretario-source-activate ((obj el-secretario-elfeed-source) &optional backwards)
  "See `el-secretario-source.el'.
OBJ BACKWARDS."
  (with-slots (query) obj
    (setq elfeed-show-entry-delete 'elfeed-kill-buffer)
    (setq elfeed-show-entry-switch (lambda (x) (switch-to-buffer x nil t)))
    (when query
      (elfeed-search-set-filter query))

    (elfeed)

    (setq elfeed-sort-order 'ascending)
    (sit-for 0.1)
    (if backwards
        (progn
          (goto-char (point-max))
          (forward-line -1))
      (goto-char (point-min)))
    (call-interactively #'elfeed-search-show-entry)
    (el-secretario-activate-keymap)))

(cl-defmethod el-secretario-source-next-item ((_obj el-secretario-elfeed-source))
  "See `el-secretario-source.el'."
  (el-secretario-elfeed--show-next))

(defun el-secretario-elfeed--show-next ()
  "Show the next item in the elfeed-search buffer."
  ;; This code is copied and adapted from elfeed.
  (funcall elfeed-show-entry-delete)
  (with-current-buffer (elfeed-search-buffer)
    (when elfeed-search-remain-on-entry (forward-line 1))
    (if (string= "" (buffer-substring-no-properties (point-at-bol) (point-at-eol)))
        (el-secretario--next-source)
      (call-interactively #'elfeed-search-show-entry))))

(cl-defmethod el-secretario-source-previous-item ((_obj el-secretario-elfeed-source))
  "See `el-secretario-source.el'."
  (el-secretario-elfeed--show-prev))

(defun el-secretario-elfeed--show-prev ()
  "Show the previous item in the elfeed-search buffer."
  ;; This code is copied and adapted from elfeed.
  (funcall elfeed-show-entry-delete)
  (with-current-buffer (elfeed-search-buffer)
    (when elfeed-search-remain-on-entry (forward-line 1))
    (if (= (forward-line -2)
           -1)
        (el-secretario--previous-source))
    (call-interactively #'elfeed-search-show-entry)))

(provide 'el-secretario-elfeed)
;;; el-secretario-elfeed.el ends here
