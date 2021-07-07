;;; go-fill-struct.el --- Fill struct for golang.    -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Sergey Kostyaev <feo.me@ya.ru>

;; Author:  Sergey Kostyaev <feo.me@ya.ru>
;; Keywords: tools
;; Package-Version: 20171225.331
;; Package-Commit: a613d0b378473eef39e8fd5724abe790aea84321

;; Version:  0.1.0
;; URL: https://github.com/s-kostyaev/go-fill-struct
;; Package-Requires: ((emacs "24"))

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

;; For use this packages you should install `fillstruct' first:
;; % go get -u github.com/davidrjenni/reftools/cmd/fillstruct

;;; Code:

(require 'json)

(defvar go-fill-struct--buf nil
  "Currently used go buffer for fillstruct.")

;;;###autoload
(defun go-fill-struct ()
  "Fill go struct at point."
  (interactive)
  (save-buffer)
  (setq go-fill-struct--buf (buffer-name))
  (let* ((cmd
          (format
           "fillstruct -file %s -offset %s"
           (shell-quote-argument (buffer-file-name))
           (- (point) 1)))
         (proc (start-process-shell-command "fillstruct" "*fillstruct*" cmd))
         (sentinel (lambda (_proc _state)
                     (with-current-buffer "*fillstruct*"
                       (ignore-errors
                         (let* ((json-object-type 'hash-table)
                                (json-array-type 'list)
                                (json-key-type 'string)
                                (json (json-read-from-string
                                       (buffer-substring-no-properties (point-min) (point-max))))
                                (json-data (or (car-safe json) json))
                                (begin (+ (gethash "start" json-data) 1))
                                (end (+ (gethash "end" json-data) 1))
                                (content (gethash "code" json-data)))
                           (with-current-buffer go-fill-struct--buf
                             (delete-region begin end)
                             (goto-char begin)
                             (insert content)
                             (goto-char begin)
                             (goto-char (line-end-position)))))
                       (kill-buffer)))))
    (set-process-sentinel proc sentinel)))


(provide 'go-fill-struct)
;;; go-fill-struct.el ends here
