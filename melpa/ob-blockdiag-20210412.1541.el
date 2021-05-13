;;; ob-blockdiag.el --- org-babel functions for blockdiag evaluation

;; Copyright (C) 2017 Dmitry Moskowski

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Author: Dmitry Moskowski
;; Keywords: tools, convenience
;; Package-Commit: c3794bf7bdb8fdb3db90db41619dda4e7d3dd7b9
;; Package-Version: 20210412.1541
;; Package-X-Original-Version: 20170501.112
;; Homepage: https://github.com/corpix/ob-blockdiag.el

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; Org-Babel support for evaluating blockdiag source code.

;;; Requirements:

;; - blockdiag :: http://blockdiag.com/en/

;;; Code:
(require 'ob)

(defvar org-babel-default-header-args:blockdiag
  '(
    (:results . "file")
    (:exports . "results")
    (:tool    . "blockdiag")
    (:transparency . nil)
    (:antialias . nil)
    (:font    . nil)
    (:size    . nil)
    (:type    . nil))
  "Default arguments for drawing a blockdiag image.")

(add-to-list 'org-src-lang-modes '("blockdiag" . blockdiag))

(defun org-babel-execute:blockdiag (body params)
  (let ((file (cdr (assoc :file params)))
        (tool (cdr (assoc :tool params)))
        (transparency (cdr (assoc :transparency params)))
        (antialias (cdr (assoc :antialias params)))
        (font (cdr (assoc :font params)))
        (size (cdr (assoc :size params)))
        (type (cdr (assoc :type params)))

        (buffer-name "*ob-blockdiag*")
        (error-template "Subprocess '%s' exited with code '%d', see output in '%s' buffer"))
    (save-window-excursion
      (let ((buffer (get-buffer buffer-name)))(if buffer (kill-buffer buffer-name) nil))
      (let ((data-file (org-babel-temp-file "blockdiag-input"))
            (args (append (list "-o" file)
                          (if transparency (list) (list "--no-transparency"))
                          (if antialias (list "--antialias") (list))
                          (if size (list "--size" size) (list))
                          (if font (list "--font" font) (list))
                          (if type (list "-T" type) (list))))
            (buffer (get-buffer-create buffer-name)))
        (with-temp-file data-file (insert body))
        (let
            ((exit-code (apply 'call-process tool nil buffer nil (append args (list data-file)))))
          (if (= 0 exit-code) nil (error (format error-template tool exit-code buffer-name))))))))

(provide 'ob-blockdiag)
;;; ob-blockdiag.el ends here
