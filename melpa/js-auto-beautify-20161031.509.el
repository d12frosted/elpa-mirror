;;; js-auto-beautify.el --- auto format you js/jsx file

;; Author: quanwei9958@126.com
;; Version: 0.0.4
;; Package-Version: 20161031.509
;; Package-Commit: 6bc9fef474197ca1722cb1e9051b270f80cdd7cc
;; Package-Requires: ((web-beautify "0.3.1") (web-mode "14.0.27"))

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

;; Usage:
;; (add-hook 'js2-mode-hook 'js-auto-beautify-mode)
;;; Code:

(require 'web-beautify)
(require 'web-mode)


(defsubst js-auto-beautify-current-line-empty-p ()
  (save-excursion
    (beginning-of-line)
    (looking-at "[[:space:]]*$")))

(defsubst js-auto-beautify-begining-with-tag (&optional N)
  "return t if the line begining with </"
  (or N (setq N 1))
  (save-excursion
    (re-search-backward "^ *<.*" (line-beginning-position N) t)))

(defun js-auto-beautify-when-enter ()
  " eval web-beautify when type enter "
  (interactive)
  (newline-and-indent)
  (save-excursion
    (goto-char (- (line-end-position 0) 1))
    (unless (js-auto-beautify-current-line-empty-p)
      (if (numberp (js-auto-beautify-begining-with-tag))
          (let ((close-point (point)))
            (web-mode-navigate)
            (indent-region (point) close-point)
            (web-mode-navigate))
        (web-beautify-format-region web-beautify-js-program (line-beginning-position) (line-end-position)))
      (font-lock-flush (line-beginning-position) (line-end-position)))))


(defun js-auto-beautify-when-branck ()
  "eval web-beautify when branck"
  (interactive)
  (self-insert-command 1)
  (save-excursion
    (web-beautify-format-region
     web-beautify-js-program
     (scan-lists (point) -1 0)     
     (point)))
  (forward-list)
  (let ((begin (scan-lists (point) -1 0))
        (end (point)))
    (font-lock-flush begin end)
    (indent-region begin end)))


(defvar js-auto-beautify-keymap (make-sparse-keymap))
(define-key js-auto-beautify-keymap (kbd "RET") 'js-auto-beautify-when-enter)
(define-key js-auto-beautify-keymap (kbd "}") 'js-auto-beautify-when-branck)

;;;###autoload
(define-minor-mode js-auto-beautify-mode
  "auto-beautify you js/jsx"
  nil
  " AB"
  js-auto-beautify-keymap)

(provide 'js-auto-beautify)


;;; js-auto-beautify.el ends here
