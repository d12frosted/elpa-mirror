;;; consult-codesearch.el --- Consult interface for codesearch -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Youngjoo Lee

;; Author: Youngjoo Lee <youngker@gmail.com>
;; URL: https://github.com/youngker/consult-codesearch
;; Package-Version: 20230315.1424
;; Package-Commit: 51df545bb57b468058245950322ae15f6c3a0ce2
;; Version: 0.3
;; Keywords: tools
;; Package-Requires: ((emacs "27.1") (consult "0.20"))

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

;; Consult interface for codesearch
;;
;; See documentation on https://github.com/youngker/consult-codesearch.el

;;; Code:

(require 'consult)

(defgroup consult-codesearch nil
  "Consult interface for codesearch."
  :prefix "consult-codesearch-"
  :group 'consult)

(defvar consult-codesearch--args nil
  "Codesearch arguments.")

(defvar consult-codesearch-buffer "*codesearch*"
  "Codesearch buffer.")

(defcustom consult-codesearch-csearchindex ".csearchindex"
  "Index file for each projects."
  :type 'string
  :group 'consult-codesearch)

(defcustom consult-codesearch-find-file-args
  "csearch -l -f"
  "Codesearch file search command."
  :type 'string
  :group 'consult-codesearch)

(defcustom consult-codesearch-grep-args
  "csearch -n"
  "Codesearch search command."
  :type 'string
  :group 'consult-codesearch)

(defconst consult-codesearch--match-regexp
  "\\`\\(?:\\./\\)?\\([^\n\0]+\\):\\([0-9]+\\)\\([-:\0]\\)"
  "Regexp used to match file and line of codesearch output.")

(defun consult-codesearch--builder (_paths)
  "Build command line given PATHS."
  (let ((cmd (consult--build-args consult-codesearch--args)))
    (lambda (input)
      (pcase-let* ((`(,arg . ,opts) (consult--command-split input))
                   (flags (append cmd opts))
                   (files-with-matchs (member "-l" flags))
                   (ignore-case (member "-i" flags))
                   (`(,re . ,hl)
                    (funcall consult--regexp-compiler arg 'extended ignore-case)))
        (when re
          (cons (append cmd opts
                        (let ((jre (consult--join-regexps re 'extended)))
                          (if files-with-matchs
                              (list (concat "(?i)" jre) "$")
                            (list jre))))
                hl))))))

(defun consult-codesearch--set-index (dir)
  "Set CSEARCHINDEX variable in DIR."
  (let* ((start-dir (or dir default-directory))
         (index-dir (locate-dominating-file
                     start-dir consult-codesearch-csearchindex)))
    (if index-dir
        (setenv "CSEARCHINDEX"
                (expand-file-name (concat index-dir consult-codesearch-csearchindex)))
      (error "Can't find csearchindex"))))

;;;###autoload
(defun consult-codesearch-build-index (dir)
  "Create index file at DIR."
  (interactive "DIndex files in directory: ")
  (setenv "CSEARCHINDEX" (expand-file-name (concat dir consult-codesearch-csearchindex)))
  (let ((proc (apply 'start-process "codesearch"
                     consult-codesearch-buffer "cindex" (list (expand-file-name dir)))))
    (with-current-buffer consult-codesearch-buffer
      (pop-to-buffer consult-codesearch-buffer)
      (local-set-key (kbd "q") 'quit-window)
      (let ((buffer-read-only nil))
        (erase-buffer)))
    (set-process-filter
     proc
     (lambda (process output)
       (with-current-buffer (process-buffer process)
         (let ((buffer-read-only nil))
           (insert output)))))
    (set-process-sentinel
     proc
     (lambda (process event)
       (with-current-buffer (process-buffer process)
         (when (string= event "finished\n")
           (let ((buffer-read-only nil))
             (insert "\nIndexing finished"))
           (setq buffer-read-only t)))))))

;;;###autoload
(defun consult-codesearch (&optional dir)
  "Search with `codesearch' for files in DIR where the content matches a regexp.

The initial input is given by the INITIAL argument."
  (interactive "P")
  (let ((initial (substring-no-properties (or (thing-at-point 'symbol) "")))
        (consult-codesearch--args consult-codesearch-grep-args)
        (consult-async-refresh-delay 0.1)
        (consult-async-input-throttle 0)
        (consult-async-input-debounce 0)
        (consult--grep-match-regexp consult-codesearch--match-regexp)
        (_index (consult-codesearch--set-index dir)))
    (consult--grep "Codesearch" #'consult-codesearch--builder dir initial)))

;;;###autoload
(defun consult-codesearch-find-file (&optional dir)
  "Search for files in DIR matching input regexp given INITIAL input."
  (interactive "P")
  (let ((initial (substring-no-properties (or (thing-at-point 'symbol) "")))
        (consult-codesearch--args consult-codesearch-find-file-args)
        (consult-async-refresh-delay 0.1)
        (consult-async-input-throttle 0)
        (consult-async-input-debounce 0)
        (_index (consult-codesearch--set-index dir)))
    (pcase-let* ((`(,prompt ,paths ,dir) (consult--directory-prompt "Codesearch Find File" dir))
                 (default-directory dir)
                 (builder (consult-codesearch--builder paths)))
      (find-file (consult--find prompt builder initial)))))

(provide 'consult-codesearch)
;;; consult-codesearch.el ends here
