;;; slovak-holidays.el --- Adds a list of slovak holidays to Emacs calendar

;; Copyright (C) 2014 Matúš Goljer <matus.goljer@gmail.com>

;; Author: Matúš Goljer <matus.goljer@gmail.com>
;; Maintainer: Matúš Goljer <matus.goljer@gmail.com>
;; Version: 0.0.1
;; Package-Version: 20211018.1754
;; Package-Commit: bedd26dd45ca497c0028a11e94a905560fcdb2f1
;; Created: 10th September 2014
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

;; This package adds [slovak](http://en.wikipedia.org/wiki/Slovakia)
;; holidays to the Emacs calendar.
;;
;; If you have `org-agenda-include-diary` set to `t`, these will be
;; also listed in the `org-agenda` view.

;; Installation
;; ============
;;
;; If you install from MELPA, then you don't have to do anything as
;; the list will automatically autoload and be added to
;; `holiday-other-holidays` list.
;;
;; If you install manually, add a call to `(slovak-holidays-add)`
;; somewhere into your `.emacs`.  Note that this must be called
;; *before* Emacs calendar is loaded.

;;; Code:

;;;###autoload
(defvar slovak-holidays-list
  '((holiday-fixed 1 1 "Deň vzniku Slovenskej republiky")
    (holiday-fixed 1 6 "Zjavenie Pána (Traja králi)")
    (holiday-easter-etc  -2 "Veľký piatok")
    (holiday-easter-etc   0 "Veľká noc")
    (holiday-easter-etc  +1 "Veľkonočný pondelok")
    (holiday-fixed 3 25 "Deň zápasu za ľudské práva (pamätný deň)")
    (holiday-fixed 4 13 "Deň nespravodlivo stíhaných (pamätný deň)")
    (holiday-fixed 5 1 "Deň pristúpenia Slovenskej republiky k Európskej únii (pamätný deň)")
    (holiday-fixed 5 1 "Sviatok práce")
    (holiday-fixed 5 4 "Výročie úmrtia M. R. Štefánika (pamätný deň)")
    (holiday-fixed 5 8 "Deň víťazstva nad fašizmom")
    (holiday-fixed 6 7 "Výročie Memoranda národa slovenského (pamätný deň)")
    (holiday-fixed 7 5 "Deň zahraničných Slovákov (pamätný deň)")
    (holiday-fixed 7 5 "Sviatok svätého Cyrila a Metoda")
    (holiday-fixed 7 17 "Výročie deklarácie o zvrchovanosti SR (pamätný deň)")
    (holiday-fixed 8 10 "Deň obetí banských nešťastí (pamätný deň)")
    (holiday-fixed 8 29 "Výročie SNP")
    (holiday-fixed 8 4 "Deň Matice Slovenskej (pamätný deň)")
    (holiday-fixed 9 1 "Deň Ústavy Slovenskej republiky")
    (holiday-fixed 9 9 "Deň obetí holokaustu a rasového násilia (pamätný deň)")
    (holiday-fixed 9 15 "Sedembolestná Panna Mária")
    (holiday-fixed 9 19 "Deň vzniku Slovenskej národnej rady (pamätný deň)")
    (holiday-fixed 10 6 "Deň obetí Dukly (pamätný deň)")
    (holiday-fixed 10 27 "Deň Černovskej tragédie (pamätný deň)")
    (holiday-fixed 10 28 "Deň vzniku samostatného Česko-slovenského štátu (pamätný deň)")
    (holiday-fixed 10 29 "Deň narodenia Ľ. Štúra (pamätný deň)")
    (holiday-fixed 10 30 "Výročie Deklarácie slovenského národa (pamätný deň)")
    (holiday-fixed 10 31 "Deň reformácie (pamätný deň)")
    (holiday-fixed 11 1 "Sviatok všetkých svätých")
    (holiday-fixed 11 17 "Deň boja za slobodu a demokraciu")
    (holiday-fixed 12 24 "Štedrý deň")
    (holiday-fixed 12 25 "Prvý sviatok vianočný")
    (holiday-fixed 12 26 "Druhý sviatok vianočný")
    (holiday-fixed 12 30 "Deň vyhlásenia Slovenska za samostatnú cirkevnú provinciu (pamätný deň)")
    "List of slovak holidays."))

;;;###autoload
(defun slovak-holidays-add ()
  "Add slovak holidays to Emacs calendar."
  (mapc (lambda (d) (add-to-list 'holiday-other-holidays d t)) slovak-holidays-list))

(provide 'slovak-holidays)
;;; slovak-holidays.el ends here
