;;; ibuffer-tramp.el --- Group ibuffer's list by TRAMP connection
;;
;; Copyright (C) 2011 Svend Sorensen
;;
;; Author: Svend Sorensen <svend@ciffer.net>
;; Keywords: convenience
;; Package-Version: 20151118.1739
;; Package-Commit: bcad0bda3a67f55d1be936bf8fa9ef735fe1e3f3
;; X-URL: http://github.com/svend/ibuffer-tramp
;; URL: http://github.com/svend/ibuffer-tramp
;; Version: DEV
;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; This code is heavily based on Steve Purcell's ibuffer-vc
;; (http://github.com/purcell/ibuffer-vc).
;;
;; Adds functionality to ibuffer for grouping buffers by their TRAMP
;; connection.
;;
;;; Use:
;;
;; To group buffers by TRAMP connection:
;;
;;   M-x ibuffer-tramp-set-filter-groups-by-tramp-connection
;;
;; or, make this the default:
;;
;;   (add-hook 'ibuffer-hook
;;     (lambda ()
;;       (ibuffer-tramp-set-filter-groups-by-tramp-connection)
;;       (ibuffer-do-sort-by-alphabetic)))
;;
;; Alternatively, use `ibuffer-tramp-generate-filter-groups-by-tramp-connection'
;; to programmatically obtain a list of filter groups that you can
;; combine with your own custom groups.
;;
;;; Code:

;; requires

(require 'ibuffer)
(require 'ibuf-ext)
(require 'tramp)
(eval-when-compile
  (require 'cl))

(defun ibuffer-tramp-connection (buf)
  "Return a cons cell (method . host), or nil if the file is not
using a TRAMP connection"
  (let ((file-name (with-current-buffer buf (or buffer-file-name default-directory))))
    (when (tramp-tramp-file-p file-name)
      (let ((method (tramp-file-name-method (tramp-dissect-file-name file-name)))
	    (host (tramp-file-name-host (tramp-dissect-file-name file-name))))
	(cons method host)))))

;;;###autoload
(defun ibuffer-tramp-generate-filter-groups-by-tramp-connection ()
  "Create a set of ibuffer filter groups based on the TRAMP connection of buffers"
  (let ((roots (ibuffer-remove-duplicates
                (delq nil (mapcar 'ibuffer-tramp-connection (buffer-list))))))
    (mapcar (lambda (tramp-connection)
              (cons (format "%s:%s" (car tramp-connection) (cdr tramp-connection))
                    `((tramp-connection . ,tramp-connection))))
            roots)))

(define-ibuffer-filter tramp-connection
    "Toggle current view to buffers with TRAMP connection QUALIFIER."
  (:description "TRAMP connection"
                :reader (read-from-minibuffer "Filter by TRAMP connection (regexp): "))
  (ibuffer-awhen (ibuffer-tramp-connection buf)
    (equal qualifier it)))

;;;###autoload
(defun ibuffer-tramp-set-filter-groups-by-tramp-connection ()
  "Set the current filter groups to filter by TRAMP connection."
  (interactive)
  (setq ibuffer-filter-groups (ibuffer-tramp-generate-filter-groups-by-tramp-connection))
  (ibuffer-update nil t))

(provide 'ibuffer-tramp)
;;; ibuffer-tramp.el ends here
