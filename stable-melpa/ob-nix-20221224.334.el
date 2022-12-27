;;; ob-nix.el --- Simple org-babel support for nix -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Wilko Meyer

;; Author: Wilko Meyer <w-devel@wmeyer.eu>
;; Keywords: lisp, tools
;; Package-Version: 20221224.334
;; Package-Commit: 76d71b37fb031f25bd52ff9c98b29292ebe0424e
;; Homepage: https://codeberg.org/theesm/ob-nix
;; Version: 0.01
;; Package-Requires: ((emacs "24.1"))

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

;;; Commentary:

;; Simple org-babel language support for nix expressions

;;; Requirements:

;; nix as well as nix-instantiate has to be installed and available

;;; Code:
(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)
;; possibly require modes required for your language

(defcustom ob-nix-command "nix-instantiate"
  "Name of command to use for executing nix code."
  :group 'org-babel
  :type 'string)

(defun org-babel-execute:nix (body params)
  "Evaluate nix code with org-babel.
Argument BODY takes a source blocks body.
Argument PARAMS takes a source block paramters."
  (let ((in-file (org-babel-temp-file "nix" ".nix"))
	 (json (cdr (assoc :json params)))
	 (xml (cdr (assoc :xml params)))
	 (strict (cdr (assoc :strict params)))
         (verbosity (or (cdr (assq :verbosity params)) t)))
    (let ((cmd (concat ob-nix-command
		 " --eval "
		 (if json
		 "--json ")
		 (if xml
		 "--xml ")
		 (if strict
		 "--strict ")
		 (if verbosity
		 "--verbose ")
		 " -- "
		 (org-babel-process-file-name in-file))))
    (with-temp-file in-file
      (insert body))
    (message "%s" cmd)
    (org-babel-eval cmd ""))))


(provide 'ob-nix)
;;; ob-nix.el ends here
