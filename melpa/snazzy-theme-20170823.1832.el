;;; snazzy-theme.el --- An elegant syntax theme with bright colors  -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Wei Jian Gan <weijiangan@outlook.com>

;;; Authors:
;; Scheme: Sindre Sorhus (https://sindresorhus.com/)
;; Template: Kaleb Elwert <belak@coded.io>

;; Keywords: faces, theme, color, snazzy
;; Package-Version: 20170823.1832
;; Package-Commit: 57a1763b49b4a776084c16bc70c219246fa5b412
;; URL: https://github.com/weijiangan/emacs-snazzy/
;; Version: 1.0
;; Package-Requires: ((emacs "24") (base16-theme "2.1"))

;; This file is not a part of GNU Emacs.

;;; License:

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Add this one-liner to your init.el:
;; (load-theme 'snazzy t)

;;; Code:

(require 'base16-theme)

(defvar snazzy-theme-colors
  '(:base00 "#1e1f29"
    :base01 "#34353e"
    :base02 "#4a4b53"
    :base03 "#78787e"
    :base04 "#a5a5a9"
    :base05 "#eff0eb"
    :base06 "#f1f1f0"
    :base07 "#f1f1f0"
    :base08 "#ff5c57"
    :base09 "#ff9f43"
    :base0A "#f3f99d"
    :base0B "#5af78e"
    :base0C "#9aedfe"
    :base0D "#57c7ff"
    :base0E "#ff6ac1"
    :base0F "#b2643c")
  "All colors for Snazzy theme are defined here.")

;; Define the theme
(deftheme snazzy)

;; Add all the faces to the theme
(base16-theme-define 'snazzy snazzy-theme-colors)

;; Mark the theme as provided
(provide-theme 'snazzy)

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide 'snazzy-theme)

;;; snazzy-theme.el ends here
