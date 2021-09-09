;;; flycheck-pony.el --- Pony support in Flycheck
;;
;; Authors: Sean T Allen <sean@seantallen.com>
;; Version: 0.3.0
;; Package-Version: 20210118.1326
;; Package-Commit: 3c303551cb9c317e49878cb860c6ed6d142d9613
;; URL: https://github.com/seantallen/flycheck-pony
;; Keywords: tools, convenience
;; Package-Requires: ((flycheck "0.25.1"))
;;
;; This file is not part of GNU Emacs.
;;
;; Copyright (C) 2016 Richard M. Loveland <r@rmloveland.com>
;; Copyright (c) 2016 Sean T. Allen
;; Copyright (c) 2021 The Pony Developers
;;
;;; Commentary:
;;
;; Pony syntax checking support for Flycheck.  Runs "ponyc -rfinal" in the
;; current working directory.
;;
;; You may need to customize the location of your Pony compiler if
;; Emacs isn't seeing it on your PATH:
;;
;; (setq flycheck-pony-executable "/usr/local/bin/ponyc")
;;
;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Code:

(require 'flycheck)

(defgroup flycheck-pony nil
  "Pony support for Flycheck."
  :prefix "flycheck-pony-"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/seantallen/flycheck-pony"))

(flycheck-define-checker pony
  "A Pony syntax checker using the ponyc compiler.

See URL `http://www.ponylang.org'."
  :command ("ponyc" "-rfinal")
  :standard-input nil
  :error-patterns
  ((error line-start (file-name) ":" line ":" column
    (zero-or-more (or digit ":")) (message) line-end))
  :modes ponylang-mode)

(flycheck-define-checker corral
  "A Pony syntax checker using corral dependency management tool.

See URL `https://github.com/ponylang/corral'."
  :command ("corral" "run" "--" "ponyc" "-rfinal")
  :standard-input nil
  :error-patterns
  ((error line-start (file-name) ":" line ":" column
    (zero-or-more (or digit ":")) (message) line-end))
  :modes ponylang-mode)

(add-to-list 'flycheck-checkers 'pony)
(add-to-list 'flycheck-checkers 'corral)

(provide 'flycheck-pony)

;;; flycheck-pony.el ends here
