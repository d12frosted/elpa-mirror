;;; osx-pseudo-daemon.el --- Daemon mode that plays nice with OSX.

;; Author: Ryan C. Thompson
;; URL: https://github.com/DarwinAwardWinner/osx-pseudo-daemon
;; Package-Version: 20200215.513
;; Package-Commit: 94240ebb716f11af8427b6295c3f44c0c43419d3
;; Version: 2.2
;; Created: 2013-09-20
;; Keywords: convenience osx

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; This package has been renamed to mac-pseudo-daemon.el, to be
;; consistent with the renaming of OSX to Mac OS. Please install that
;; package instead.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
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

(require 'mac-pseudo-daemon)

(define-obsolete-function-alias 'osx-pseudo-daemon-mode 'mac-pseudo-daemon-mode "2.0")
(define-obsolete-variable-alias 'osx-pseudo-daemon-mode 'mac-pseudo-daemon-mode "2.0")

(provide 'osx-pseudo-daemon)

;;; osx-pseudo-daemon.el ends here
