;;; pdb-capf.el --- Completion-at-point function for python debugger -*- lexical-binding: t -*-

;; Copyright (C) 2020 Andrii Kolomoiets

;; Author: Andrii Kolomoiets <andreyk.mad@gmail.com>
;; Keywords: languages, abbrev, convenience
;; Package-Commit: 2f4099aa1330f87df4e9cd526de057ee9b71de6c
;; Package-Version: 20200419.1237
;; Package-X-Original-Version: 1.0
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/muffinmad/emacs-pdb-capf

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; `completion-at-point' function that provides completions for current
;; pdb session.
;;
;; Add `pdb-capf' to `completion-at-point-functions' in buffer with
;; existing pdb session, e.g.:
;;
;;   (add-hook 'completion-at-point-functions 'pdb-capf nil t)
;;

;;; Code:

(require 'rx)
(require 'python)

(defvar pdb-capf-script
  (concat
   "import rlcompleter;"
   "__ECAP_N=locals().copy();__ECAP_N.update(**globals());"
   "__ECAP_T='''%s''';"
   "print(';'.join("
   "getattr(rlcompleter.Completer(__ECAP_N), 'attr_matches' if '.' in __ECAP_T else 'global_matches')"
   "(__ECAP_T)))")
  "Python script to get completions.")

(defun pdb-capf--completions (string)
  "Get completions for STRING from current pdb process."
  (let* ((buffer (current-buffer))
         (process (get-buffer-process buffer))
         (comint-prompt-regexp (concat "^" python-shell-prompt-pdb-regexp)))
    (with-temp-buffer
      ;; redirect output and send completion script
      (comint-redirect-send-command-to-process
       (format pdb-capf-script string)
       (current-buffer) process nil t)
      ;; wait for command output
      (with-current-buffer buffer
        (while (null comint-redirect-completed)
          (accept-process-output nil 0.1)))
      (goto-char (point-min))
      ;; skip first line in case process echoes input
      (unless (= (count-lines (point) (point-max)) 1)
        (forward-line 1))
      (let ((completions (buffer-substring-no-properties
                          (point)
                          (line-end-position))))
        (unless (string-equal completions "")
          (split-string completions ";"))))))

;;;###autoload
(defun pdb-capf ()
  "Return completion table for current pdb session."
  (when (and (process-live-p (get-buffer-process (current-buffer)))
             (save-excursion
               (forward-line 0)
               (looking-at python-shell-prompt-pdb-regexp)))
    (let* ((end (point))
           (start (save-excursion
                    (comint-goto-process-mark)
                    (point)))
           (start (save-excursion
                    (if (re-search-backward
                         (python-rx (or ":" whitespace open-paren close-paren
                                        string-delimiter simple-operator))
                         start t)
                        (+ (point) (length (match-string-no-properties 0)))
                      start))))
      (when (>= end start)
        (list start
              end
              (completion-table-with-cache #'pdb-capf--completions)
              :exclusive 'no)))))

(provide 'pdb-capf)

;;; pdb-capf.el ends here
