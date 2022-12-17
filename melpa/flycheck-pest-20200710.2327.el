;;; flycheck-pest.el --- Flycheck integration for Pest --*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; URL: https://github.com/ksqsf/pest-mode
;; Package-Version: 20200710.2327
;; Package-Commit: 43447a2c70f98edd1139005e32f437d3f142442b
;; Keywords: convenience flycheck
;; Version: 0.1
;; Package-Requires: ((emacs "26.3") (flycheck "31") (pest-mode "0.1"))

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

;; Flycheck integration for Pest.

;; To use this package, add following code to your init file.

;;   (with-eval-after-load 'flycheck
;;     (require 'flycheck-pest)
;;     (flycheck-pest-setup))

;;; Code:

(require 'flycheck)

(defun flycheck-pest-parse (output checker buffer)
  "Parse pest error from pesta OUTPUT.

CHECKER and BUFFER denote the CHECKER that returned OUTPUT and
the BUFFER that was checked respectively."
  (let ((regexp (rx bol "nil " "("
                    (group (+ (char digit))) ","
                    (group (+ (char digit))) ") "
                    (group (* nonl)) eol))
        (last-match 0)
        alist)
    (while (string-match regexp output last-match)
      (push `((beg . ,(flycheck-string-to-number-safe (match-string 1 output)))
              (end . ,(flycheck-string-to-number-safe (match-string 2 output)))
              (msg . ,(match-string 3 output)))
            alist)
      (setq last-match (match-end 0)))
    (mapcar
     (lambda (elm)
       (let-alist elm
         (if .beg
             (let* ((line (line-number-at-pos .beg 'absolte))
                    (line-beg-point (save-excursion
                                      (goto-char .beg)
                                      (line-beginning-position)))
                    (column (- .end line-beg-point)))
               (flycheck-error-new-at
                line column 'warning .msg
                :checker checker :buffer buffer))
           (flycheck-error-new-at
            (line-number-at-pos (point-max)) 0 'warning .msg
            :checker checker :buffer buffer))))
     (nreverse alist))))

(flycheck-define-checker pest
  "A flycheck checker for Pest grammar files."
  :command ("pesta"
            "meta_check")
  :standard-input t
  :error-parser flycheck-pest-parse
  :modes (pest-mode))

;;;###autoload
(defun flycheck-pest-setup ()
  "Setup Flycheck Indent."
  (interactive)
  (add-to-list 'flycheck-checkers 'pest 'append))

(provide 'flycheck-pest)
;;; flycheck-pest.el ends here
