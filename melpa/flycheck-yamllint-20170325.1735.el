;;; flycheck-yamllint.el --- Flycheck integration for YAMLLint

;; Copyright (c) 2017 Krzysztof Magosa

;; Author: Krzysztof Magosa <krzysztof@magosa.pl>
;; URL: https://github.com/krzysztof-magosa/flycheck-yamllint
;; Package-Version: 20170325.1735
;; Package-Commit: 110d310fae409e1869b82c34e60936bd3783dc69
;; Package-Requires: ((flycheck "30"))
;; Created: 25 March 2017
;; Version: 0.1.0
;; Keywords: convenience, languages, tools

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;

;;; Code:

(require 'flycheck)

(flycheck-def-config-file-var flycheck-yamllintrc yaml-yamllint ".yamllint"
  :safe #'stringp)

(flycheck-define-checker yaml-yamllint
  "A YAML syntax checker using YAMLLint.

See URL `https://github.com/adrienverge/yamllint'."
  :command ("yamllint" "-f" "parsable" source (config-file "-c" flycheck-yamllintrc))
  :error-patterns
  ((error line-start (file-name) ":" line ":" column ": [error] " (message) line-end)
   (warning line-start (file-name) ":" line ":" column ": [warning] " (message) line-end))
  :modes yaml-mode)

;;;###autoload
(defun flycheck-yamllint-setup ()
  "Setup Flycheck YAMLLint integration."
  (interactive)
  (add-to-list 'flycheck-checkers 'yaml-yamllint))


(provide 'flycheck-yamllint)
;;; flycheck-yamllint.el ends here
