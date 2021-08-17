;;; flycheck-mmark.el --- Flycheck checker for the MMark markdown processor -*- lexical-binding: t; -*-
;;
;; Copyright © 2018–present Mark Karpov <markkarpov92@gmail.com>
;;
;; Author: Mark Karpov <markkarpov92@gmail.com>
;; URL: https://github.com/mmark-md/flycheck-mmark
;; Package-Version: 20190713.1323
;; Package-Commit: 67d6216229337c9c020a8aecd6ae2417de29b5e8
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.4") (flycheck "0.29"))
;; Keywords: convenience, text
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a Flycheck checker for the MMark markdown
;; processor.

;;; Code:

(require 'flycheck)
(require 'json)

(defgroup flycheck-mmark nil
  "Flycheck checker for the MMark markdown processor."
  :group  'flycheck
  :tag    "Flycheck MMark"
  :prefix "flycheck-mmark-"
  :link   '(url-link :tag "GitHub"
                     "https://github.com/mmark-md/flycheck-mmark"))

(defun flycheck-mmark-parse-errors (output checker buffer)
  "Decode MMark parse errors in JSON format decoding OUTPUT.

CHECKER is the checker used, BUFFER is the buffer that is being
checked."
  (let ((json-array-type 'list))
    (unless (string-empty-p output)
      (mapcar
       (lambda (err)
         (flycheck-error-new
          :checker checker
          :buffer  buffer
          :line     (cdr (assoc 'line   err))
          :column   (cdr (assoc 'column err))
          :message  (cdr (assoc 'text   err))
          :level    'error))
       (json-read-from-string output)))))

(flycheck-define-checker mmark
  "A syntax checker for the MMark markdown processor using ‘mmark’ CLI tool.

See: https://github.com/mmark-md/mmark-cli"
  :command        ("mmark" "--json" "--ofile" null-device)
  :standard-input t
  :error-parser   flycheck-mmark-parse-errors
  :modes          markdown-mode)

;;;###autoload
(defun flycheck-mmark-setup ()
  "Setup Flycheck for MMark."
  (interactive)
  (add-to-list 'flycheck-checkers 'mmark))

(provide 'flycheck-mmark)

;;; flycheck-mmark.el ends here
