;;; flycheck-php-noverify.el --- Flycheck checker for PHP Noverify linter

;; Version: 0.1.0
;; Package-Version: 20211005.401
;; Package-Commit: 3c5cfa5b790bb7f0a8da7f3caee8e4782b67f8ac
;; URL: https://github.com/Junker/flycheck-php-noverify
;; Package-Requires: ((flycheck "0.22"))

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

;;; Commentary:
;; Flycheck checker for PHP Noverify linter

;;;; Setup:
;; (add-hook 'flycheck-mode-hook #'flycheck-php-noverify-setup)

;;; Code:

(require 'flycheck)

(defconst flycheck-php-noverify--default-excluded-checks '("undefinedConstant" "undefinedClass" "undefinedFunction" "undefinedMethod" "undefinedProperty" "undefinedTrait" "unused"))

(flycheck-def-option-var flycheck-php-noverify-exclude-checks flycheck-php-noverify--default-excluded-checks php-noverify
  "list of check names to be excluded"
  :type '(repeat :tag "Checks" (string :tag "Check name"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-php-noverify-allow-checks nil php-noverify
  "list of check names to be enabled"
  :type '(repeat :tag "Checks" (string :tag "Check name"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-php-noverify-php7 nil php-noverify
  "Analyze as PHP 7"
  :safe #'booleanp
  :type 'boolean)

(flycheck-def-args-var flycheck-php-noverify-args php-noverify)

(flycheck-define-checker php-noverify
  "Noverify - Pretty fast linter (code static analysis utility) for PHP."
  :command ("noverify"
            "check"
            "--critical" "\"\""
            "--ignore-vendor"
            "--disable-cache"
            (option "--exclude-checks=" flycheck-php-noverify-exclude-checks concat flycheck-option-comma-separated-list)
            (option "--allow-checks=" flycheck-php-noverify-allow-checks concat flycheck-option-comma-separated-list)
            (option-flag "--php7" flycheck-php-noverify-php7)
            (eval flycheck-php-noverify-args)
            source)
  :standard-input t
  :error-patterns
  (
   (error line-start "ERROR   " (message) " at " (file-name)  ":" line line-end)
   (warning line-start "WARNING " (message) " at " (file-name)  ":" line line-end)
   (info line-start "MAYBE   " (message) " at " (file-name)  ":" line line-end))
  :modes php-mode)

;;;###autoload
(defun flycheck-php-noverify-setup ()
  "Setup PHP Noverify support for Flycheck."
  (interactive)

  (add-to-list 'flycheck-checkers 'php-noverify))

(provide 'flycheck-php-noverify)

;;; flycheck-php-noverify.el ends here
