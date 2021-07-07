;;; orgtbl-show-header.el --- Show the header of the current column in the minibuffer

;; Copyright (C) 2014 Damien Cassou

;; Author: Damien Cassou <damien.cassou@gmail.com>
;; Version: 0.1
;; Package-Version: 20141023.837
;; Package-Commit: 112d54a44682f065318ed0c9c89a8f5b8907342a

;; This file is not part of GNU Emacs.

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

;;; Commentary:

;; Show the header of the current column in the minibuffer

;;; Code:

(require 'org-table)

;;;###autoload
(defun orgtbl-show-header-of-current-column ()
  "In a table, show the header of the column the point is in."
  (interactive)
  (let ((message-log-max nil))
    (message "%s" (substring-no-properties (org-table-get 1 nil)))))

(defadvice org-table-next-field (after orgtbl-show-header-after-next-field last)
  "Call `orgtbl-show-header-of-current-column`."
  (orgtbl-show-header-of-current-column))

(ad-disable-advice 'org-table-next-field 'after 'orgtbl-show-header-after-next-field)
(ad-activate 'org-table-next-field)

(defadvice org-table-previous-field (after orgtbl-show-header-after-previous-field last)
  "Call `orgtbl-show-header-of-current-column`."
  (orgtbl-show-header-of-current-column))

(ad-disable-advice 'org-table-previous-field 'after 'orgtbl-show-header-after-previous-field)
(ad-activate 'org-table-previous-field)

(defun orgtbl-show-header-activate ()
  "Configure \[org-table-next-field] to call `orgtbl-show-header-of-current-column`."
  (ad-enable-advice 'org-table-next-field 'after 'orgtbl-show-header-after-next-field)
  (ad-activate 'org-table-next-field)
  (ad-enable-advice 'org-table-previous-field 'after 'orgtbl-show-header-after-previous-field)
  (ad-activate 'org-table-previous-field))

(defun orgtbl-show-header-deactivate ()
  "Configure \[org-table-next-field] not to call `orgtbl-show-header-of-current-column`."
  (ad-disable-advice 'org-table-next-field 'after 'orgtbl-show-header-after-next-field)
  (ad-activate 'org-table-next-field)
  (ad-disable-advice 'org-table-previous-field 'after 'orgtbl-show-header-after-previous-field)
  (ad-activate 'org-table-previous-field))

;;;###autoload
(define-minor-mode orgtbl-show-header
  "Show current header while navigating in the table."
  nil ;; init value
  'orgtbl-head ;; lighter
  nil ;; keymap
  (if orgtbl-show-header
      (orgtbl-show-header-activate)
    (orgtbl-show-header-deactivate)))

(provide 'orgtbl-show-header)
;;; orgtbl-show-header.el ends here
