;;; flycheck-keg.el --- Flycheck for Keg projects  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 0.0.1
;; Package-Version: 20200726.218
;; Package-Commit: d98113b8c32ad0164b05f92bec447d64268e311e
;; Keywords: convenience
;; Package-Requires: ((emacs "24.3") (keg "0.1") (flycheck "0.1"))
;; URL: https://github.com/conao3/keg.el

;; note: Flycheck requires Emacs-24.3 as minimum Emacs version.

;; This program is free software: you can redistribute it and/or modify
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

;; Flycheck for Keg projects.

;; To use this package, add below code in your init.el.

;;    (add-hook 'flycheck-mode-hook #'flycheck-keg-setup)

;;; Code:

(require 'keg)
(require 'flycheck)

(defgroup flycheck-keg nil
  "Flycheck for Keg projects."
  :group 'convenience
  :link '(url-link :tag "Github" "https://github.com/conao3/keg.el"))

(defcustom flycheck-keg-add-root-directory t
  "When non-nil, add the root directory to the load path.

If this variable is non nil, add the root directory of a Keg
project to `flycheck-emacs-lisp-load-path'."
  :group 'flycheck-keg
  :type 'boolean)

;;;###autoload
(defun flycheck-keg-setup ()
  "Setup Flycheck for Elisp project using Keg."
  (when (buffer-file-name)
    (let ((dir (keg-file-dir)))
      (when dir
        (setq-local flycheck-emacs-lisp-initialize-packages t)
        (setq-local flycheck-emacs-lisp-package-user-dir (keg-elpa-dir))
        (when (eq flycheck-emacs-lisp-load-path 'inherit)
          ;; Disable `load-path' inheritance if enabled.
          (setq-local flycheck-emacs-lisp-load-path nil))
        (when flycheck-keg-add-root-directory
          (setq-local flycheck-emacs-lisp-load-path
                      (cons dir flycheck-emacs-lisp-load-path)))))))

(provide 'flycheck-keg)
;;; flycheck-keg.el ends here
