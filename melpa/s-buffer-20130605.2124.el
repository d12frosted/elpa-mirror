;;; s-buffer.el --- s operations for buffers

;; Copyright (C) 2013  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Keywords: lisp
;; Created: 15th May 2013
;; Url: http://github.com/nicferrier/emacs-s-buffer
;; Package-requires: ((s "1.6.0")(noflet "0.0.3"))
;; Version: 0.0.4

;; This program is free software; you can redistribute it and/or modify
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

;; The awesome s library for EmacsLisp has great extensions for doing
;; string operations. Some of those operations would be useful on
;; buffers. So this is those operations fitted for buffers.

;;; Code:

(require 's)

(defun s-buffer-format (buffer replacer &optional data)
  (let ((str (with-current-buffer buffer (buffer-string))))
    (s-format str replacer data)))

(defmacro s-buffer-lex-format (buffer)
  "Use scope to resolve the variables in BUFFER.

The buffer form of `s-lex-format'."
  `(s-lex-format (with-current-buffer (eval ,buffer)
                   (buffer-string))))

(provide 's-buffer)

;;; s-buffer.el ends here
