;;; helm-rubygems-local.el --- Installed local rubygems find-file for helm

;; Copyright (C) 2013 by hadashiA

;; Author: hadashiA <dev@hadashikick.jp>
;; URL: https://github.com/f-kubotar/helm-rubygems-local
;; Package-Version: 20130712.111
;; Package-Commit: 289cb33d41c703af9791d6da46b55f070013c2e3
;; Version: 0.0.1
;; Package-Requires: ((helm "1.5.3"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(defvar helm-c-source-rubygems-local
  '((name . "rubygems")
    (candidates-in-buffer)
    (init . (lambda ()
              (let ((gemfile-dir
                     (block 'find-gemfile
                       (let* ((cur-dir (file-name-directory
                                        (expand-file-name (or (buffer-file-name)
                                                              default-directory))))
                              (cnt 0))
                         (while (and (< (setq cnt (+ 1 cnt)) 10)
                                     (not (equal cur-dir "/")))
                           (when (member "Gemfile" (directory-files cur-dir))
                             (return-from 'find-gemfile cur-dir))
                           (setq cur-dir (expand-file-name (concat cur-dir "/.."))))
                         ))))
                (helm-attrset 'gem-command
                                  (concat (if gemfile-dir
                                              (format "BUNDLE_GEMFILE=%s/Gemfile bundle exec "
                                                      gemfile-dir)
                                            "")
                                          "gem 2>/dev/null"))
                (unless (helm-candidate-buffer)
                  (call-process-shell-command (format "%s list" (helm-attr 'gem-command))
                                              nil
                                              (helm-candidate-buffer 'local))))))
    (action . (lambda (gem-name)
                ;; (message (helm-attr 'gem-command))
                (let ((gem-which (shell-command-to-string
                                  (format "%s which %s"
                                          (helm-attr 'gem-command)
                                          (replace-regexp-in-string "\s+(.+)$" "" gem-name))))
                      (path))
                  (print gem-which)
                  (if (or (null gem-which)
                          (string= "" gem-which)
                          (string-match "^ERROR:" gem-which))
                      (message "Can't find ruby library file or shared library %s" gem-name)
                    (setq path (file-name-directory gem-which))
                    (if (and path (file-exists-p path))
                        (find-file path)
                      (message "no such file or directory: \"%s\"" path))
                    )
                  )))
    ))

;;;###autoload
(defun helm-rubygems-local ()
  (interactive)
  (helm-other-buffer
   '(helm-c-source-rubygems-local)
   "*helm local gems*"
  ))

(provide 'helm-rubygems-local)

;;; helm-rubygems-local.el ends here
