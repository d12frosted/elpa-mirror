;;; pcmpl-pip.el --- pcomplete for pip

;; Copyright (C) 2014-2019 Wei Zhao
;; Author: zwild <judezhao@outlook.com>
;; Git: https://github.com/zwild/pcmpl-pip.git
;; Package-Requires: ((s "1.12.0") (f "0.19.0") (seq "2.15"))
;; Package-Version: 20181229.1420
;; Package-Commit: ebb672d4494f876f611639e65df4e28e566c06b5
;; Version: 0.5
;; Created: 2014-09-10
;; Time-stamp: <2017-12-01 16:08>
;; Keywords: pcomplete, pip, python, tools

;; This file is NOT part of GNU Emacs.

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

;; Pcomplete for python and pip.
;; Based on pip 9.0.1 docs.

;;; Code:
(provide 'pcmpl-pip)

(require 'pcomplete)

(defgroup pcmpl-pip nil
  "Pcomplete for pip"
  :group 'pcomplete)

(defcustom pcmpl-pip-command "pip3"
  "pip2 or pip3"
  :group 'pcmpl-pip
  :type 'string)

(defcustom pcmpl-pip-use-cache t
  "Cache packages for speed."
  :group 'pcmpl-pip
  :type 'boolean)

(defcustom pcmpl-pip-cache-file "~/.pip/zsh-cache"
  "Location of pip cache file."
  :group 'pcmpl-pip
  :type 'string)

(defcustom pcmpl-pip-complete-package-min-length 3
  "The minimum length of package name when needed to complete."
  :group 'pcmpl-pip
  :type 'number)

(defconst pcmpl-pip-index-url "https://pypi.python.org/simple/")

;;;###autoload
(defun pcmpl-pip-clean-cache ()
  "Clean the pip cache file."
  (interactive)
  (shell-command-to-string (concat "rm " pcmpl-pip-cache-file)))

;; https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/pip/pip.plugin.zsh
(defun pcmpl-pip-create-index ()
  "Create the pip indexes file."
  (let* ((temp "/tmp/pip-cache")
         (dir (file-name-directory pcmpl-pip-cache-file)))
    (message "caching pip package index...")
    (unless (file-exists-p dir)
      (make-directory dir))
    (shell-command-to-string (concat "curl " pcmpl-pip-index-url
                                     " | sed -n '/<a href/ s/.*>\\([^<]\\{1,\\}\\).*/\\1/p'"
                                     " >> " temp))
    (shell-command-to-string (concat "sort " temp
                                     " | uniq | tr '\n' ' ' > "
                                     pcmpl-pip-cache-file))
    (shell-command-to-string (concat "rm " temp))))

;;;###autoload
(defun pcmpl-pip-update-index ()
  "Update the current pip cache file."
  (interactive)
  (pcmpl-pip-clean-cache)
  (pcmpl-pip-create-index))

;; utils
(defun pcmpl-pip-complete-flags (flags-- &optional flags-)
  (while (cond
          ((pcomplete-match "^--" 0) (pcomplete-here flags--))
          ((pcomplete-match "^-" 0) (pcomplete-here flags-)))))

(defun pcmpl-commands-without-dash ()
  (seq-filter
   (lambda (s) (not (s-starts-with? "-" s)))
   pcomplete-args))

(defun pcmpl-contains-options (option)
  (seq-find (lambda (s) (string= s option)) pcomplete-args))

(defconst pcmpl-pip-all-packages
  (if (file-exists-p pcmpl-pip-cache-file)
      (split-string (shell-command-to-string (concat "cat " pcmpl-pip-cache-file)))
    '()))

(defun pcmpl-pip-complete-all-packages ()
  (while
      (when (>= (length (pcomplete-arg 'last))
                pcmpl-pip-complete-package-min-length)
        (pcomplete-here pcmpl-pip-all-packages))))

(defun pcmpl-pip-installed-packages ()
  "All installed packages."
  (split-string (shell-command-to-string
                 (format "%s freeze | cut -d '=' -f 1"
                         pcmpl-pip-command))))

;; options
(defconst pcmpl-python-options
  '("-b" "-B" "-c" "-d" "-E" "-h" "-i" "-I" "-m" "-O"
    "-OO" "-q" "-s" "-S" "-u" "-v" "-V" "-W" "-x" "-X"))

(defconst pcmpl-pip-general-options--
  '("--help" "--isolated" "--verbose" "--version" "--quiet"
    "--log" "--proxy" "--retries" "--timeout" "--exists-action"
    "--trusted-host" "--cert" "--client-cert" "--cache-dir"
    "--no-cache-dir" "--disable-pip-version-check"))

(defconst pcmpl-pip-commands
  '("install" "download" "uninstall" "freeze" "list" "show"
    "check" "search" "wheel" "hash" "completion" "help"))

(defconst pcmpl-pip-install-options--
  '("--constraint" "--editable" "--requirement" "--build"
    "--target" "--download" "--src" "--upgrade" "--upgrade-strategy"
    "--force-reinstall" "--ignore-installed" "--ignore-requires-python"
    "--no-deps" "--install-option" "--global-option" "--user""--egg"
    "--root" "--prefix" "--compile" "--no-compile" "--no-use-wheel"
    "--no-binary" "--only-binary" "--pre" "--no-clean" "--require-hashes"))

(defconst pcmpl-pip-install-options-
  '("-c" "-e" "-r" "-b" "-t" "-d" "-U" "-I"))

(defconst pcmpl-pip-download-options--
  '("--constraint" "--editable" "--requirement" "--build"
    "--no-deps" "--global-option" "--no-binary" "--only-binary"
    "--src" "--pre" "--no-clean" "--require-hashes" "--dest"
    "--platform" "--python-version" "--implementation" "--abi"
    "--index-url" "--extra-index-url" "--no-index"
    "--find-links" "--process-dependency-links"))

(defconst pcmpl-pip-download-options-
  '("-c" "-e" "-r" "-b" "-d" "-i" "-f"))

(defconst pcmpl-pip-list-options--
  '("--outdated" "--uptodate" "--editable" "--local"
    "--user" "--pre" "--format" "--not-required"))

(defconst pcmpl-pip-wheel-options--
  '("--wheel-dir" "--no-use-wheel" "--no-binary" "--only-binary"
    "--build-option" "--constraint" "--editable" "--requirement"
    "--src" "--ignore-requires-python" "--no-deps" "--build"
    "--global-option" "--pre" "--no-clean" "--require-hashes"))

(defconst pcmpl-pip-wheel-options-
  '("-w" "-c" "-e" "-r" "-b"))

;;;###autoload
(defun pcomplete/python ()
  (pcmpl-pip-complete-flags nil pcmpl-python-options)
  (pcomplete-here (pcomplete-entries)))

;;;###autoload
(defun pcomplete/pip ()
  (let ((command (nth 1 (pcmpl-commands-without-dash))))
    (when (and pcmpl-pip-use-cache
               (not (file-exists-p pcmpl-pip-cache-file)))
      (pcmpl-pip-create-index))
    (pcmpl-pip-complete-flags pcmpl-pip-general-options-- '("-h" "-v" "-V" "-q"))
    (pcomplete-here pcmpl-pip-commands)
    (cond ((string= command "install")
           (pcmpl-pip-complete-flags pcmpl-pip-install-options-- pcmpl-pip-install-options-)
           (when (or (pcmpl-contains-options "-U") (pcmpl-contains-options "--upgrade"))
             (while (pcomplete-here (pcmpl-pip-installed-packages))))
           (pcmpl-pip-complete-all-packages)
           (pcomplete-here (pcomplete-entries)))
          ((string= command "download")
           (pcmpl-pip-complete-flags pcmpl-pip-download-options-- pcmpl-pip-download-options-)
           (pcomplete-here (pcomplete-entries)))
          ((string= command "uninstall")
           (pcmpl-pip-complete-flags '("--requirement" "--yes") '("-r" "-y"))
           (when (or (pcmpl-contains-options "-r") (pcmpl-contains-options "--requirement"))
             (pcomplete-here (pcomplete-entries)))
           (while (pcomplete-here (pcmpl-pip-installed-packages))))
          ((string= command "freeze")
           (pcmpl-pip-complete-flags '("--requirement" "--find-links" "--local" "--user" "--all")
                                     '("-r" "-f" "-l"))
           (pcomplete-here (pcomplete-entries)))
          ((string= command "list")
           (pcmpl-pip-complete-flags pcmpl-pip-list-options-- '("-o" "-u" "-e" "-l")))
          ((string= command "show")
           (pcmpl-pip-complete-flags '("--files") '("-f"))
           (while (pcomplete-here (pcmpl-pip-installed-packages))))
          ((string= command "search")
           (pcmpl-pip-complete-flags '("--index") '("-i")))
          ((string= command "wheel")
           (pcmpl-pip-complete-flags pcmpl-pip-wheel-options-- pcmpl-pip-wheel-options-)
           (pcomplete-here (pcomplete-entries)))
          ((string= command "hash")
           (pcmpl-pip-complete-flags '("--algorithm") '("-a"))
           (pcomplete-here '("sha256" "sha384" "sha512")))
          ((string= command "help")
           (pcomplete-here pcmpl-pip-commands)))))

;;;###autoload
(defalias 'pcomplete/pip2 'pcomplete/pip)

;;;###autoload
(defalias 'pcomplete/pip3 'pcomplete/pip)

;;;###autoload
(defalias 'pcomplete/python3 'pcomplete/python)

;;; pcmpl-pip.el ends here
