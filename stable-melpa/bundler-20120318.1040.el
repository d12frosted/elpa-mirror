;;; bundler.el --- Interact with Bundler from Emacs

;; Copyright (c) 2011 Tobias Svensson <tob@tobiassvensson.co.uk>

;; Author: Tobias Svensson <tob@tobiassvensson.co.uk>
;; URL: http://github.com/tobiassvn/
;; Package-Version: 20120318.1040
;; Package-Commit: 4cb4fafe092d587cc9e58ff61cf900fb7f409adf
;; Keywords: bundler ruby
;; Created: 31 Dec 2011
;; Version: 1.1.0
;; Package-Requires: ((inf-ruby "2.1"))

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; Interact with Bundler from Emacs.
;;
;; 1) bundle-open
;;
;;    Wraps 'bundle open' which, if the given gem is installed and has been
;;    required correctly, will open the gem's source directory with dired.
;;
;; 2) bundle-console
;;
;;    Starts an inferior ruby process in the context of the current bundle
;;    using 'bundle console' (requires inf-ruby to be installed).
;;
;; 3) bundle-install, bundle-update, bundle-check
;;
;;    Runs the corresponding Bundler command with async-shell-command and
;;    *Bundler* as the target buffer. This exists so the output won't mess
;;    with the default buffer used by M-& and async-shell-command.

;;; Install

;; $ cd ~/.emacs.d/vendor
;; $ git clone git://github.com/tobiassvn/bundler.el.git
;;
;; In your emacs config:
;;
;; (add-to-list 'load-path "~/.emacs.d/vendor/bundler.el")
;; (require 'bundler)

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

(require 'inf-ruby)

;;;###autoload
(defun bundle-open (gem-name)
  "Queries for a gem name and opens the location of the gem in dired."
  (interactive (list (completing-read "Bundled gem: " (bundle-list-gems-cached))))
    (if (= (length gem-name) 0)
        (message "No gem name given.")
      (let ((gem-location (bundle-gem-location gem-name)))
        (if (= (length gem-location) 0)
            (message "Gem not found or Gemfile missing.")
          (dired gem-location)))))

;;;###autoload
(defun bundle-console ()
  "Run an inferior Ruby process in the context of the current bundle."
  (interactive)
  (run-ruby "bundle console"))

;;;###autoload
(defun bundle-check ()
  "Run bundle check for the current bundle."
  (interactive)
  (bundle-command "bundle check"))

;;;###autoload
(defun bundle-install ()
  "Run bundle install for the current bundle."
  (interactive)
  (bundle-command "bundle install"))

;;;###autoload
(defun bundle-update ()
  "Run bundle update for the current bundle."
  (interactive)
  (bundle-command "bundle update"))

(defun bundle-command (cmd)
  "Run cmd in an async buffer."
  (async-shell-command cmd "*Bundler*"))

(defun bundle-gem-location (gem-name)
  "Returns the location of the given gem or an empty string"
  "if it has not been resolved."
  (let ((bundler-stdout
         (shell-command-to-string
          (format "bundle show %s" (shell-quote-argument gem-name)))))
    (if (or (string-match "Could not locate Gemfile" bundler-stdout)
            (string-match "Could not find gem" bundler-stdout))
        ""
      (concat (replace-regexp-in-string "\n" "" bundler-stdout) "/"))))

(defvar bundle-gem-list-cache
  (make-hash-table)
  "Holds a hash table of gem lists per directory.")

(defun* bundle-locate-gemfile (&optional (dir default-directory))
  (let ((has-gemfile (directory-files dir nil "^Gemfile$"))
        (is-root (equal dir "/")))
    (cond
     (has-gemfile dir)
     (is-root
      (print (format
              "No Gemfile found in either %s or any parent directory!"
              default-directory))
      nil)
     ((bundle-locate-gemfile (expand-file-name ".." dir))))))

(defun bundle-list-gems-cached ()
  (let* ((gemfile-dir (bundle-locate-gemfile))
         (gem-list (gethash gemfile-dir bundle-gem-list-cache)))
    (unless gemfile-dir
      (return nil))
    (unless gem-list
      (print (format "Don't have directory %s in cache yet, updating." gemfile-dir))
      (setq gem-list (bundle-list-gems))
      (puthash gemfile-dir gem-list bundle-gem-list-cache))
    gem-list))

(defun bundle-list-gems ()
  (save-excursion
    (let* ((bundle-out (shell-command-to-string "bundle list"))
           (bundle-lines (split-string bundle-out "\n")))
    
      (defun parse-bundle-list-line (line)
        (if (string-match "^  \\* \\([^\s]+\\).*$" line)
            (match-string 1 line)
          nil))

      (mapcar 'parse-bundle-list-line bundle-lines))))

(provide 'bundler)
;;; bundler.el ends here.
