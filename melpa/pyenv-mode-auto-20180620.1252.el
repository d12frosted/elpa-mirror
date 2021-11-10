;;; pyenv-mode-auto.el --- Automatically activates pyenv version if .python-version file exists.

;; Copyright © 2016 Sviatoslav Bulbakha <mail@ssbb.me>

;; Author: Sviatoslav Bulbakha <mail@ssbb.me>
;; URL: https://github.com/ssbb/pyenv-mode-auto
;; Package-Version: 20180620.1252
;; Package-Commit: 347b94cd5ad22e33cc41be661c102d4548767858
;; Keywords: python, pyenv
;; Version: 0.1.1
;; Package-Requires: ((pyenv-mode "0.1.0") (s "1.11.0") (f "0.17.0"))

;; This file is NOT part of GNU Emacs.

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

;;; Commentary:
;;
;; This library provides easy way to automatically activate pyenv
;; with pyenv-mode if .python-version file exists.
;;
;;; Code:

(require 's)
(require 'f)
(require 'pyenv-mode)

(defun pyenv-mode-auto-hook ()
  "Automatically activates pyenv version if .python-version file exists."
  (f-traverse-upwards
   (lambda (path)
     (let ((pyenv-version-path (f-expand ".python-version" path)))
       (if (f-exists? pyenv-version-path)
           (progn
             (pyenv-mode-set (car (s-lines (s-trim (f-read-text pyenv-version-path 'utf-8)))))
             t))))))

(add-hook 'find-file-hook 'pyenv-mode-auto-hook)

(provide 'pyenv-mode-auto)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; pyenv-mode-auto.el ends here
