;;; markdownfmt.el --- Format markdown using markdownfmt    -*- lexical-binding: t; -*-

;; Author: Nicolas Lamirault <nicolas.lamirault@gmail.com>
;; URL: https://github.com/nlamirault/emacs-markdownfmt
;; Package-Version: 20160609.1241
;; Package-Commit: 187a74eb4fd9e8520ce08da42d1d292b9af7f2b7
;; Version: 0.1.0
;; Keywords: markdown

;; Package-Requires: ((emacs "24"))

;; Copyright (C) 2016 Nicolas Lamirault <nicolas.lamirault@gmail.com>

;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:

;;; Code:


(defgroup markdownfmt nil
  "Format Markdown buffers using markdownfmt."
  :group 'markdown)

(defcustom markdownfmt-bin "markdownfmt"
  "Path to markdownfmt executable."
  :type 'string
  :group 'markdownfmt)

(defcustom markdownfmt-popup-errors nil
  "Display error buffer when markdownfmt fails."
  :type 'boolean
  :group 'markdownfmt)


(defun markdownfmt--call (buf)
  "Format BUF using markdownfmt."
  (with-current-buffer (get-buffer-create "*markdownfmt*")
    (erase-buffer)
    (insert-buffer-substring buf)
    (if (zerop (call-process-region (point-min) (point-max) markdownfmt-bin t t nil))
        (progn (copy-to-buffer buf (point-min) (point-max))
               (kill-buffer))
      (when markdownfmt-popup-errors
        (display-buffer (current-buffer)))
      (error "Markdownfmt failed, see *markdownfmt* buffer for details"))))


;;;###autoload
(defun markdownfmt-format-buffer ()
  "Format the current buffer using markdownfmt."
  (interactive)
  (unless (executable-find markdownfmt-bin)
    (error "Could not locate executable \"%s\"" markdownfmt-bin))
  (let ((cur-point (point))
        (cur-win-start (window-start)))
    (markdownfmt--call (current-buffer))
    (goto-char cur-point)
    (set-window-start (selected-window) cur-win-start))
  (message "Formatted buffer with markdownfmt."))


;;;###autoload
(defun markdownfmt-enable-on-save ()
  "Run markdownfmt when saving buffer."
  (interactive)
  (add-hook 'before-save-hook #'markdownfmt-format-buffer nil t))


(provide 'markdownfmt)
;;; markdownfmt.el ends here
