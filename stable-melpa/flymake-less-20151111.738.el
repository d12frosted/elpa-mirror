;;; flymake-less.el --- Flymake handler for LESS stylesheets (lesscss.org)

;; Copyright (C) 2013-2015  Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; Package-Version: 20151111.738
;; Package-X-Original-Version: 0
;; Keywords: languages
;; Package-Commit: 32d3c28a9a5c52b82d1741ff9d715013b6498421
;; Package-Requires: ((less-css-mode "0.15") (flymake-easy "0.1"))

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

;;; Commentary:

;; Usage:
;;   (require 'flymake-less)
;;   (add-hook 'less-css-mode-hook 'flymake-less-load)
;;
;; Beware that lessc is quite slow, so there can be a significant lag
;; between editing and the highlighting of resulting errors.
;;
;; Like the author's many other flymake-*.el extensions, this code is
;; designed to configure flymake in a buffer-local fashion, which
;; avoids the dual pitfalls of 1) inflating the global list of
;; `flymake-err-line-patterns' and 2) being required to specify the
;; matching filename extensions (e.g. "*.css") redundantly.
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy


;;; Code:

(require 'flymake-easy)
(require 'less-css-mode)

(defgroup flymake-less nil
  "Flymake handler for LESS stylesheets."
  :group 'flymake)

(defcustom flymake-less-lessc-options
  '("--lint" "--no-color") ;; Requires Less >= 1.4
  "Options to pass to lessc."
  :group 'flymake-less)


(defun flymake-less-command (filename)
  "Construct a command that flymake can use to check less syntax at FILENAME."
  (cons less-css-lessc-command
        (append flymake-less-lessc-options (list filename))))

(defconst flymake-less-err-line-patterns
  (list (list less-css-default-error-regex 2 3 4 1))
  "Error line patterns in form expected by flymake.")

;;;###autoload
(defun flymake-less-load ()
  "Flymake support for LESS files"
  (interactive)
  (flymake-easy-load
   'flymake-less-command
   flymake-less-err-line-patterns
   'tempdir
   "less"))


(provide 'flymake-less)
;;; flymake-less.el ends here
