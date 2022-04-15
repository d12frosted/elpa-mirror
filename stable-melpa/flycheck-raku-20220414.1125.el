;;; flycheck-raku.el --- Raku support in Flycheck -*- lexical-binding: t; -*-

;; Copyright (C) 2015 Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>
;; Copyright (C) 2020 Johnathon Weare <jrweare@gmail.com>
;; Copyright (C) 2021 Siavash Askari Nasr

;; Author: Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>
;;      Johnathon Weare <jrweare@gmail.com>
;;      Siavash Askari Nasr <siavash.askari.nasr@gmail.com>
;; original URL: https://github.com/hinrik/flycheck-perl6
;; URL: https://github.com/Raku/flycheck-raku
;; Package-Version: 20220414.1125
;; Package-Commit: d141782cf1c7936b2bbe027f82ec1c9887c08be3
;; Keywords: tools, convenience
;; Version: 0.7
;; Package-Requires: ((emacs "26.3") (flycheck "0.22"))

;; This file is not part of GNU Emacs.

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

;; Raku syntax checking support for Flycheck.

;; Runs "raku -c" on your code.  Currently does not report the exact
;; column number of the error, just the line number.

;;; Code:

(require 'flycheck)
(require 'project)

(defgroup flycheck-raku nil
  "Raku support for Flycheck."
  :prefix "flycheck-raku-"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/Raku/flycheck-raku"))

(flycheck-def-option-var flycheck-raku-include-path nil raku
  "A list of include directories for Raku.

The value of this variable is a list of strings, where each
string is a directory to add to the include path of Raku.
Relative paths are relative to the file being checked."
  :type '(repeat (directory :tag "Include directory"))
  :safe #'flycheck-string-list-p)

(flycheck-define-checker raku
  "A Raku syntax checker."
  :command ("raku" "-c"
            (option-list "-I" flycheck-raku-include-path)
            ;; Add project root to path
            (eval (let ((current-project (project-current)))
                    (if current-project
                        (let ((project-root (car (project-roots current-project))))
                          (list "-I" (expand-file-name project-root))))))
            source)
  :error-parser flycheck-parse-with-patterns-without-color
  :error-filter (lambda (errors)
                  (flatten-list
                   (mapcar
                    (lambda (err)
                      (let ((str (flycheck-error-message err)))
                        (if (string-match "\\`\\(Undeclared \\(?:routine\\|name\\)\\)s?:" str)
                            (let ((error-type (match-string 1 str)) errs)
                              (while (string-match "\s*\\(.+?\\) at lines? \\([^\n]+\n\\)" str (match-end 0))
                                (let ((msg (concat error-type " " (match-string 1 str)))
                                      (rest-of-line (match-string 2 str))
                                      (rest-start-pos 0)
                                      line-numbers)
                                  (save-match-data
                                    (while (string-match "\\([[:digit:]]+\\)\\(?:, \\)?" rest-of-line rest-start-pos)
                                      (setq rest-start-pos (match-end 0))
                                      (push (string-to-number (match-string 1 rest-of-line))
                                            line-numbers))
                                    (string-match "\\([^\n]*\\)\n" rest-of-line (match-end 0))
                                    (mapc
                                     (lambda (line-number)
                                       (push
                                        (flycheck-error-new-at
                                         line-number nil (flycheck-error-level err) (concat msg (match-string 1 rest-of-line)))
                                        errs))
                                     line-numbers))))
                              errs)
                          err)))
                    errors)))
  :error-patterns ((error (? string-start "Use of Nil in string context\n" (* whitespace))
                          (* whitespace)
                          (? "Syntax OK\n" (* whitespace))
                          (? line-start "===SORRY!===" (? " Error while compiling " (file-name)) "\n")
                          (? (+ nonl) "difficulties:\n" (* whitespace))

                          (message
                           (or (seq line-start "===SORRY!===" (? "Error while compiling ") (+? anything) "\n\n")
                               (+? anything))

                           (or (seq (* whitespace) "at " (file-name) ":" line "\n")
                               (+ (seq (+? nonl) " at line" (? "s") " "  (+ (seq line (? ", "))) (* nonl) "\n")))

                           (? (* whitespace) (+ "-") ">" (+ nonl) "\n"
                              (*? (seq (+ whitespace) (+ nonl) "\n"))))))
  :modes raku-mode)

(add-to-list 'flycheck-checkers 'raku)

(provide 'flycheck-raku)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; flycheck-raku.el ends here
