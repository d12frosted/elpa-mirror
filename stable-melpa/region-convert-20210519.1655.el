;;; region-convert.el --- Convert string in region by Lisp function -*- lexical-binding: t -*-

;; Copyright (C) 2021 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 19 Nov 2016
;; Version: 1.0.0
;; Package-Version: 20210519.1655
;; Package-Commit: cb3ab0417d7b74e5edd34bf23a70737fc7bf1d3a
;; Package-Requires: ((emacs "24.3"))
;; Keywords: region convenience
;; Homepage: https://github.com/zonuexe/right-click-context
;; License: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;; ## Interactive
;;;
;;;  1. Select text region (mark region)
;;;  2. M-x region-convert (or press binding key)
;;;  3. Input function name
;;;
;;; ### Key binding
;;;
;;;      (global-set-key (kbd "C-c r") 'region-convert)
;;;
;;; ## Use from Lisp
;;;
;;;     (region-convert 5 22 'upcase)
;;;

;;; Code:

;;;###autoload
(defun region-convert (begin end callback &rest args)
  "Convert string in region(BEGIN to END) by CALLBACK function call with additional arguments ARGS."
  (interactive "r\na")
  (let ((region-string (buffer-substring-no-properties begin end))
        result)
    (setq result (apply callback region-string args))
    (if (null result)
        (error "Convert Error")
      (save-excursion
        (goto-char end)
        (delete-region begin end)
        (insert result)
        (set-mark begin)))))

(provide 'region-convert)
;;; region-convert.el ends here
