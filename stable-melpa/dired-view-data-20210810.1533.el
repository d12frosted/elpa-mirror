;;; dired-view-data.el --- View data from dired via ESS and R  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Shuguang Sun

;; Author: Shuguang Sun <shuguang79@qq.com>
;; Created: 2021/03/28
;; Version: 1.0
;; Package-Version: 20210810.1533
;; Package-Commit: 75d5f961926392feb408049d416ed5c4c2213f07
;; URL: https://github.com/ShuguangSun/dired-view-data
;; Package-Requires: ((emacs "26.1") (ess "18.10.1") (ess-view-data "1.0"))
;; Keywords: tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; View data from dired via ess(-r)

;; (require 'dired-view-data)
;; (dired-view-data-global-mode)
;; or call minor-mode in dired buffer mannualy
;; (dired-view-data-mode 1)
;; which make `dired-do-shell-command' (`S-!') recognize those files as well if
;; `dired-view-data-guess-shell-alist-p' is `t'.

;; In dired buffer, call `dired-view-data` (`V' or `C-c C-v') on a data file
;; (e.g., sas7bdat, xpt, rds, csv, rda or rdata), and buffer will pop up with
;; data displayed.

;; You can modify or add new format via `dired-view-data-data-name-format'.

;;; Code:

(require 'dired-x)
(require 'ess-r-mode)
(require 'ess-inf)
(require 'ess-view-data)
;; (require 'ob-R) ;; org-babel-R-initiate-session


(defgroup dired-view-data ()
  "Read data from dired, for example, sas7bdat for SAS."
  :group 'ess
  :prefix "dired-view-data-")

(defcustom dired-view-data-buffer-name-format "*R: View File*"
  "Buffer of R Session for data post-handling."
  :type 'string
  :group 'dired-view-data)

(defcustom dired-view-data-use-DT-p nil
  "If t, using DT for display."
  :type 'bool
  :group 'dired-view-data)

(defcustom dired-view-data-history-file nil
  "File to pick up history from.  nil means *no* history is read or written.
t means something like \".Rhistory\".
If this is a relative file name, it is relative to `ess-history-directory'.
Consequently, if that is set explicitly, you will have one history file
for all projects.
This is local version of `ess-history-file.'"
  :type 'bool
  :group 'dired-view-data)

(defcustom dired-view-data-default-directory nil
  "Where the R sesssion to start.
nil is from the data directory.
A directory means start the R session from it globally."
  :type 'directory
  :safe 'stringp
  :group 'dired-view-data)

(defcustom dired-view-data-guess-shell-alist-p t
  "Whether to add `dired-view-data' to `dired-guess-shell-alist-user'."
  :type 'bool
  :group 'dired-view-data)


(defcustom dired-view-data-data-name-format
  '((sas7bdat  "`%1$s` <- haven::read_sas('%2$s')\n"
               dired-view-data-view)
    (xpt       "`%1$s` <- foreign::read.xport('%2$s')\n"
               dired-view-data-view)
    (Rda       "`%1$s` <- get(load('%2$s')[1])\n"
               dired-view-data-view)
    (Rdata     "`%1$s` <- get(load('%2$s')[1])\n"
               dired-view-data-view)
    (rds       "`%1$s` <- readRDS('%2$s')\n"
               dired-view-data-view)
    (csv       "`%1$s` <- data.table::fread('%2$s')\n"
               dired-view-data-view))
  "Cons of data format (file extension) and code to read and display.

The code for reading will be send by `ess-send-string'.
The code is a format string with to OBJECTS: filename as dataname,
and filename with full path.

If the code for display is a function, it will be called directly.
If it is a string (i.e., ``DT::datatable(`%1$s`)\n''), it will be sent
by `ess-send-string'."
  :type '(alist :key-type (symbol :tag "ext")
                :value-type
                (group (string :tag "format string for read data")
                       (choice (string :tag "format string for display")
                               (function :tag "Function to display"))))
  :group 'dired-view-data)


;; this is from ob-comint, renamed hear to avoid unnecessary load heavy org package
(defun dired-view-data-R-buffer-livep (buffer)
  "Check if BUFFER is a comint buffer with a live process."
  (let ((buffer (when buffer (get-buffer buffer))))
    (and buffer (buffer-live-p buffer) (get-buffer-process buffer) buffer)))

(defvar ess-ask-for-ess-directory) ; dynamically scoped
;; this is from ob-R, renamed hear to avoid unnecessary load heavy org package
(defun dired-view-data-R-initiate-session (session params)
  "If there is not a current R process then create one."
  (unless (string= session "none")
    (let ((session (or session "*R*"))
	  (ess-ask-for-ess-directory
	   (and (boundp 'ess-ask-for-ess-directory)
		ess-ask-for-ess-directory
		(not (cdr (assq :dir params))))))
      (if (dired-view-data-R-buffer-livep session)
	  session
	(save-window-excursion
	  (when (get-buffer session)
	    ;; Session buffer exists, but with dead process
	    (set-buffer session))
	  (require 'ess) (R)
	  (let ((R-proc (get-process (or ess-local-process-name
					 ess-current-process-name))))
	    (while (process-get R-proc 'callbacks)
	      (ess-wait-for-process R-proc)))
	  (rename-buffer
	   (if (bufferp session)
	       (buffer-name session)
	     (if (stringp session)
		 session
	       (buffer-name))))
	  (current-buffer))))))


(defun dired-view-data-view (dt)
  "Function for displaying data.
Argument DT dataset."
  (if dired-view-data-use-DT-p
      (let ((ess-view-data-current-backend "dplyr+DT"))
        (pop-to-buffer (ess-view-data-print-ex dt)))
      (pop-to-buffer (ess-view-data-print-ex dt))))

(defun dired-view-data--do (file-name)
  "Read data from dired.
Argument FILE-NAME file-name to the dataset."
  (save-excursion
    (let* ((default-directory (or dired-view-data-default-directory default-directory))
           (ess-history-file dired-view-data-history-file)
           (dt-name (file-name-base file-name))
           (dt-type (intern (file-name-extension file-name)))
	       (dt-dir (file-name-directory file-name))
           dtdo
           readdt
           displaydt
           session)
      (when (assq dt-type dired-view-data-data-name-format)
        (setq session (dired-view-data-R-initiate-session
		               dired-view-data-buffer-name-format
                       `((:dir ,dt-dir))))
        (setq dtdo (cdr (assq dt-type dired-view-data-data-name-format)))
        (setq readdt (format (concat (car dtdo) "\n")
                             ;; "`%s` <- haven::read_sas('%s')\n"
                             dt-name file-name))
        (setq displaydt (nth 1 dtdo))
        (with-current-buffer (get-buffer session)
          (ess-send-string (get-process (or ess-local-process-name
					                        ess-current-process-name))
                           readdt 't)
          (ess-switch-to-ESS t))
        (with-current-buffer (get-buffer session)
          (cond ((stringp displaydt)
                 (ess-send-string (get-process (or ess-local-process-name
					                               ess-current-process-name))
                                  (format displaydt dt-name) 't))
                ((functionp displaydt)
                 ;; to wait for the process ready
                 (sleep-for 1)
                 (funcall displaydt dt-name))))))))


;;;###autoload
(defun dired-view-data ()
  "View data from dired."
  (interactive)
  (let* ((file-name (dired-get-file-for-visit)))
    (if (and (file-exists-p file-name)
             (not (file-directory-p file-name))
             (not (file-remote-p file-name)))
        (dired-view-data--do file-name))))


(defvar dired-view-data-mode-hook nil
  "Hook run when `dired-view-data-mode' is turned on.")

(defun dired-view-data-guess-shell-alist ()
  "Add alist to `dired-guess-shell-alist-user'."
  (interactive)
  (when (derived-mode-p 'dired-mode)
    (add-to-list (make-local-variable 'dired-guess-shell-alist-user)
                 (list "\\.\\(sas7bdat\\|xpt\\|rds\\|csv\\|rda\\|rdata\\)$"
                       '(progn
                          (if (y-or-n-p-with-timeout "Read to R? " 4 nil)
                              (progn
                                (dired-view-data--do (dired-get-filename))
                                (keyboard-quit))
                            (if (eq system-type 'windows-nt)  ;; for w32
                                (w32-shell-execute "open" file-name nil 1))))))))


(defun dired-view-data-assert-dired-buffer ()
  (unless (derived-mode-p 'dired-mode)
    (error "Buffer is not in dired-mode!")))


(defvar dired-view-data-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "V") #'dired-view-data)
    (define-key map "\C-c&\C-v" #'dired-view-data)
    map)
  "The keymap used when `dired-view-data-mode' is active.")

;;;###autoload
(define-minor-mode dired-view-data-mode
  "Enable additional font locking in `dired-mode'."
  :global nil
  :lighter " DVD"
  :keymap dired-view-data-mode-map
  :group 'dired-view-data
  ;; FIXME: enable it only in dired-mode
  (dired-view-data-assert-dired-buffer)
  (when dired-view-data-mode
    (if dired-view-data-guess-shell-alist-p
        (dired-view-data-guess-shell-alist))
    ;; It is annoying
    ;; (message "View data from dired via ESS-r enabled.")
    ))

;;;###autoload
(defun dired-view-data-mode-on ()
  "Turn on `dired-view-data-mode'."
  (interactive)
  (when (derived-mode-p 'dired-mode)
    (dired-view-data-mode)))

;;;###autoload
(define-globalized-minor-mode dired-view-data-global-mode dired-view-data-mode
  dired-view-data-mode-on)

(eval-when-compile (require 'wdired))
(defvar-local dired-view-data--wdired-change nil
  "Change to wdired-mode and back")

(with-eval-after-load 'wdired
  ;; wdired-change-to-wdired-mode
  (add-hook 'wdired-mode-hook
            #'(lambda () (when dired-view-data-mode
                           (dired-view-data-mode -1)
                           (setq dired-view-data--wdired-change t))))

  ;; wdired-change-to-dired-mode
  (advice-add 'wdired-change-to-dired-mode :after
              #'(lambda () (when dired-view-data--wdired-change
                             (dired-view-data-mode 1)))))

(provide 'dired-view-data)
;;; dired-view-data.el ends here
