;;; flycheck-elixir.el --- Support Elixir in flycheck

;; Copyright (C) 2016 Lorenzo Bolla <lbolla@gmail.com>
;;
;; Author: Lorenzo Bolla <lbolla@gmail.com>
;; Created: 26 March 2016
;; Version: 1.0
;; Package-Version: 20210413.612
;; Package-Commit: b57a77a21d6cf9621b3387831cba34135c4fa35d
;; Package-Requires: ((flycheck "0.25"))

;;; Commentary:

;; This package adds support for elixir to flycheck.  It requires
;; elixir>=1.2.3.
;; Warning: running the checker will effectively execute the buffer,
;; therefore it may be unsafe to run.  See
;; https://github.com/flycheck/flycheck/issues/630

;; To use it, add to your init.el:

;; (require 'flycheck-elixir)
;; (add-hook 'elixir-mode-hook 'flycheck-mode)

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
(require 'cl-lib)
(require 'flycheck)

(defun find-project-root (filename)
  (let ((closest-mix-root (locate-dominating-file filename "mix.exs")))
    (let ((apps-match (string-match "/apps/[^/]+" closest-mix-root)))
      (if apps-match
          (let ((project-root (substring closest-mix-root 0 (+ 1 apps-match))))
            (if (file-exists-p (concat project-root "mix.exs"))
                project-root
              closest-mix-root))
        closest-mix-root))
    ))

(defun elixirc-params (filename)
  (let ((project-path (find-project-root filename)))
    (if project-path
        (let ((lib-path (concat project-path "_build/dev/lib")))
          (if (file-directory-p lib-path)
              (let ((dep-paths (remove-if (lambda (p)
                                            (let ((n (file-name-base p)))
                                              (or (equal n ".") (equal n ".."))))
                                          (directory-files lib-path t))))
                (seq-reduce (lambda (a p) (cons "-pa" (cons (concat p "/ebin") a))) dep-paths ()))
              )))))

(flycheck-define-checker elixir
  "Elixir checker."
  :command ("elixirc"
            "--ignore-module-conflict"  ; Avoid module conflict warnings
            (eval (list "-o" (flycheck-temp-dir-system)))
            (eval (elixirc-params (buffer-file-name)))
            source-inplace)  ; Check as soon as possible, not just on file-save
  :error-patterns
  ((warning line-start
            "warning: "
            (message)
            (one-or-more not-wordchar)
            (file-name)
            ":"
            line
            line-end)
   (error line-start
          "** ("
          (one-or-more word)
          "Error) "
          (file-name)
          ":"
          line
          ": "
          (message)
          line-end))
  :modes elixir-mode
  :predicate
    (lambda () (not (string-equal "exs" (file-name-extension buffer-file-name)))))

(add-to-list 'flycheck-checkers 'elixir t)

(provide 'flycheck-elixir)
;;; flycheck-elixir.el ends here
