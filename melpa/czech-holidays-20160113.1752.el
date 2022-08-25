;;; czech-holidays.el --- Adds a list of Czech public holidays to Emacs calendar

;; Copyright (C) 2015 David Chkhikvadze <david.chk@outlook.com>

;; Author: David Chkhikvadze <david.chk@outlook.com>
;; Maintainer: David Chkhikvadze <david.chk@outlook.com>
;; Version: 0.0.1
;; Package-Version: 20160113.1752
;; Package-Commit: d19828122cf3322bcf50601cefa4ac385d2d8f82
;; Created: 29th December 2015
;; Keywords: calendar

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; This package adds Czech (https://en.wikipedia.org/wiki/Czech_Republic)
;;; public holidays to the Emacs calendar.
;;;
;;; If you have `org-agenda-include-diary` set to `t`, these will be
;;; also listed in the `org-agenda` view.

;;; Installation

;;; This package is available on MELPA, just `M-x` `package-install`
;;; `czech-holidays`. If you want to install it manually, clone this
;;; repository somewhere, add it to `load-path`, and add
;;; `(require 'czech-holidays)` to `.emacs`.

;;; Configuration

;;; Add a call to `(czech-holidays-add)` somewhere in your `.emacs`.
;;; Note that this must be called *before* Emacs calendar is loaded.

;;; Code:

(defvar czech-holidays-list
  '((holiday-fixed 1 1 "Den obnovy samostatného českého státu; Nový rok")
    (holiday-easter-etc -2 "Velký pátek")
    (holiday-easter-etc 1 "Velikonoční Pondělí")
    (holiday-fixed 5 1 "Svátek práce")
    (holiday-fixed 5 8 "Den vítězství")
    (holiday-fixed 7 5 "Den slovanských věrozvěstů Cyrila a Metoděje")
    (holiday-fixed 7 6 "Den upálení mistra Jana Husa")
    (holiday-fixed 9 28 "Den české státnosti")
    (holiday-fixed 10 28 "Den vzniku samostatného československého státu")
    (holiday-fixed 11 17 "Den boje za svobodu a demokracii")
    (holiday-fixed 12 24 "Štědrý den")
    (holiday-fixed 12 25 "svátek vánoční")
    (holiday-fixed 12 26 "svátek vánoční"))
  "List of Czech public holidays.")

;;;###autoload
(defun czech-holidays-add ()
  "Add Czech public holidays to Emacs calendar."
  (mapc (lambda (d) (add-to-list 'holiday-other-holidays d t)) czech-holidays-list))

(provide 'czech-holidays)
;;; czech-holidays.el ends here
