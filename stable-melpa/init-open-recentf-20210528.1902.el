;;; init-open-recentf.el --- Invoke a command immediately after startup -*- lexical-binding: t -*-

;; Copyright (C) 2020 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 26 Oct 2015
;; Version: 0.2.1
;; Package-Version: 20210528.1902
;; Package-Commit: c019ea85a9c589815b0af60153858d09bcef130e
;; Homepage: https://github.com/zonuexe/init-open-recentf.el
;; Keywords: files recentf after-init-hook
;; Package-Requires: ((emacs "24.4"))
;; License: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.

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
;;
;; Open recentf immediately after Emacs is started.
;; Here are some example scenarios for when Emacs is started from the command line:
;;   - If files are opened (e.g. '$ emacs file1.txt'), nothing out of the ordinary occurs-- the file is opened.
;;   - However if a file is not indicated (e.g. '$ emacs '), recentf will be opened after emacs is initialized.
;; This script uses only the inbuilt advice function for startup.  It does not require or use any interactive function.
;; (This approach is a dirty hack, but an alternative hook to accomplish the same thing does not exist.)
;;
;; Put the following into your .emacs file (~/.emacs.d/init.el)
;;
;;   (init-open-recentf)
;;
;; `init-open-recentf' supports the following frameworks: helm, ido, anything (and the default Emacs setup without those frameworks).
;;  The package determines the frameworks from your environment, but you can also indicate it explicitly.
;;
;;   (setq init-open-recentf-interface 'ido)
;;   (init-open-recentf)
;;
;; Another possible configuration is demonstrated below if you want to specify an arbitrary function.
;;
;;   (setq init-open-recentf-function #'awesome-open-recentf)
;;   (init-open-recentf)
;;

;;; Code:
(eval-when-compile
  (require 'cl-lib))
(require 'recentf)

(eval-when-compile
  (declare-function anything-recentf "ext:anything.el" () t)
  (declare-function counsel-recentf "ext:counsel.el" () t)
  (declare-function helm-recentf "ext:helm-for-files.el" () t)
  (declare-function consult-recent-file "ext:consult.el" () t))

(defgroup init-open-recentf nil
  "init-open-recentf"
  :group 'initialization)

(defcustom init-open-recentf-function nil
  "Function to open recentf files (or other)."
  :type '(function :tag "Invoke recentf (or other) function")
  :group 'init-open-recentf)

(defcustom init-open-recentf-interface
  nil
  "Interface to open recentf files."
  :type '(radio (const :tag "Use ido interface" 'ido)
                (const :tag "Use helm interface" 'helm)
                (const :tag "Use anything interface" 'anything)
                (const :tag "Use Ivy/counsel interface" 'counsel)
                (const :tag "Use Consult command" 'consult)
                (const :tag "Use Emacs default (recentf-open-files)" 'default)
                (const :tag "Select automatically" 'nil))
  :group 'init-open-recentf)

(defcustom init-open-recentf-use-advice (eval-when-compile (< emacs-major-version 27))
  "If T, use advice to `command-line-1'."
  :type 'boolean
  :group 'init-open-recentf)

(defvar init-open-recentf-before-hook nil
  "Run hooks before `init-open-recentf-open'.")

(defvar init-open-recentf-after-hook nil
  "Run hooks after `init-open-recentf-open'.")

(defun init-open-recentf--opened-file-buffer ()
  "Return T when there are opened file buffers."
  (cl-loop for buf in (buffer-list)
           if (buffer-local-value 'buffer-file-name buf)
           return t))

(defun init-open-recentf-interface ()
  "Return the symbol of the detected Emacs user interface mode."
  (or init-open-recentf-interface
      (cond
       ((bound-and-true-p helm-mode) 'helm)
       ((bound-and-true-p ido-mode) 'ido)
       ((bound-and-true-p counsel-mode) 'counsel)
       ((fboundp 'consult-recent-file) 'consult)
       ((fboundp 'anything-recentf) 'anything)
       (:else 'default))))

(defun init-open-recentf-dwim ()
  "Open recent file command you want (Do What I Mean)."
  (if init-open-recentf-function
      (call-interactively init-open-recentf-function)
    (cl-case (init-open-recentf-interface)
      ((consult) (consult-recent-file))
      ((helm) (helm-recentf))
      ((ido) (find-file (ido-completing-read "Find recent file: " recentf-list)))
      ((counsel) (counsel-recentf))
      ((anything) (anything-recentf))
      ((default) (recentf-open-files)))))

(defun init-open-recentf-open (&rest _dummy-args)
  "If files are opened, does nothing.  Open recentf otherwise.
`DUMMY-ARGS' is ignored."
  (run-hooks 'init-open-recentf-before-hook)
  (cond
   ((init-open-recentf--opened-file-buffer) t)
   ((recentf-enabled-p) (init-open-recentf-dwim))
   (:else
    (error "`recentf-mode' is not enabled")))
  (run-hooks 'init-open-recentf-after-hook))

;;;###autoload
(defun init-open-recentf ()
  "Set 'after-init-hook ."
  (prog1 t
    (if init-open-recentf-use-advice
        (advice-add 'command-line-1 :after #'init-open-recentf-open)
      (run-with-idle-timer 0.00001 nil #'init-open-recentf-open))))

(provide 'init-open-recentf)
;;; init-open-recentf.el ends here
