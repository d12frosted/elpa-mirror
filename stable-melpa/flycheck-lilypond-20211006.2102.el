;;; flycheck-lilypond.el --- LilyPond support in Flycheck -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>

;; Author: Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>
;; URL: https://github.com/hinrik/flycheck-lilypond
;; Package-Version: 20211006.2102
;; Package-Commit: 78f8c16cd67f9f6d3f1806e1fd403222723ba400
;; Keywords: tools, convenience
;; Version: 0.1-git
;; Package-Requires: ((emacs "24.3") (flycheck "0.22"))

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

;; LilyPond syntax checking support for Flycheck.

;; You can add the following to your init file:

;; (add-hook 'LilyPond-mode-hook 'flycheck-mode)
;; (eval-after-load 'flycheck '(require 'flycheck-lilypond)

;;; Code:

(require 'flycheck)

(defgroup flycheck-lilypond nil
  "LilyPond support for Flycheck."
  :prefix "flycheck-lilypond-"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/hinrik/flycheck-lilypond"))

(flycheck-define-checker lilypond
  "A LilyPond syntax checker."
  :command ("lilypond" "-l" "WARNING" "-o" temporary-directory source)
  :error-patterns
  ((error line-start (file-name) ":" line ":" column ": error: " (message) line-end)
   (error line-start (file-name) ":" line ": error: " (message) line-end)
   (warning line-start (file-name) ":" line ":" column ": warning: " (message) line-end)
   (warning line-start (file-name) ":" line ": warning: " (message) line-end))
  :modes LilyPond-mode)

(add-to-list 'flycheck-checkers 'lilypond)

(provide 'flycheck-lilypond)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; flycheck-lilypond.el ends here
