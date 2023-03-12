;;; isgd.el --- Shorten URLs using the isgd.com shortener service


;; Copyright (C) 2015  Chmouel Boudjnah <chmouel@chmouel.com>

;; Version: 20150414
;; Package-Version: 20150414.936
;; Package-Commit: 764306dadd5a9213799081a48aba22f7c75cca9a
;; Author: Chmouel Boudjnah <chmouel@chmouel.com>
;; URL: https://github.com/chmouel/isgd.el

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Simple mode to shorten URLs from Emacs.

;; Adapted from bitly.el from Jorgen Schaefer <forcer@forcix.cx>
;; available here https://github.com/jorgenschaefer/bitly-el

;; Use (isgd-shorten URL) from an Emacs Lisp program, or
;; M-x isgd-url-at-point to replace the URL at point (or the region)
;; with a shortened version.

;;; Code:
(require 'thingatpt)
(require 'url-util)

;; User variables
(defvar isgd-base-url "http://is.gd/api.php")

;; Functions
(defun isgd-shorten (long-url)
  (let ((buf (url-retrieve-synchronously
              (format "%s?longurl=%s"
                      isgd-base-url (url-hexify-string long-url)))))
    (with-current-buffer buf
      (goto-char (point-min))
      (search-forward "\n\n" nil t)
      (let ((beg (point)))
        (end-of-line)
        (filter-buffer-substring beg (point))))))

;;;###autoload
(defun isgd-at-point ()
  "Replace the URL at point with a shortened one.

With an active region, use the region contents as an URL."
  (interactive)
  (let ((bounds (if (use-region-p)
                    (cons (region-beginning)
                          (region-end))
                  (thing-at-point-bounds-of-url-at-point)))
        url)
    (if (not bounds)
        (error "No URL at point")
      (save-excursion
        (delete-region (car bounds) (cdr bounds))
        (goto-char (car bounds))
        (insert
         (isgd-shorten
          (buffer-substring-no-properties (car bounds)
                                          (cdr bounds))))))))

;;; End isgd.el ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'isgd)

;;; isgd.el ends here
