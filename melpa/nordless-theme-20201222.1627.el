;;; nordless-theme.el --- A mostly colorless version of nord-theme

;; Copyright (C) 2018-2020 Thomas Letan
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

(deftheme nordless "A mostly colorless version of nord-theme")

(colorless-themes-make nordless
                       "#2E3440"    ; bg
                       "#3B4252"    ; bg+
                       "#434C5E"    ; current-line
                       "#4C566A"    ; fade
                       "#D8DEE9"    ; fg
                       "#E5E9F0"    ; fg+
                       "#88C0D0"    ; docstring
                       "#BF616A"    ; red
                       "#D08770"    ; orange
                       "#EBCB8B"    ; yellow
                       "#A3BE8C")   ; green

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'nordless)
(provide 'nordless-theme)
;;; nordless-theme.el ends here
