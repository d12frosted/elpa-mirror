;;; template-overlays.el --- Display template regions using overlays -*- coding: utf-8 -*-

;; Copyright © 2018 Mariano Montone
;;
;; Author: Mariano Montone <marianomontone@gmail.com>
;; Maintainer: Mariano Montone <marianomontone@gmail.com>
;; URL: http://www.github.com/mmontone/template-overlays
;; Package-Version: 20180706.1132
;; Package-Commit: 3cbc9a4882dcbbddf9b168883d119a6af0848784
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (ov "1.0.6"))
;; Keywords: faces, convenience, templates, overlays

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

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Display template regions using overlays.

;;; Code:

(require 'cl-lib)
(require 'ov)

(defun template-overlays-regexp-replace (regexp replace &optional beg end)
  "Make overlays spanning the regions that match REGEXP.
REPLACE should be a function that is called to replace the matched REGEXP.
If BEG and END are numbers, they specify the bounds of the search."
  (save-excursion
    (goto-char (or beg (point-min)))
    (let (ov-or-ovs finish)
      (ov-recenter (point-max))
      (while (and (not finish) (re-search-forward regexp end t))
        ;; Apply only when there are not overlays already
        (when (not (overlays-at (match-beginning 0)))
          (let ((ov (ov-make (match-beginning 0)
                             (match-end 0)
                             nil (not ov-sticky-front) ov-sticky-rear)))
            (let ((replacement (funcall replace
                                        (buffer-substring-no-properties
                                         (match-beginning 0)
                                         (match-end 0)))))
              (overlay-put ov 'display replacement)
              (overlay-put ov 'category 'template-overlays))
            (setq ov-or-ovs (cons ov ov-or-ovs))))
        (when (= (match-beginning 0) (match-end 0))
          (if (eobp)
              (setq finish t)
            (forward-char 1))))
      ov-or-ovs)))

(defvar template-overlays-default-delimiters
  '(("{%" "%}" face (:weight bold))
    ("{{" "}}" face (:box t))
    ("<!--" "-->" face (:slant italic))
    ("{#" "#}" face (:slant italic))))

(defvar template-overlays-delimiters template-overlays-default-delimiters
  "Template overlays delimiters.  A list of (delim-from delim-to &rest options).")

(defun template-overlays-set-overlays ()
  "Set overlays in the current buffer."

  (dolist (delim template-overlays-delimiters)
    (destructuring-bind (from-delim to-delim &rest options)
        delim
      (apply #'ov-set
             (template-overlays-regexp-replace
              (concat from-delim "\s*\\(.*?\\)\s*" to-delim)
              (lambda (match)
                (buffer-substring-no-properties
                                (match-beginning 1)
                                (match-end 1))))                  
              options)))
  t)

(defun template-overlays-delete-all-overlays ()
  "Remove all template overlays from current buffer."
  (remove-overlays nil nil 'category 'template-overlays))

(defun template-overlays-delete-overlays-at-point ()
  "Delete template overlays at point."
  (mapcar (lambda (ov)
            (when (eql (overlay-get ov 'category) 'template-overlays)
              (delete-overlay ov)))
          (overlays-at (point))))

(make-variable-buffer-local 'last-post-command-position)

(defun template-overlays-update-overlays ()
  "Update the template overlays in current buffer."
  (unless (equal (point) last-post-command-position)
    (template-overlays-set-overlays)
    (template-overlays-delete-overlays-at-point)
    (setq last-post-command-position (point))))

;;;###autoload
(define-minor-mode template-overlays-mode
  "Template overlays minor mode"
  :lighter " TOv"

  (require 'ov)
  
  (message "Template overlays are %s" (if template-overlays-mode "ON" "OFF"))

  (if template-overlays-mode
      (progn
        (add-hook 'post-command-hook 'template-overlays-update-overlays nil t)
        (template-overlays-update-overlays))
    (remove-hook 'post-command-hook 'template-overlays-update-overlays t)
    (kill-local-variable 'last-post-command-position)
    (template-overlays-delete-all-overlays)))

(provide 'template-overlays)

;;; template-overlays.el ends here
