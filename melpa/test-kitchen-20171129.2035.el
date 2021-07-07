;;; test-kitchen.el --- Run test-kitchen inside of emacs

;; Copyright (C) 2015 JJ Asghar <http://jjasghar.github.io>
;; Author: JJ Asghar
;; URL: http://github.com/jjasghar/test-kitchen-el
;; Package-Version: 20171129.2035
;; Package-Commit: 0fc0ca4808425f03fbeb8125246043723e2a179a
;; Created: 2015
;; Version: 0.4.0
;; Keywords: chef ruby test-kitchen

;; This file is NOT part of GNU Emacs.
;;
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
;; See <http://www.gnu.org/licenses/> for a copy of the GNU General
;; Public License.

;;; Commentary:

;; This minor mode also assumes you have [[https://downloads.chef.io/chef-dk/][ChefDK]] installed.
;;
;; I'd like to thank [[https://twitter.com/camdez][Cameron Desautels]] for the jump start on this project. /me tips my hat to you sir.
;;
;; I'd also like to thank [[http://twitter.com/ionrock][Eric Larson]] for pushing me to keep this alive.
;;
;; This minor mode allows you to run test-kitchen in a separate buffer
;;
;;  * Run test-kitchen destroy in another buffer
;;  * Run test-kitchen list in another buffer
;;  * Run test-kitchen test in another buffer
;;  * Run test-kitchen verify in another buffer
;;
;; You'll probably want to define some key bindings to run these.
;;
;;   (global-set-key (kbd "C-c C-d") 'test-kitchen-destroy)
;;   (global-set-key (kbd "C-c C-t") 'test-kitchen-test)
;;   (global-set-key (kbd "C-c l") 'test-kitchen-list)
;;   (global-set-key (kbd "C-c C-kv") 'test-kitchen-verify)
;;   (global-set-key (kbd "C-c C-kc") 'test-kitchen-converge)

;; TODO:
;;
;; 1) Have a way to select the only one suite to run
;; 2) Have a way to select only one os to run

;;; Code:

(defcustom test-kitchen-destroy-command "chef exec kitchen destroy"
  "The command used to destroy a kitchen.")

(defcustom test-kitchen-list-command "chef exec kitchen list"
  "The command used to list the kitchen nodes.")

(defcustom test-kitchen-test-command "chef exec kitchen test"
  "The command used to run the tests.")

(defcustom test-kitchen-converge-command "chef exec kitchen converge"
  "The command used for converge project.")

(defcustom test-kitchen-verify-command "chef exec kitchen verify"
  "The command use to verify the kitchen.")

(defun test-kitchen-locate-root-dir ()
  "Return the full path of the directory where .kitchen.yml file was found, else nil."
  (locate-dominating-file (file-name-as-directory
                           (file-name-directory buffer-file-name))
                          ".kitchen.yml"))

(defvar test-kitchen-list-cache (make-hash-table :test 'equal)
  "Use it as cache for kitchen-list in format:
path/to/.kitchen.yml => '(cache timestamp-high-sec timestamp-low-sec timestamp-microseconds).")

;;; test kitchen is very likes colors, so colorize compilation buffer
(require 'ansi-color)

(defadvice display-message-or-buffer (before ansi-color activate)
  "Process ANSI color codes in shell output."
  (let ((buf (ad-get-arg 0)))
    (and (bufferp buf)
	 (string-match "^\\*kitchen.*\\*" (buffer-name buf))
	 (with-current-buffer buf
	              (ansi-color-apply-on-region (point-min) (point-max))))))

(defun test-kitchen-colorize-compilation-buffer ()
  (toggle-read-only)
  (ansi-color-apply-on-region compilation-filter-start (point))
  (toggle-read-only))

;; define test kitchen compilation mode
(define-compilation-mode test-kitchen-compilation-mode "Test Kitchen compilation"
  "Compilation mode for RSpec output."
  (add-hook 'compilation-filter-hook 'test-kitchen-colorize-compilation-buffer nil t))

(defun test-kitchen-run (cmd)
  (let ((root-dir (test-kitchen-locate-root-dir)))
    (if root-dir
        (let ((default-directory root-dir))
          (compile cmd 'test-kitchen-compilation-mode))
      (error "Couldn't locate .kitchen.yml!"))))

(defun test-kitchen-run-to-string (cmd)
  (let ((root-dir (test-kitchen-locate-root-dir)))
    (if root-dir
        (let ((default-directory root-dir))
          (shell-command-to-string cmd))
      (error "Couldn't locate .kitchen.yml!"))))

;;;###autoload
(defun test-kitchen-destroy (instance)
  "Run chef exec kitchen destroy in a different buffer."
  (interactive (list (completing-read "Kitchen instance to destroy: " (split-string (test-kitchen-list-bare)))))
  (test-kitchen-run (concat test-kitchen-destroy-command " " instance)))

;;;###autoload
(defun test-kitchen-destroy-all ()
  "Run chef exec kitchen destroy in a different buffer."
  (interactive)
  (test-kitchen-run test-kitchen-destroy-command))

(defun test-kitchen-list-update-cache ()
  (let* ((kitchen-root-dir (test-kitchen-locate-root-dir))
         (default-directory kitchen-root-dir)
         (kitchen-yml-path (concat (file-name-as-directory kitchen-root-dir) ".kitchen.yml"))
         (kitchen-yml-cache (gethash kitchen-yml-path test-kitchen-list-cache))
         (kitchen-yml-mod-time (when
                                   (file-exists-p kitchen-yml-path)
                                 (nth 5 (file-attributes kitchen-yml-path))))
         ;;
         (cache-expired-p (or
                           ;; check if cache exists
                           (null kitchen-yml-cache)
                           ;; check if cache timestamp earlier, than .kitchen.yml modification time
                           (< (nth 1 kitchen-yml-cache) (nth 0 kitchen-yml-mod-time))
                           (and
                            (= (nth 1 kitchen-yml-cache) (nth 0 kitchen-yml-mod-time))
                            (< (nth 2 kitchen-yml-cache) (nth 1 kitchen-yml-mod-time)))
                           (and
                            (= (nth 1 kitchen-yml-cache) (nth 0 kitchen-yml-mod-time))
                            (= (nth 2 kitchen-yml-cache) (nth 1 kitchen-yml-mod-time))
                            (< (nth 3 kitchen-yml-cache) (nth 2 kitchen-yml-mod-time)))))
         (current-time-stamp (current-time)))
    ;;
    (when cache-expired-p
      (setf
       (gethash kitchen-yml-path test-kitchen-list-cache)
       (list
        (test-kitchen-run-to-string (concat test-kitchen-list-command " -b 2>/dev/null"))
        (nth 0 current-time-stamp)
        (nth 1 current-time-stamp)
        (nth 2 current-time-stamp))))))

;;;###autoload
(defun test-kitchen-list-bare ()
  "Run chef exec kitchen list."
  (test-kitchen-list-update-cache)
  (let* ((kitchen-root-dir (test-kitchen-locate-root-dir))
         (kitchen-yml-path (concat (file-name-as-directory kitchen-root-dir) ".kitchen.yml")))
    (car (gethash kitchen-yml-path test-kitchen-list-cache))))

;;;###autoload
(defun test-kitchen-list ()
  "Run chef exec kitchen list in a different buffer."
  (interactive)
  (with-output-to-temp-buffer "*kitchen-list*"
    (princ (test-kitchen-run-to-string (concat test-kitchen-list-command " --color 2>/dev/null")))))

;;;###autoload
(defun test-kitchen-test (instance)
  "Run chef exec kitchen test in a different buffer."
  (interactive (list (completing-read "Kitchen instance to perform test: " (split-string (test-kitchen-list-bare)))))
  (test-kitchen-run (concat test-kitchen-test-command " " instance)))

;;;###autoload
(defun test-kitchen-test-all ()
  "Run chef exec kitchen test in a different buffer."
  (interactive)
  (test-kitchen-run test-kitchen-test-command))

;;;###autoload
(defun test-kitchen-converge (instance)
  "Run chef exec kitchen converge selected VM in a different buffer."
  (interactive (list (completing-read "Kitchen instance to converge: " (split-string (test-kitchen-list-bare)))))
  (test-kitchen-run (concat test-kitchen-converge-command " " instance)))

;;;###autoload
(defun test-kitchen-converge-all ()
  "Run chef exec kitchen converge in a different buffer."
  (interactive)
  (test-kitchen-run test-kitchen-converge-command))

;;;###autoload
(defun test-kitchen-verify (instance)
  "Run chef exec kitchen verify in a different buffer."
  (interactive (list (completing-read "Kitchen instance to verify: " (split-string (test-kitchen-list-bare)))))
  (test-kitchen-run (concat test-kitchen-verify-command " " instance)))

;;;###autoload
(defun test-kitchen-verify-all ()
  "Run chef exec kitchen verify in a different buffer."
  (interactive)
  (test-kitchen-run test-kitchen-verify-command))

(provide 'test-kitchen)
;;; test-kitchen.el ends here
