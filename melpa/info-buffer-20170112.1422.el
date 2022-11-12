;;; info-buffer.el --- Display info topics in separate buffers

;; Copyright (C) 2015-2017 Lluís Vilanova
                                        ;
;; Author: Lluís Vilanova <vilanova@ac.upc.edu>
;; URL: http://www.github.com/llvilanova/info-buffer
;; Package-Version: 20170112.1422
;; Package-Commit: d35dad6e766c6e2ddb8dc6acb4ce5b6e10fbcaa7
;; Version: 0.2
;; Keywords: docs, info

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see http://www.gnu.org/licenses/.

;;; Commentary:
;;
;; Interactive command (`info-buffer') to display each info topic on its
;; separate buffer.  With prefix, display an already opened topic on a new
;; buffer.

;; If you're using `use-package', you can easily re-define Emacs's info binding
;; to use `info-buffer' instead:

;;   (use-package info-buffer
;;     :bind (("C-h i" . info-buffer)))

;;; Code:

(require 'info)


(defun info-buffer--open (topic bufname)
  "Open info on TOPIC in BUFNAME."
  (if (get-buffer bufname)
      (switch-to-buffer bufname)
    (info topic bufname)))

;;;###autoload
(defun info-buffer (topic replicate)
  "Display Info TOPIC in its own buffer.

Displays TOPIC on the current window, and reuses an existing
buffer if it is already showing TOPIC.

With prefix, or if REPLICATE is non-nil, never reuse an existing
buffer."
  (interactive
   (list
    (progn
      (info-initialize)
      (completing-read "Display manual: "
		       (info--manual-names nil)
		       nil t))
    current-prefix-arg))
  (let ((bufname (format "*info: %s*" topic)))
    (when replicate
      (setq bufname (generate-new-buffer-name bufname)))
    (info-buffer--open topic bufname)))

(provide 'info-buffer)

;;; info-buffer.el ends here
