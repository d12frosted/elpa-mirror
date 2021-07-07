;;; elscreen-mew.el --- ElScreen Add-On for Mew
;; -*- Mode: Emacs-Lisp -*-

;; Copyright (C) 2013 by Takashi Masuda

;; Author: Takashi Masuda <masutaka.net@gmail.com>
;; URL: https://github.com/masutaka/elscreen-mew
;; Package-Version: 20160504.1835
;; Package-Commit: c90a23441d836da14a1cb12788432308ba58e2b6
;; Version: 1.0.2
;; Package-Requires: ((elscreen "20120413.807"))

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
;; This package is ElScreen Add-On for Mew.

;;; Installation:
;; Put `elscreen-mew.el' in the `load-path' and add
;;
;;   (require 'elscreen-mew)
;;
;; to your Mew init file.

;;; Code:

(require 'elscreen)

(defcustom elscreen-mew-mode-to-nickname-alist
  '(("^mew-draft-mode$" .
     (lambda ()
       (format "Mew(%s)" (buffer-name (current-buffer)))))
    ("^mew-" . "Mew"))
  "*Alist composed of the pair of mode-name and corresponding screen-name."
  :type '(alist :key-type string :value-type (choice string function))
  :tag "Mew major-mode to screen nickname alist"
  :set (lambda (symbol value)
         (custom-set-default symbol value)
         (elscreen-rebuild-mode-to-nickname-alist))
  :group 'mew)
(elscreen-set-mode-to-nickname-alist 'elscreen-mew-mode-to-nickname-alist)


(defadvice mew-buffer-message (after
			       mew-buffer-message-after-advice
			       activate)
  (setq ad-return-value
	(format "%s[%d]" ad-return-value (elscreen-get-current-screen))))

(provide 'elscreen-mew)

;;; elscreen-mew.el ends here
