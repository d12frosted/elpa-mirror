;;; lockfile-mode.el --- Major mode for .lock files -*- lexical-binding: t; -*-

;; Author: Preetpal S. Sohal
;; URL: https://github.com/preetpalS/emacs-lockfile-mode
;; Package-Version: 20170625.507
;; Package-Commit: 496b6035716df0582f879f9488f296947cabead2
;; Version: 0.1.0
;; License: GNU General Public License Version 3

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Usage:
;; (require 'lockfile-mode) ; unless installed from a package

;;; Code:

;;;###autoload
(define-derived-mode lockfile-mode fundamental-mode "lockfile"
  "A minimalistic major mode for `.lock' files."
  :abbrev-table nil
  (setq buffer-read-only t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lock\\'" . lockfile-mode))

(provide 'lockfile-mode)

;;; lockfile-mode.el ends here
