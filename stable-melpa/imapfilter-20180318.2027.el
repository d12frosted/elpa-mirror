;;; imapfilter.el --- run the imapfilter executable  -*- lexical-binding: t -*-

;; Copyright (C) 2015-2018  Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/imapfilter
;; Keywords: mail

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
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Run the `imapfilter' executable, showing progress in a buffer.

;;; Code:

(defgroup imapfilter nil
  "Run the `imapfilter' executable."
  :group 'mail)

(defcustom imapfilter-args '("-v")
  "The arguments for the `imapfilter' executable."
  :group 'imapfilter
  :type '(repeat string))

(defcustom imapfilter-update-buffer-height 8
  "Height of the `imapfile' update buffer."
  :group 'imapfilter
  :type 'integer)

;;;###autoload
(defun imapfilter ()
  "Run the `imapfilter' executable."
  (interactive)
  (message "Running imapfilter...")
  (let ((winconf (current-window-configuration))
        (win (split-window
              (frame-root-window)
              (- (window-height (frame-root-window))
                 imapfilter-update-buffer-height))))
    (with-current-buffer (get-buffer-create " *imapfilter*")
      (set-window-buffer win (current-buffer))
      (set-window-dedicated-p win t)
      (erase-buffer)
      (let ((default-process-coding-system
              (cons (coding-system-change-eol-conversion
                     (car default-process-coding-system) 'dos)
                    (coding-system-change-eol-conversion
                     (cdr default-process-coding-system) 'dos))))
        (apply #'call-process "imapfilter" nil (current-buffer) t
               imapfilter-args)))
    (set-window-configuration winconf))
  (message "Running imapfilter...done"))

;;; _
(provide 'imapfilter)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; imapfilter.el ends here
