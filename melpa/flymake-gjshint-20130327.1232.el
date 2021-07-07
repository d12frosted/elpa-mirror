;;; flymake-gjshint.el --- A flymake handler for javascript using both jshint and gjslint

;; Copyright (C) 2013  Yasuyuki Oka

;; Author: Yasuyuki Oka <yasuyk@gmail.com>
;; Keywords: flymake, javascript, jshint, gjslint
;; Package-Version: 20130327.1232
;; Package-Commit: dc957c14cb060819585de8aedb330e24efa4b784
;; Version: 0.0.6

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

;; Add to your Emacs config:

;;   (require 'flymake-gjshint)
;;   (add-hook 'js-mode-hook 'flymake-gjshint:load)
;;
;;
;; If you want to disable flymake-gjshint in a certain directory
;; (e.g. test code directory), set flymake-gjshint to nil in `.dir-locals.el'.
;;
;; Here’s an example of a `.dir-locals.el' file:
;; -----------------------------------
;; ((nil . ((flymake-gjshint . nil))))
;; -----------------------------------
;;
;; Command:
;;
;; The following command is defined:
;;
;; * `flymake-gjshint:fixjsstyle'
;;   Fix many of the glslint errors in current buffer by fixjsstyle.
;;

;;; Code:

(require 'flymake)

(defgroup flymake-gjshint nil
  "Flymake checking of Javascript using jshint and gjslint"
  :group 'programming
  :prefix "flymake-gjshint")

;;;###autoload
(defcustom flymake-gjshint 'both
  "Tool(s) to check syntax Javascript source code.

Must be one of `both', `jshint', `gjslint' or nil.
Set `both' to enable both `jshint' and `gjslint'.
If This variable is nil, flymake is disabled."
  :type 'symbol
  :group 'flymake-gjshint)
(put 'flymake-gjshint 'safe-local-variable 'symbolp)

;;;###autoload
(defcustom flymake-gjshint:jshint-configuration-path nil
  "Absolute Path to a JSON configuration file for JSHint.

If you locate `.jshintrc` in home directory, you need not to set this variable.
JSHint will look for this file in the current working directory
and, if not found, will move one level up the directory tree all
the way up to the filesystem root."
  :type 'string
  :group 'flymake-gjshint)

;;;###autoload
(defcustom flymake-gjshint:gjslint-flagfile-path nil
  "Absolute Path to a configuration file for Closure Linter."
  :type 'string
  :group 'flymake-gjshint)

;;;###autoload
(defcustom flymake-gjshint:jshint-command "jshint"
  "Name (and optionally full path) of jshint executable."
  :type 'string :group 'flymake-gjshint)

;;;###autoload
(defcustom flymake-gjshint:gjslint-command "gjslint"
  "Name (and optionally full path) of gjslint executable."
  :type 'string :group 'flymake-gjshint)

;;;###autoload
(defcustom flymake-gjshint:fixjsstyle-command "fixjsstyle"
  "Name (and optionally full path) of fixjsstyle executable."
  :type 'string :group 'flymake-gjshint)

(defun flymake-gjshint:jshint-command-line ()
  "Create jshint command line."
  (if flymake-gjshint:jshint-configuration-path
      (format "%s --config %s "
              flymake-gjshint:jshint-command
              flymake-gjshint:jshint-configuration-path)
    flymake-gjshint:jshint-command))

(defun flymake-gjshint:gjslint-command-line ()
  "Create gjslint command line."
  (if flymake-gjshint:gjslint-flagfile-path
      (format "%s --flagfile %s "
              flymake-gjshint:gjslint-command
              flymake-gjshint:gjslint-flagfile-path)
    flymake-gjshint:gjslint-command))

(defun flymake-gjshint:init ()
  "Create syntax check command line using jshint and gjslint."
  (let* ((tempfile (flymake-init-create-temp-buffer-copy
                    'flymake-create-temp-inplace)))
    (cond ((eq flymake-gjshint 'both)
           (list "sh"
                 (list "-c"
                       (format "%s %s; %s %s;"
                               (flymake-gjshint:jshint-command-line) tempfile
                               (flymake-gjshint:gjslint-command-line) tempfile))))
          ((eq flymake-gjshint 'jshint)
           (if flymake-gjshint:jshint-configuration-path
               (list flymake-gjshint:jshint-command
                     (list tempfile "--config" flymake-gjshint:jshint-configuration-path))
           (list flymake-gjshint:jshint-command (list tempfile))))
          ((eq flymake-gjshint 'gjslint)
           (if flymake-gjshint:gjslint-flagfile-path
               (list flymake-gjshint:gjslint-command
                     (list tempfile "--flagfile" flymake-gjshint:gjslint-flagfile-path))
             (list flymake-gjshint:gjslint-command (list tempfile))))
           (t nil))))

(defvar flymake-gjshint:allowed-file-name-masks
  '(".+\\.js$"
    flymake-gjshint:init
    flymake-simple-cleanup
    flymake-get-real-file-name))

(defvar flymake-gjshint:gjslint-err-line-patterns
  '("^Line \\([[:digit:]]+\\), E:[[:digit:]]+: \\(.*\\)$"
    nil 1 nil 2))

(defvar flymake-gjshint:jshint-err-line-patterns
  '("^\\(.*\\): line \\([[:digit:]]+\\), col \\([[:digit:]]+\\), \\(.+\\)$"
    1 2 3 4))

;;;###autoload
(defun flymake-gjshint:fixjsstyle ()
  "Fix many of the glslint errors in current buffer by fixjsstyle."
  (interactive)
  (if (executable-find flymake-gjshint:fixjsstyle-command)
      (when (equal 0 (call-process-shell-command
                      (format "%s '%s'"
                              flymake-gjshint:fixjsstyle-command
                              (buffer-file-name))))
        (let ((file-name (buffer-file-name)))
          (when (buffer-modified-p)
            (save-buffer))
          (kill-buffer (buffer-name))
          (find-file file-name)))
    (message (format "%s not found."
                     flymake-gjshint:fixjsstyle-command))))

(defun flymake-gjshint:setup ()
  "Set up flymake for gjshint."
  (when flymake-gjshint
    (make-local-variable 'flymake-allowed-file-name-masks)
    (make-local-variable 'flymake-err-line-patterns)

    (add-to-list 'flymake-allowed-file-name-masks
                 flymake-gjshint:allowed-file-name-masks)
    (add-to-list 'flymake-err-line-patterns
                 flymake-gjshint:gjslint-err-line-patterns)
    (add-to-list 'flymake-err-line-patterns
                 flymake-gjshint:jshint-err-line-patterns)
    (flymake-mode 1)))

(defvar flymake-gjshint:jshint-url
  "http://www.jshint.com"
  "`jshint` website URL.")

(defvar flymake-gjshint:gjslint-url
  "https://developers.google.com/closure/utilities/docs/linter_howto"
  "`gjslint` website URL.")

;;;###autoload
(defun flymake-gjshint:load ()
  "Configure flymake mode to check the current buffer's javascript syntax.

This function is designed to be called in `js-mode-hook' or
equivalent; it does not alter flymake's global configuration, so
function `flymake-mode' alone will not suffice."
  (interactive)
  (let ((jshint (executable-find flymake-gjshint:jshint-command))
        (gjslint (executable-find flymake-gjshint:gjslint-command)))
    (if (and flymake-gjshint (or jshint gjslint))
        (progn
          (make-local-variable 'hack-local-variables-hook)
          (add-hook 'hack-local-variables-hook 'flymake-gjshint:setup))
      (unless jshint
        (message (format
                  "jshint not found. Install it from %s"
                  flymake-gjshint:jshint-url)))
      (unless gjslint
        (message (format
                  "gjslint not found. Install it from %s"
                  flymake-gjshint:gjslint-url))))))

(provide 'flymake-gjshint)

;;; flymake-gjshint.el ends here
