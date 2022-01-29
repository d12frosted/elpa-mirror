;;; el-secretario-mu4e.el --- Add mu4e inboxes to el-secretario -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2020 Leo
;;
;; Author: Leo Okawa Ericson <http://github/Zetagon>
;; Maintainer: Leo <github@relevant-information.com>
;; Created: June 20, 2021
;; Modified: June 20, 2021
;; Version: 0.0.1
;; Package-Version: 20211214.1851
;; Package-Commit: 99f4d9d38b8e6a5b3f32bd4f6a3c7f68c2523dd9
;; Keywords: convenience mail
;; Homepage: https://git.sr.ht/~zetagon/el-secretario
;; Package-Requires: ((emacs "27.1")  (org-ql "0.6-pre") (el-secretario "0.0.1"))
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
;; The Emacs secretary that helps you through all your inboxes and tasks.  See
;; README.org
;;
;;
;;; Code:
(require 'el-secretario-source)
(require 'el-secretario)
(require 'mu4e)

(defclass el-secretario-mu4e-source (el-secretario-source)
  ((query :initarg :query)
   (init-function :initarg :init-function)))
(defvar el-secretario-mu4e-map (let ((km (make-sparse-keymap)))
               (define-key km
                 "n" '("next" . el-secretario-next-item))
               (define-key km
                 "p" '("previous" . el-secretario-previous-item))
               km))


(defvar el-secretario-mu4e--activate-backwards nil)

;;;###autoload
(defun el-secretario-mu4e-make-source (query &optional keymap init-function)
  "Convenience macro for creating a source for mu4e mail.
QUERY is a normal mu4e query.
KEYMAP is a keymap to use during review of this source.
INIT-FUNCTION is a function that is run before the source is initialized."
  (el-secretario-mu4e-source
   :keymap (or keymap 'el-secretario-mu4e-map)
   :query query
   :init-function (or init-function (lambda ()))))

(cl-defmethod el-secretario-source-activate ((obj el-secretario-mu4e-source) &optional backwards)
  "See `el-secretario-source.el'.
OBJ BACKWARDS."
  (with-slots (query init-function) obj
    (funcall init-function)
    (setq el-secretario-mu4e--activate-backwards backwards)
    (setq mu4e-split-view 'single-window)
    (add-hook 'mu4e-headers-found-hook #'el-secretario-mu4e--after-search-h)
    (mu4e-headers-search (or query "flag:unread"))
    (el-secretario-activate-keymap)))

(defun el-secretario-mu4e--after-search-h ()
  "Go to the correct message directly after search is complete.

Should be added to `mu4e-headers-found-hook'."
  (remove-hook 'mu4e-headers-found-hook #'el-secretario-mu4e--after-search-h)
  (when el-secretario-mu4e--activate-backwards
    (goto-char (point-max))
    (forward-line -1))
  (if (get-text-property (point) 'msg)
      (mu4e-headers-view-message)
    ;; Go to the next/previous source if there are no messages
    (if el-secretario-mu4e--activate-backwards
        (el-secretario--previous-source)
      (el-secretario--next-source))))

(cl-defmethod el-secretario-source-next-item ((_obj el-secretario-mu4e-source))
  "See `el-secretario-source.el'."
  (unless (mu4e-view-headers-next)
    (el-secretario--next-source)))


(cl-defmethod el-secretario-source-previous-item ((_obj el-secretario-mu4e-source))
  "See `el-secretario-source.el'."
  (unless (mu4e-view-headers-next -1)
    (el-secretario--previous-source)))

;; This is copied and adapted from mu4.
;; This fixes a bug in mu4e
;; It should return nil if it doesn't succeed in getting the previous message
(define-advice mu4e~headers-move (:override (lines))
    (unless (eq major-mode 'mu4e-headers-mode)
      (mu4e-error "Must be in mu4e-headers-mode (%S)" major-mode))
    (let* ((succeeded (zerop (forward-line lines)))
           (docid (mu4e~headers-docid-at-point)))
      (if succeeded
          ;; move point, even if this function is called when this window is not
          ;; visible
          (when docid
            ;; update all windows showing the headers buffer
            (walk-windows
             (lambda (win)
               (when (eq (window-buffer win) (mu4e-get-headers-buffer))
                 (set-window-point win (point))))
             nil t)
            (if (eq mu4e-split-view 'single-window)
                (when (eq (window-buffer) (mu4e-get-view-buffer))
                  (mu4e-headers-view-message))
              ;; update message view if it was already showing
              (when (and mu4e-split-view (window-live-p mu4e~headers-view-win))
                (mu4e-headers-view-message)))
            ;; attempt to highlight the new line, display the message
            (mu4e~headers-highlight docid)
            docid)
        nil)) )

(provide 'el-secretario-mu4e)
;;; el-secretario-mu4e.el ends here
