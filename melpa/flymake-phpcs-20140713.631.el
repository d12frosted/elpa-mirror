;;; flymake-phpcs.el --- making flymake work with PHP CodeSniffer

;; Copyright 2013, 2014 Akiha Senda

;; Author: Akiha Senda
;; URL: https://github.com/senda-akiha/flymake-phpcs/
;; Package-Version: 20140713.631
;; Package-Commit: 8e5ab5103c8f40a2ab6c86def6327e480ae93657
;; Version: 1.1
;; Keywords: flymake, phpcs, php
;; Package-Requires: ((flymake-easy "0.9"))

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Please check the GitHub
;; (https://github.com/senda-akiha/flymake-phpcs/)
;; for more information.

;;; Code:

(require 'flymake-easy)

(defconst flymake-phpcs-err-line-patterns
  '(("\"\\(.*\\)\",\\([[:digit:]]+\\),\\([[:digit:]]+\\),.*,\"\\(.*\\)\".*\r?\n"
     1 2 3 4)))

(defcustom flymake-phpcs-standard "PEAR"
  "Setting the Coding Standard for PHP CodeSniffer."
  :type 'string
  :group 'flymake-phpcs)

(defcustom flymake-phpcs-command (executable-find "phpcs")
  "The name of the phpcs executable."
  :group 'flymake-phpcs
  :type 'string)

(defcustom flymake-phpcs-options "-w"
  "Configure phpcs options."
  :group 'flymake-phpcs
  :type 'string)

(defcustom flymake-phpcs-location 'inplace
  "Where to create the temporary copy: one of 'tempdir or 'inplace (default)."
  :type `(choice
          (const :tag "In place" inplace)
          (const :tag "Temporary location" tempdir))
  :group 'flymake-phpcs)

(defun flymake-phpcs-build-command-line (filename)
  "Construct a command that flymake can use to check PHP source."
  (list flymake-phpcs-command "--report=csv"
        flymake-phpcs-options
        (concat "--standard="
                (if (string-match "/" flymake-phpcs-standard)
                    (expand-file-name flymake-phpcs-standard)
                  flymake-phpcs-standard))
        filename))

;;;###autoload
(defun flymake-phpcs-load ()
  "Configure flymake mode to check the current buffer's PHP syntax."
  (interactive)
  (flymake-easy-load 'flymake-phpcs-build-command-line
                     flymake-phpcs-err-line-patterns
                     flymake-phpcs-location
                     "php"))

(provide 'flymake-phpcs)

;;; flymake-phpcs.el ends here
