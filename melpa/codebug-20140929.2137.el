;;; codebug.el --- Interact with codebug

;; Copyright (C) 2014 Shane Dowling

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

;; Author: Shane Dowling
;; URL: http://www.shanedowling.com/
;; Package-Version: 20140929.2137
;; Package-Commit: ac0e4331ba94ccb5203fa492570e1ca6b90c3d52
;; Version: 0.0.1

;;; Change Log:

;;; Code:

;;;###autoload
(defun codebug ()
  "Run CodeBug."
  (interactive)
  (unless (eq system-type 'darwin)
    (error "Sorry, OSX support only."))
  (shell-command (format "open 'codebug://send?file=%s&line=%d&op=add&open=1'"
                         (or (buffer-file-name)
                             (error "Buffer is not visiting a file."))
                         (line-number-at-pos))))

(provide 'codebug)

;;; codebug.el ends here
