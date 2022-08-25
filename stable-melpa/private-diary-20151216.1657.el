;;; private-diary.el --- maintain a private diary in Emacs

;; Copyright (C)  2015  James P. Ascher

;; Author: James P. Ascher <jpa4q@virginia.edu>
;; Keywords: diary, encryption
;; Package-Version: 20151216.1657
;; Package-Commit: 5b1aeb22f22447fd35e1c107b6db44a7b27b8a42
;; URL: https://github.com/cacology/private-diary

;; Version: 1.0
;; Package-Requires: ((emacs "24.0"))

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
;; This package supports a private diary file that functions like the
;; existing Emacs diary, but can be encrypted while leaving the
;; non-private diary in plain text.  Documentation on
;; https://github.com/cacology/private-diary

;;; Code:

(require 'diary-lib)

(defgroup private-diary nil
  "Variables for the private-diary package."
  :prefix "private-diary"
  :group 'files
  :link '(url-link :tag "Github" "https://github.com/cacology/private-diary")
  )

(defcustom private-diary-file "~/private-diary.txt.gpg"
  "The file that is the other diary, not currently in use."
  :group 'private-diary
  :type '(file))

;;;###autoload
(defun private-diary-swap-with-diary nil
  "Swaps the values of the `diary-file' and `private-diary-file'."
  (interactive nil)
  (let ((old-diary-file diary-file))
    (setq diary-file private-diary-file)
    (setq private-diary-file old-diary-file)
    (message "Diary: %s Private: %s" diary-file private-diary-file)))

(provide 'private-diary)
;;; private-diary.el ends here
