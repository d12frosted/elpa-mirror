;;; toggle-window.el --- toggle current window size between half and full

;; Copyright © 2014 Kenny Liu
;; Author: Kenny Liu
;; URL: https://github.com/deadghost/toggle-window
;; Package-Version: 20141207.1548
;; Package-Commit: e82c60e543933880402ede11e9423e48a17dde53
;; Git-Repository: git://github.com/deadghost/toggle-window.git
;; Created: 2014-12-06
;; Version: 0.1.0
;; Keywords: hide window

;; This file is not part of GNU Emacs
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

(defun toggle-window-max-window-height ()
  "Expand current window to max height."
  (interactive)
  (enlarge-window (frame-height)))

(defun toggle-window-hide-show-window ()
  "Toggles showing current window at half frame or full frame height."
  (interactive)
  (if (<= (window-height) (/ (frame-height) 2))
	  (toggle-window-max-window-height)
	(balance-windows)))

(provide 'toggle-window)
;;; toggle-window.el ends here
