;;; import-popwin.el --- popwin buffer near by import statements with popwin -*- lexical-binding: t -*-

;; Copyright (C) 2017 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-import-popwin
;; Package-Version: 20170218.1407
;; Package-Commit: bb05a9e226f8c63fe7b18a3e92010357049ab5ba
;; Version: 0.10
;; Package-Requires: ((emacs "24.3") (popwin "0.6"))

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

;; Pop up buffer with pop-win near by import statements. For example
;; in C language, pop up near by include statements.
;;
;; This package is inspired by this article
;;  - http://shibayu36.hatenablog.com/entry/2013/01/03/223056

;;; Code:

(require 'cl-lib)
(require 'popwin)

(defgroup import-popwin nil
  "popup buffer near by import statements"
  :group 'popwin)

(defcustom import-popwin:height 0.4
  "height of popwin buffer"
  :type 'number)

(defcustom import-popwin:position 'bottom
  "position of popwin buffer"
  :type 'symbol)

(defvar import-popwin:info nil)

(defvar import-popwin:common-before-hook nil
  "common hook before popup window")

(defvar import-popwin:common-after-hook nil
  "common hook after popup window")

(defmacro import-popwin:run-hooks-with-save-excursion (hook)
  `(save-excursion
     (run-hooks ,hook)))

(defmacro import-popwin:funcall-with-save-excursion (func)
  `(when ,func
     (save-excursion
       (funcall ,func))))

(defun import-popwin:match-mode (mode modes)
  (cond ((listp modes) (member mode modes))
        (t (eq mode modes))))

(defun import-popwin:find-info (mode)
  (cl-loop for info in import-popwin:info
           for modes = (car info)
           when (import-popwin:match-mode mode modes)
           return (cdr info)))

;;;###autoload
(defun import-popwin ()
  (interactive)
  (let ((info (import-popwin:find-info major-mode)))
    (unless info
      (error (format "%s information is not registered!!" major-mode)))
    (let ((before-func (plist-get info :before))
          (fallback-func (plist-get info :fallback))
          (after-func (plist-get info :after))
          (regexp (plist-get info :regexp)))
      (import-popwin:run-hooks-with-save-excursion
       'import-popwin:common-before-hook)
      (import-popwin:funcall-with-save-excursion before-func)
      (popwin:popup-buffer (current-buffer)
                           :height import-popwin:height
                           :position import-popwin:position)
      (goto-char (line-end-position))
      (or (re-search-backward regexp nil t)
          (import-popwin:funcall-with-save-excursion fallback-func)
          (goto-char (point-min)))
      (forward-line 1)
      (recenter)
      (import-popwin:run-hooks-with-save-excursion
       'import-popwin:common-after-hook)
      (import-popwin:funcall-with-save-excursion after-func))))

(defun import-popwin:registered-info-p (mode-list)
  (cl-loop for mode in mode-list
           when (cl-loop for info in import-popwin:info
                         when (import-popwin:match-mode mode (car info))
                         return info)
           return it))

(defun import-popwin:override-info (mode params oldinfo)
  (setcar oldinfo mode)
  (setcdr oldinfo params))

(defun import-popwin:validate-parameters (plist)
  (cl-loop for prop in '(:mode :regexp)
           unless (plist-get plist prop)
           do
           (error "missing mandatory parameter '%s'" prop)))

(defun import-popwin:collect-info-properties (plist)
  (cl-loop for prop in '(:before :regexp :after :fallback)
           append (list prop (plist-get plist prop))))

(defun import-popwin:add (&rest plist)
  (import-popwin:validate-parameters plist)
  (let* ((mode (plist-get plist :mode))
         (params (import-popwin:collect-info-properties plist))
         (mode-list (or (and (listp mode) mode) (list mode)))
         (registered-info (import-popwin:registered-info-p mode-list)))
    (if registered-info
        (import-popwin:override-info mode-list params registered-info)
      (push (cons mode-list params) import-popwin:info))))

;; Default configuration
(import-popwin:add :mode '(c-mode c++-mode)
                   :regexp "^#include")

(import-popwin:add :mode 'java-mode
                   :regexp "^import")

(import-popwin:add :mode '(cperl-mode perl-mode)
                   :regexp "^\\s-*use\\s-*[^;]+;")

(import-popwin:add :mode '(ruby-mode enh-ruby-mode)
                   :regexp "^require\\s-")

(import-popwin:add :mode 'python-mode
                   :regexp "^\\(?:import\\|from\\)\\s-+")

(import-popwin:add :mode 'emacs-lisp-mode
                   :regexp "^\\s-*(require\\s-+")

(import-popwin:add :mode '(js-mode js2-mode javascript-mode)
                   :regexp "=\\s-*require\\s-*(\\s-*")

(import-popwin:add :mode 'coffee-mode
                   :regexp "^\\S-*\\s-*=\\s-*require\\s-*\\(?:['\"]\\|(\\)")

(import-popwin:add :mode 'go-mode
                   :regexp "^import\\s-*")

(import-popwin:add :mode 'haskell-mode
                   :regexp "^import\\s-*")

(import-popwin:add :mode 'scala-mode
                   :regexp "^import\\s-*")

(provide 'import-popwin)

;;; import-popwin.el ends here
