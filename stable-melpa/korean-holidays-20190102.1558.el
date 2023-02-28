;;; korean-holidays.el --- Korean holidays for calendar.

;; Author: SeungKi Kim <tttuuu888@gmail.com>
;; URL: https://github.com/tttuuu888/korean-holidays
;; Package-Version: 20190102.1558
;; Package-Commit: 3f90ed86f46f8e5533f23baa40e2513ac497ca2b
;; Version: 0.1.0
;; Keywords: calendar

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; To use `korean-holidays' exclusively
;;
;;  (setq calendar-holidays korean-holidays)
;;
;; To use 'korean-holidays' additionally
;;
;;  (setq calendar-holidays (append calendar-holidays korean-holidays))
;;
;; inspired by german-holidays.el

;;; Code:

(eval-when-compile
  (require 'calendar)
  (require 'holidays))

;;;###autoload
(defvar korean-holidays
  '((holiday-fixed    1  1 "신정")
    (holiday-chinese  1  1 "설날")
    (holiday-fixed    3  1 "3.1절")
    (holiday-chinese  4  8 "부처님오신날")
    (holiday-fixed    5  5 "어린이날")
    (holiday-fixed    6  6 "현충일")
    (holiday-fixed    8 15 "광복절")
    (holiday-chinese  8 15 "추석")
    (holiday-fixed   10  3 "개천절")
    (holiday-fixed   10  9 "한글날")
    (holiday-fixed   12 25 "크리스마스"))
  "Korean holidays.")


(provide 'korean-holidays)

;;; korean-holidays.el ends here
