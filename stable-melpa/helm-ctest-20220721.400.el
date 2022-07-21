;;; helm-ctest.el --- Run ctest from within emacs

;; Copyright (C) 2015 Dan LaManna

;; Author: Dan LaManna <me@danlamanna.com>
;; Version: 1.0
;; Package-Version: 20220721.400
;; Package-Commit: 48edc9fa862219da34feb423c06c33d8f6d43722
;; Keywords: helm,ctest
;; Package-Requires: ((s "1.9.0") (dash "2.11.0") (helm-core "3.6.0"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
(require 's)
(require 'dash)
(require 'helm-core)

;;; Code:

(defcustom helm-ctest-dir nil
  "Directory to run ctest in."
  :group 'helm-ctest
  :type 'string)

(defcustom helm-ctest-env nil
  "Environment variables for tests."
  :group 'helm-ctest
  :type 'string)

(defcustom helm-ctest-bin "ctest"
  "Ctest execution binary"
  :group 'helm-ctest
  :type 'string
  )

(defcustom helm-ctest-candidates-command (concat helm-ctest-bin " -N")
  "Command used to list the tests."
  :group 'helm-ctest
  :type 'string)

(defun helm-ctest-build-dir()
  "Determine the directory to run ctest in, and set it to
  `helm-ctest-dir'.

   Ensures it has a trailing slash."
  (unless helm-ctest-dir
    (setq helm-ctest-dir
          (read-directory-name "CTest Build Dir: ")))
  (s-append "/" (s-chop-suffix "/" helm-ctest-dir)))

(defun helm-ctest-candidates()
  "Run ctest to figure out what test candidates exist."
  (let* ((ctest-cmd helm-ctest-candidates-command)
         (test-re "^Test[[:space:]]*#")
         (default-directory (helm-ctest-build-dir)))
    (-filter (lambda(s)
               (s-match test-re s))
             (-map 's-trim
                   (s-lines (shell-command-to-string ctest-cmd))))))

(defun helm-ctest-nums-from-strs(strs)
  "Takes a list of `strs' with elements like:
   'Test #17: pep8_style_core' and returns a list of numbers
   representing the strings.

   This is useful for turning the selected tests into a ctest command
   using their integer representation."
  (-map (lambda(s)
          (string-to-number
           (car (cdr (s-match "#\\([[:digit:]]+\\)" s)))))
        strs))

(defun helm-ctest-command(test-nums)
  "Create the command that ctest should run based on the selected
   candidates."
  (concat "env CLICOLOR_FORCE=1 CTEST_OUTPUT_ON_FAILURE=1 "
          helm-ctest-env " "
          helm-ctest-bin " -I "
          (s-join "," (-map (lambda(test-num)
                              (format "%d,%d," test-num test-num))
                            test-nums))))

(defun helm-ctest-action(&rest args)
  "The action to run ctest on the selected tests.

   Uses the compile interface."
  (let* ((test-strs (helm-marked-candidates))
         (test-nums (helm-ctest-nums-from-strs test-strs))
         (default-directory (helm-ctest-build-dir))
         (compile-command (helm-ctest-command test-nums)))
    (compile compile-command)))

;;;###autoload
(defun helm-ctest()
  (interactive)
  (helm :sources (helm-build-sync-source "CTests"
                   :candidates (helm-ctest-candidates)
                   :action '(("run tests" . helm-ctest-action)))
        :buffer "*helm ctest*"))

(provide 'helm-ctest)
;;; helm-ctest.el ends here
