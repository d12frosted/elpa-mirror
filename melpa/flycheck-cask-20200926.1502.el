;;; flycheck-cask.el --- Cask support in Flycheck -*- lexical-binding: t; -*-

;; Copyright (C) 2013-2015  Sebastian Wiesner <swiesner@lunaryorn.com>

;; Author: Sebastian Wiesner <swiesner@lunaryorn.com>
;; URL: https://github.com/flycheck/flycheck-cask
;; Package-Version: 20200926.1502
;; Package-Commit: 4b2ede6362ded4a45678dfbef1876faa42edbd58
;; Keywords: tools, convenience
;; Version: 0.5-cvs
;; Package-Requires: ((emacs "24.3") (flycheck "0.14") (dash "2.4.0"))

;; This file is not part of GNU Emacs.

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

;; Add Cask support for Flycheck.

;; Configure Flycheck to initialize packages from Cask in Cask projects.

;;;; Setup

;; (add-hook 'flycheck-mode-hook #'flycheck-cask-setup)

;;; Code:

(require 'flycheck)
(require 'dash)
(require 'package)

(defgroup flycheck-cask nil
  "Cask support for Flycheck."
  :prefix "flycheck-cask-"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/flycheck/flycheck-cask"))

(defcustom flycheck-cask-add-root-directory t
  "When non-nil, add the root directory to the load path.

If this variable is non nil, add the root directory of a Cask
project to `flycheck-emacs-lisp-load-path'."
  :group 'flycheck-cask
  :type 'boolean)

(defcustom flycheck-cask-fall-back-to-package-user-dir nil
  "When non-nil, fall back to `package-user-dir'.

When non-nil, fall back to packages from `package-user-dir' for
non-Cask projects."
  :group 'flycheck-cask
  :type 'directory)

(defun flycheck-cask-package-dir (root-dir)
  "Get the package directory for ROOT-DIR."
  (expand-file-name (format ".cask/%s.%s/elpa"
                            emacs-major-version
                            emacs-minor-version)
                    root-dir))

(defun flycheck-cask-initialize-cask-dir (directory)
  "Initialise Flycheck for the given Cask DIRECTORY."
  (setq-local flycheck-emacs-lisp-initialize-packages t)
  (setq-local flycheck-emacs-lisp-package-user-dir
              (flycheck-cask-package-dir directory))
  (when (eq flycheck-emacs-lisp-load-path 'inherit)
    ;; Disable `load-path' inheritance if enabled.
    (setq-local flycheck-emacs-lisp-load-path nil))
  (when flycheck-cask-add-root-directory
    (setq-local flycheck-emacs-lisp-load-path
                (cons directory flycheck-emacs-lisp-load-path))))

;;;###autoload
(defun flycheck-cask-setup ()
  "Setup Cask integration for Flycheck.

If the current file is part of a Cask project, as denoted by the
existence of a Cask file in the file's directory or any ancestor
thereof, configure Flycheck to initialze Cask packages while
syntax checking.

Set `flycheck-emacs-lisp-initialize-packages' and
`flycheck-emacs-lisp-package-user-dir' accordingly."
  (when (buffer-file-name)
    (-if-let (root-dir (locate-dominating-file (buffer-file-name) "Cask"))
        (flycheck-cask-initialize-cask-dir root-dir)
      (when flycheck-cask-fall-back-to-package-user-dir
        (setq-local flycheck-emacs-lisp-initialize-packages t)
        (setq-local flycheck-emacs-lisp-package-user-dir package-user-dir)))))

(provide 'flycheck-cask)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; flycheck-cask.el ends here
