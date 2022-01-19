;;; pager-default-keybindings.el --- Add the default keybindings suggested for pager.el

;; Copyright (C) 2013 Nathaniel Flath <nflath@gmail.com>

;; Author: Nathaniel Flath <nflath@gmail.com>
;; URL: http://github.com/nflath/pager-default-keybindings
;; Package-Version: 20130719.2057
;; Package-Commit: dbbd49c2ac5906d1dabf9e9c832bfebc1ab405b3
;; Version: 1.1
;; Package-Requires: ((pager "1.0"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;;;This package sets the suggested keybindings for pager

;;; Installation:

;; To install, put this file somewhere in your load-path and add the following
;; to your .emacs file:
;; (require 'pager-default-keybindings)

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'pager)

(global-set-key "\C-v"     'pager-page-down)
(global-set-key [next]     'pager-page-down)
(global-set-key "\ev"      'pager-page-up)
(global-set-key [prior]    'pager-page-up)
(global-set-key '[M-up]    'pager-row-up)
(global-set-key '[M-kp-8]  'pager-row-up)
(global-set-key '[M-down]  'pager-row-down)
(global-set-key '[M-kp-2]  'pager-row-down)

(provide 'pager-default-keybindings)
;;; pager-default-keybindings.el ends here
