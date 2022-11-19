;;; flycheck-clolyze.el --- Add Clolyze to to flycheck -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Daniel Laps <daniel.laps@hhu.de>
;;
;; URL: https://github.com/DLaps/flycheck-clolyze
;; Author: Daniel Laps <daniel.laps@hhu.de>
;; Version: 1.0.0
;; Package-Requires: ((flycheck "0.25") (emacs "24"))

;;; Commentary:

;; This package adds Clolyze to flycheck.  To use it, add
;; to your init.el:
;; (require 'flycheck-clolyze)

;;; License:

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:
(require 'flycheck)

(flycheck-define-checker clolyze
  "This checker uses clolyze to check clojure code."
  :command ("lein" "clolyze" ":linting")
  :error-patterns ((warning  line-start (file-name) ":" line ":" column ":" (message) line-end))
  :modes clojure-mode)

(add-to-list 'flycheck-checkers 'clolyze)

(provide 'flycheck-clolyze)
;;; flycheck-clolyze.el ends here
