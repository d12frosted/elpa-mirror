;;; flycheck-dogma.el --- flycheck checker for elixir dogma

;; Copyright (C) 2016 by Aaron Jensen

;; Author: Aaron Jensen <aaronjensen@gmail.com>
;; URL: https://github.com/aaronjensen/flycheck-dogma
;; Package-Version: 20170125.721
;; Package-Commit: eea1844a81e87e2488b05e703a93272d0fc3bc74
;; Version: 0.1.0
;; Package-Requires: ((flycheck "29"))

;;; Commentary:

;; This package adds support for dogma to flycheck.

;; To use it, require it and ensure you have elixir-mode set up for flycheck:

;;   (eval-after-load 'flycheck
;;     '(flycheck-dogma-setup))
;;   (add-hook 'elixir-mode-hook 'flycheck-mode)

;;; License:

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

;;; Code:
(require 'flycheck)
(defun flycheck-dogma--project-root (&rest _ignored)
  "Find directory with mix.exs."
  (and buffer-file-name
       (locate-dominating-file buffer-file-name "mix.exs")))

(flycheck-define-checker elixir-dogma
  "Elixir dogma checker."
  :command ("mix" "dogma" "--format" "flycheck" source)
  :predicate
  (lambda ()
    (file-exists-p "deps/dogma"))
  :error-patterns
  (
   (info line-start (file-name) ":" line ":" column ": " (or "C" "R" "D") ": " (optional (id (one-or-more (not (any ":")))) ": ") (message) line-end)
   (warning line-start (file-name) ":" line ":" column ": " (or "W" "E" "F") ": " (optional (id (one-or-more (not (any ":")))) ": ") (message) line-end))
  :working-directory flycheck-dogma--project-root
  :modes elixir-mode)

;;;###autoload
(defun flycheck-dogma-setup ()
  "Setup flycheck-dogma.
Add `elixir-dogma' to `flycheck-checkers'."
  (interactive)
  (add-to-list 'flycheck-checkers 'elixir-dogma))

(provide 'flycheck-dogma)
;;; flycheck-dogma.el ends here
