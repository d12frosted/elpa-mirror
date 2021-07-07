;;; xwidgets-reuse.el --- Reuse xwidgets sessions to reduce resource consumption -*- lexical-binding: t -*-

;; Author: Boris Glavic <lordpretzel@gmail.com>
;; Maintainer: Boris Glavic <lordpretzel@gmail.com>
;; Version: 0.2
;; Package-Version: 20200817.147
;; Package-Commit: 5d56472dda53e43e0a11edcd373b44c0dbab47ce
;; Package-Requires: ((emacs "26.1"))
;; Homepage: https://github.com/lordpretzel/xwidgets-reuse
;; Keywords: hypermedia


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; Xwidget sessions are relatively heavy-weight.  This packages allows a single
;; xwidgets session to be reused for browsing.  This can be useful for tasks
;; like viewing html email in xwidgets or elfeed feeds or dash documentation.  To
;; customize behavior, you can register minor modes with `xwidgets-reuse' that
;; bind custom keys.  Call `xwidgets-reuse-register-minor-mode' to register your
;; minor mode.  Use `xwidgets-reuse-xwidget-reuse-browse-url(url &optional
;; use-minor-mode)' to browse `url' reusing an xwidget session.  This turns off
;; all minor modes registered with `xwidgets-reuse' in the reused xwidgets
;; session.  If `use-minor-mode' is provided, then this minor mode is turned on
;; in the xwidgets session.

;;; Code:

(require 'seq)
(require 'xwidget)

;; ********************************************************************************
;; customizations and defvars
(defcustom xwidgets-reuse-xwidgets-default-specialization-minor-modes
  nil
  "Minor modes applied to specialize xwidgets buffers for a purpose.
For example, such a purpose could be reading html email with mu4e.  Since we are
reusing a single xwidgets buffer, these minor modes need to be turned on / off
when reusing the buffer for a different purpose."
  :group 'xwidgets-reuse
  :type 'list)

(defvar xwidgets-reuse--xwidgets-specialization-minor-modes
  xwidgets-reuse-xwidgets-default-specialization-minor-modes
  "Current list of specialization minor modes.
Allows for runtime registration of new modes.")

;; ********************************************************************************
;; functions
(defun xwidgets-reuse-turn-off-all-xwidgets-specialization-minor-modes ()
  "Turn of all specialization minor modes for xwidgets."
  (with-current-buffer (current-buffer)
    (when (memq major-mode '(xwidget-webkit-mode))
      (dolist (mmode xwidgets-reuse--xwidgets-specialization-minor-modes)
        (funcall mmode -1)))))

;;;###autoload
(defun xwidgets-reuse-register-minor-mode (minor-mode)
  "Registers a MINOR-MODE with xwidgets-reuse.
This minor mode will automatically be turned off when another minor mode from
`xwidgets-reuse--xwidgets-specialization-minor-modes' is used through
`xwidgets-reuse-xwidget-reuse-browse-url'."
  (if (boundp minor-mode)
      (add-to-list 'xwidgets-reuse--xwidgets-specialization-minor-modes minor-mode)
    (error "`MINOR-MODE' needs to be a function corresponding to a minor mode")))

;;;###autoload
(defun xwidgets-reuse-xwidget-reuse-browse-url (url &optional use-minor-mode)
  "Open URL using xwidgets, reusing an existing xwidget buffer if possible.
Optional argument USE-MINOR-MODE is a minor mode to be activated
in the xwidgets session (e.g., for custom keybindings)."
  (interactive "sURL to browse in xwidgets: ")
  (let ((buf (car (seq-filter (lambda (x) (string-match "*xwidget webkit:" (buffer-name x))) (buffer-list)))))
    (if buf
        (progn (unless (eq (window-buffer) buf)
                 (switch-to-buffer buf))
               (xwidget-webkit-goto-url url))
      (xwidget-webkit-browse-url url))
    (xwidgets-reuse-turn-off-all-xwidgets-specialization-minor-modes)
    (when use-minor-mode
      (funcall use-minor-mode 1))))

;; ********************************************************************************
;; utility functions for minor modes to bind if they like to

;;;###autoload
(defun xwidgets-reuse-xwidget-external-browse-current-url ()
  "Externally browse url shown in current xwidget session."
  (interactive)
  (when (memq major-mode '(xwidget-webkit-mode))
    (let* ((urlstr (xwidget-webkit-current-url)))
      (browse-url urlstr))))

(provide 'xwidgets-reuse)
;;; xwidgets-reuse.el ends here
