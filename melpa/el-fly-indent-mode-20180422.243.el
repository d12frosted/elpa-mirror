;;; el-fly-indent-mode.el --- Indent Emacs Lisp on the fly

;; Copyright (C) 2018 Jiahao Li

;; Author: Jiahao Li <jiahaowork@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20180422.243
;; Package-Commit: 1dd4b907ff4d9581c18b4e38e8719e83ba0dace1
;; Keywords: lisp, languages
;; Homepage: https://github.com/jiahaowork/el-fly-indent-mode.el
;; Package-Requires: ((emacs "25"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This minor mode indents Emacs Lisp code on the fly.
;; After installation, add
;; (add-hook 'emacs-lisp-mode-hook #'el-fly-indent-mode)
;; to your ~/.emacs file.

;; For detailed explanations and more examples see the homepage:
;; https://github.com/jiahaowork/el-fly-indent-mode.el

;;; Code:
(defvar el-fly-indent-flag nil)

(defun el-fly-indent-before-change (begin end)
  "Monitor text between BEGIN and END before any change."
  (when el-fly-indent-mode
    (let ((string (buffer-substring begin end)))
      (when
	  (or
	   (string-match-p "[()]" string)
	   )
	(setq el-fly-indent-flag t)))))

(defun el-fly-indent-after-change (begin end length)
  "Monitor text between BEGIN and END after any change.
LENGTH not used"
  (when el-fly-indent-mode
    (message "after change")
    (let ((string (buffer-substring begin end)))
      (when
	  (or
	   (string-match-p "\\W" (buffer-substring (1- begin) begin))
	   (string-match-p "[()]" string)
	   (string-match-p "([ \f\t\n\r\v]*\\w*\\'" (buffer-substring (point-min) begin))
	   el-fly-indent-flag)
	(indent-region begin (el-fly-indent-region-end begin))
	(setq el-fly-indent-flag nil)))))

(defun el-fly-indent-region-end (start)
  "Determine the end of the region to indent given START."
  (let ((end
	 (string-match
	  "\n[\f\t\n\r\v]*\n[^ \f\t\n\r\v]"
	  (buffer-string)
	  (1- start))))
    (if end
	(1+ end)
      (point-max))))

(defvar el-fly-indent-mode-map (make-sparse-keymap))
;;;###autoload
(define-minor-mode el-fly-indent-mode
  "Minor mode."
  :init-value nil
  :global nil
  (if el-fly-indent-mode
      (progn
        (make-local-variable 'before-change-functions)
        (make-local-variable 'after-change-functions)
        (push 'el-fly-indent-before-change before-change-functions)
        (push 'el-fly-indent-after-change after-change-functions))
    (setq before-change-functions (delq 'el-fly-indent-before-change before-change-functions)
          after-change-functions (delq 'el-fly-indent-after-change after-change-functions))))

(provide 'el-fly-indent-mode)

;;; el-fly-indent-mode.el ends here
