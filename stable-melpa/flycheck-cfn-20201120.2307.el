;;; flycheck-cfn.el --- Flycheck backend for AWS cloudformation -*- lexical-binding: t; -*-

;; Copyright (C) 2020  William Orr <will@worrbase.com>
;;
;; Author: William Orr <will@worrbase.com>
;; Version: 1.0.0
;; Package-Version: 20201120.2307
;; Package-Commit: a4ca40978e680f9edc86c141e696e0ae57c63533
;; Keywords: convenience
;; Package-Requires: ((emacs "26.1") (flycheck "31"))
;; URL: https://gitlab.com/worr/cfn-mode

;; flycheck-cfn is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later version.
;;
;; flycheck-cfn is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License
;; along with flycheck-cfn.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; This package adds support for AWS Cloudformation in Flycheck.
;;
;; To use, first install the requisite tools:
;;
;; ~gem install cfn_nag~
;; ~pip install cfn-lint~
;;
;; For information about these checkers, and how to handle configuration and
;; exceptions, see the following links:
;;
;; - cfn_nag :: `https://github.com/stelligent/cfn_nag'
;; - cfn-lint :: `https://github.com/aws-cloudformation/cfn-python-lint'
;;
;; To use, do:
;; (add-hook 'cfn-mode-hook
;;   (setq flycheck-checkers (append flycheck-checkers '(cfn-lint cfn-nag))))

;;; Code:

(require 'flycheck)

(defgroup flycheck-cfn nil
  "Cloudformation support for flycheck"
  :prefix "flycheck-cfn-"
  :group 'flycheck
  :link '(url-link :tag "Gitlab" "https://gitlab.com/worr/cfn-mode"))

(defun flycheck-cfn-parse-cfn-nag (output checker buffer)
  "Parse cfn-nag errors from JSON OUTPUT.

Parse cfn-nag OUTPUT for cfn-nag CHECKER on a given BUFFER"

  (seq-map (lambda (violation)
             (message "%s" violation)
             (let-alist violation
               (seq-map (lambda (linenum)
                          (flycheck-error-new-at
                           linenum
                           nil
                           (if (equal .type "WARN")
                               'warning
                             'error)
                           .message
                           :id .id
                           :checker checker
                           :filename (buffer-file-name buffer)))
                        .line_numbers)))
           (seq-filter
            'listp
            (seq-map (lambda (msg)
                       (alist-get 'violations
                                  (alist-get 'file_results msg)))
                     (car (flycheck-parse-json output))))))

(flycheck-define-checker cfn-lint
  "AWS CloudFormationlinter using cfn-lint.

Install cfn-lint first: pip install cfn-lint

See `https://github.com/aws-cloudformation/cfn-python-lint'."

  :command ("cfn-lint" "-f" "parseable" source)
  :error-patterns ((warning line-start (file-name) ":" line ":" column
                            ":" (one-or-more digit) ":" (one-or-more digit) ":"
                            (id "W" (one-or-more digit)) ":" (message) line-end)
                   (error line-start (file-name) ":" line ":" column
                          ":" (one-or-more digit) ":" (one-or-more digit) ":"
                          (id "E" (one-or-more digit)) ":" (message) line-end))
  :modes (cfn-mode))

(flycheck-define-checker cfn-nag
  "AWS CloudFormation linter using cfn-nag.

Install cfn-nag first: gem install cfn-nag

See `https://github.com/stelligent/cfn_nag'"

  :command ("cfn_nag" "--output-format" "json" source)
  :error-parser flycheck-cfn-parse-cfn-nag
  :modes (cfn-mode))

;;;###autoload
(defun flycheck-cfn-setup ()
  "Setup cfn linters for flycheck."
  (add-to-list 'flycheck-checkers 'cfn-nag)
  (add-to-list 'flycheck-checkers 'cfn-lint)
  (flycheck-mode +1))

(provide 'flycheck-cfn)

;;; flycheck-cfn.el ends here
