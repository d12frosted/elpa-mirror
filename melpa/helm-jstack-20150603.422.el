;;; helm-jstack.el --- Helm interface to Jps & Jstack for Java/JVM processes  -*- lexical-binding: t; -*-

;; Copyright (C) 2015 helm-jstack authors

;; Author: Raghav Kumar Gautam <rgautam@apache.com>
;; Keywords: Java, Jps, Jstack, JVM, Emacs, Elisp, Helm
;; Package-Version: 20150603.422
;; Package-Commit: aab0fd9f14794ae3a6e7cfbe7f6a81842ce4c23b
;; Package-Requires: ((emacs "24") (helm "1.7.0") (cl-lib "0.5"))

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

;; Look up jps, jstack/java stack trace through helm-interface.

;;; Code:
(require 'helm)
(require 'cl-lib)

(defcustom helm-jstack-follow-delay 1
  "Delay before jps summary pops up."
  :type 'number
  :group 'helm-jstack)

(defcustom helm-jps-prog "jps"
  "Name of the Jps program."
  :type 'string
  :group 'helm-jstack)

(defcustom helm-jstack-prog "jstack"
  "Name of the Jstack program."
  :type 'string
  :group 'helm-jstack)

(defcustom helm-jstack-args ""
  "Argument to pass to the Jstack program."
  :type 'string
  :group 'helm-jstack)

(defcustom helm-jps-args "-v"
  "Argument to pass to the Jps program."
  :type 'string
  :group 'helm-jstack)

;;(helm-jstack-get-candidates)
(defun helm-jstack-get-candidates ()
  "Run jps and get a list of java processes."
  (split-string (shell-command-to-string (format "%s %s" helm-jps-prog helm-jps-args)) "\n"))

;;(helm-jstack-persistent-action "13704 Launcher")
(defun helm-jstack-persistent-action (jps-line)
  "Display stack trace corresponding to JPS-LINE."
  (let* ((buf (get-buffer-create "*jstack*"))
	 (pid (string-to-number jps-line))
	 (command (format "%s %s %s" helm-jstack-prog helm-jstack-args pid)))
    (with-current-buffer buf
      (compilation-mode)
      (setq-local compile-command command)
      (setq-local compilation-ask-about-save nil)
      (cl-letf (((symbol-function 'message) #'format))
	(recompile))
      (display-buffer buf))))

(defvar helm-jstack-suggest-source
  `((name . "Jstack Suggest")
    (candidates . helm-jstack-get-candidates)
    (action . (("Jstack" . helm-jstack-persistent-action)))
    (persistent-action . helm-jstack-persistent-action)
    (pattern-transformer . downcase)
    (keymap . ,helm-map)
    (follow . 1)
    (follow-delay . ,helm-jstack-follow-delay)
    (requires-pattern . 0)))

;;;###autoload
(defun helm-jstack-suggest ()
  "Preconfigured `helm' for jstack lookup with jstack suggest."
  (interactive)
  (helm :sources 'helm-jstack-suggest-source
	:buffer "*helm jstack*"))

(defalias 'helm-jps 'helm-jstack-suggest)
(defalias 'helm-jvm 'helm-jstack-suggest)

(provide 'helm-jstack)
;;; helm-jstack.el ends here
