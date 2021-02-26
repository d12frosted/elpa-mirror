;;; flycheck-ini-pyinilint.el --- Flycheck integration for PyINILint

;; Copyright 2019 Daniel J. R. May

;; Author: Daniel J. R. May <daniel.may@danieljrmay.com>
;; URL: https://gitlab.com/danieljrmay/flycheck-ini-pyinilint
;; Package-Version: 20190312.1931
;; Package-Commit: 7febbea9ed407eccc4bfd24ae0d3afd1c19394f7
;; Package-Requires: ((flycheck "31"))
;; Created: 12 March 2019
;; Version: 0.3
;; Keywords: convenience, files, tools

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This file provides an INI-file syntax checker via flycheck and
;; pyinilint.  You will need both installed.

;; Find out more about flycheck and how to intstall it at
;; <https://www.flycheck.org>.

;; Find out more about pyinilint and how to install it at
;; <https://gitlab.com/danieljrmay/pyinilint>.

;; If you are developing this code then you will want to have a look
;; at the flycheck developer documetation at
;; <https://www.flycheck.org/en/latest/developer/developing.html>.

;;; Code:

(require 'flycheck)

(flycheck-define-checker ini-pyinilint
  "A INI-file checker using PyINILint.

See URL `https://gitlab.com/danieljrmay/pyinilint'."
  :command ("pyinilint" "--interpolate" source)
  :error-patterns (
		   (info line-start "[WARNING] "
			 (id (one-or-more not-newline))
			 " at line " line
			 " of " (file-name)
			 ": " (message) line-end)
		   (error line-start "[ERROR] "
			  (id (one-or-more not-newline))
			  " at line " line
			  " of " (file-name)
			  ": " (message) line-end) )
  :modes conf-colon-mode)

;;;###autoload
(defun flycheck-ini-pyinilint-setup()
  "Setup Flycheck PyINILint integration."
  (interactive)
  (add-to-list 'flycheck-checkers 'ini-pyinilint))

(provide 'flycheck-ini-pyinilint)
;;; flycheck-ini-pyinilint.el ends here
