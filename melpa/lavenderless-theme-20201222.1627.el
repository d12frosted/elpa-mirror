;;; lavenderless-theme.el --- A mostly colorless version of lavender-theme

;; Copyright (C) 2019-2020 Thomas Letan
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;; Author: Thomas Letan <lthms@soap.coffee>
;; URL: https://git.sr.ht/~lthms/colorless-themes.el
;; Package-Version: 20201222.1627
;; Package-Commit: c1ed1e12541cf05cc6c558d23c089c07e10b54d7
;; Version: 0.2
;; Package-Requires: ((colorless-themes "0.2"))
;; License: GPL-3
;; Keywords: faces theme

;;; Commentary:
;; This file has been automatically generated from a template of the
;; colorless themes project.

;;; Code:

;; -*- lexical-binding: t -*-

(require 'colorless-themes)

(deftheme lavenderless "A mostly colorless version of lavender-theme")

(colorless-themes-make lavenderless
                       "#29222E"    ; bg
                       "#362145"    ; bg+
                       "#3b3341"    ; current-line
                       "#51415C"    ; fade
                       "#E0CEED"    ; fg
                       "#d2c2d7"    ; fg+
                       "#68d3a7"    ; docstring
                       "#cc3333"    ; red
                       "#FF6200"    ; orange
                       "#F4DC97"    ; yellow
                       "#A6E22E")   ; green

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'lavenderless)
(provide 'lavenderless-theme)
;;; lavenderless-theme.el ends here
