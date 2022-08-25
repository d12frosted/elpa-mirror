;;; py-import-check.el --- Finds the unused python imports using importchecker

;; Copyright (C) 2013 Sibi

;; Author: Sibi <sibi@psibi.in>
;; Version: 0.2
;; Package-Version: 20130802.1111
;; Package-Commit: 38ad91e67047bd37231497d11d409d064d510f98
;; URL: https://github.com/psibi/emacs-py-import-check
;; Keywords: python, import, check

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

;;; Code:

(defvar py-import-check-hist nil)

(defgroup py-import-check nil
  "Run importchecker putting hits in a grep buffer."
  :group 'tools
  :group 'processes)

(defcustom py-import-check-cmd "importchecker"
  "The py-import-check command."
  :type 'string
  :group 'py-import-check)

;;;###autoload
(defun py-import-check ()
  (interactive)
  (let* ((cmd (read-shell-command "Command: " (concat py-import-check-cmd " " (file-name-nondirectory (or (buffer-file-name) ""))) 'py-import-check-hist))
         (null-device nil))
    (grep cmd)))

(provide 'py-import-check)

;;; py-import-check.el ends here
