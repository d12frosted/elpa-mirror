;;; detour.el --- Take a quick detour and return    -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Stefan Kamphausen

;; Author: Stefan Kamphausen <www.skamphausen.de>
;; Homepage: https://github.com/ska2342/detour/
;; Created: 2018
;; Version: 1.0
;; Package-Version: 20181122.2138
;; Package-Commit: f41f17cf1cf4f3db41563ff011786b6567596fb4
;; Package-Requires: ((emacs "24.4"))
;; Keywords: convenience, abbrev

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package allows you to remember your current cursor position,
;; go somewhere else and then jump between those two positions.  It is
;; meant for quick detours and then continuing your work where you
;; left off.

;; Suggested keybindings:
;; (global-set-key [(control \.)] 'detour-mark)
;; (global-set-key [(control \,)] 'detour-back)

;; Or via use-package:
;;
;; (use-package detour
;;   :bind
;;   ([(control \.)] . detour-mark)
;;   ([(control \,)] . detour-back))

;; Internally, a register is used to store the position.  If you
;; manually set this register, these functions will not work.


;;; Code:
(defvar detour-version "0.9"
  "Version number of detour package.")

(defgroup detour nil
  "Taking a quick detour and return."
  :tag "Detour"
  :link '(url-link
          :tag "Home Page"
          "https://www.github.com/ska2342/detour/")
  :link '(emacs-commentary-link
          :tag "Commentary in detour.el"
          "detour.el")
  :prefix "detour-"
  :group 'convenience)

(defcustom detour-register 8
  "Register used to store the cursor position."
  :type 'integer
  :group 'detour)

(defun detour-mark ()
  "Store cursor position fast in a register.

Use `detour-back` to jump back to the stored position."
  (interactive)
  (point-to-register detour-register))

(defun detour-back ()
  "Jumps between current and stored cursor position."
  (interactive)
  (let ((tmp (point-marker)))
    (jump-to-register detour-register)
    (set-register detour-register tmp)))

(provide 'detour)
;;; detour.el ends here
