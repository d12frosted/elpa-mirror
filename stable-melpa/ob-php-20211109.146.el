;;; ob-php.el --- Execute PHP within org-mode blocks.
;; Copyright 2016 stardiviner

;; Author: stardiviner <numbchild@gmail.com>
;; Maintainer: stardiviner <numbchild@gmail.com>
;; Keywords: org babel php
;; Package-Version: 20211109.146
;; Package-Commit: 3699808eb1ba56268ccc2e366151183e91e8c711
;; URL: https://github.com/stardiviner/ob-php
;; Created: 04th May 2016
;; Version: 0.0.1
;; Package-Requires: ((org "8"))

;;; Commentary:
;;
;; Execute PHP within org-mode blocks.

;;; Code:
(require 'org)
(require 'ob)

(defgroup ob-php nil
  "org-mode blocks for PHP."
  :group 'org)

(defcustom org-babel-php-command "php"
  "The command to execute babel body code."
  :group 'ob-php
  :type 'string)

(defcustom org-babel-php-command-options nil
  "The php command options to use when execute code."
  :group 'ob-php
  :type 'string)

(defcustom ob-php:inf-php-buffer "*php*"
  "Default PHP inferior buffer."
  :group 'ob-php
  :type 'string)

;;;###autoload
(defun org-babel-execute:php (body params)
  "Orgmode Babel PHP evaluate function for `BODY' with `PARAMS'."
  (let* ((cmd (concat org-babel-php-command " " org-babel-php-command-options))
         (code (if (string-match-p "<\\?\\(?:php\\|=\\)\\_>" body)
                   body
                 (concat "<?php\n\n" body))))
    (org-babel-eval cmd body)))

;;;###autoload
(eval-after-load 'org
  '(add-to-list 'org-src-lang-modes '("php" . php)))

(defvar org-babel-default-header-args:php '())

(add-to-list 'org-babel-default-header-args:php
             '(:results . "output"))

(provide 'ob-php)

;;; ob-php.el ends here
