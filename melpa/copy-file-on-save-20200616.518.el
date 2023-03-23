;;; copy-file-on-save.el --- Copy file on save, automatic deployment it. -*- lexical-binding: t -*-

;; Copyright (C) 2020  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 27 Jul 2017
;; Version: 0.0.5
;; Package-Version: 20200616.518
;; Package-Commit: 811c8fe638c5616b6471525421e61a4470be3b52
;; Keywords: files comm deploy
;; URL: https://github.com/emacs-php/emacs-auto-deployment
;; Package-Requires: ((emacs "24.3") (cl-lib "0.5") (f "0.17") (s "1.7.0"))

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

;; `copy-file-on-save-mode' is a minor mode to copy the file to another path on
;; `after-save-hook'.  This not only saves the backup in the project specific
;; path, it also you can realize the deployment to the remote server over TRAMP.
;;
;; ## Setup
;;
;; Put the following into your .emacs file (~/.emacs.d/init.el)
;;
;;    (global-copy-file-on-save-mode)
;;
;;
;; ## Config
;;
;; Put the following into your .dir-locals.el in project root directory.
;;
;;     ((nil . ((copy-file-on-save-dest-dir . "/scp:dest-server:/home/your/path/to/proj")
;;              (copy-file-on-save-ignore-patterns . ("/cache")))))
;;
;; See TRAMP User Manual to learn file name syntax.  Do `M-x info' and search TRAMP.
;; https://www.gnu.org/software/emacs/manual/html_node/tramp/Configuration.html#Configuration


;;; Code:
(require 'cl-lib)
(require 'f)
(require 's)
(require 'projectile nil t)

(defgroup copy-file-on-save nil
  "Copy file on save, automatic deployment it."
  :group 'files)

(defcustom copy-file-on-save-remove-mode-line-unless-availabled t
  "Don't show minor mode lighter on modeline if not available `copy-file-on-save'."
  :type 'boolean)

(defcustom copy-file-on-save-default-lighter " CopyFS"
  "Minor mode lighter to use in the mode-line."
  :type 'string)

(defconst copy-file-on-save-default-marker-file ".dir-locals.el")

(defvar copy-file-on-save-lighter copy-file-on-save-default-lighter)
(make-variable-buffer-local 'copy-file-on-save-lighter)

;; Directory Local variables
;;;###autoload
(progn
  (defvar-local copy-file-on-save-dest-dir nil
    "Path to deployment directory or convert (mapping) function.")
  (put 'copy-file-on-save-dest-dir 'safe-local-variable #'stringp))

;;;###autoload
(progn
  (defvar-local copy-file-on-save-ignore-patterns '("/\\.dir-locals\\.el\\'" "/\\.git/")
    "Ignore deploy when buffer-filename matched by these patterns.")
  (put 'copy-file-on-save-ignore-patterns 'safe-local-variable
       (lambda (obj)
         (and (listp obj)
              (cl-loop for o in obj always (stringp o))))))
;;;###autoload
(progn
  (defvar-local copy-file-on-save-project-root-marker nil
    "Marker file for project root detection.")
  (put 'copy-file-on-save-project-root-marker 'safe-local-variable
       (lambda (obj)
         (or (null obj)
             (stringp obj)
             (memq obj '(projectile))))))

;; Variables
(defvar copy-file-on-save-base-dir nil
  "Path to base directory for deployment.")

(defun copy-file-on-save--not-matches-ignore-patterns (filename)
  "Return t if FILENAME matched by `copy-file-on-save-ignore-patterns'."
  (cl-loop for pattern in copy-file-on-save-ignore-patterns
           never (string-match-p pattern filename)))

(defun copy-file-on-save--available ()
  "Return t if setup `copy-file-on-save-dest-dir' and the file is not ignoted file."
  (and buffer-file-name copy-file-on-save-dest-dir
       (copy-file-on-save--not-matches-ignore-patterns buffer-file-name)))

(defun copy-file-on-save--update-lighter (is-availabled)
  "Update display mode-line if `IS-AVAILABLED' is non-NIL."
  (setq copy-file-on-save-lighter (if (or is-availabled (not copy-file-on-save-remove-mode-line-unless-availabled))
                     copy-file-on-save-default-lighter
                   nil)))

(defun copy-file-on-save--hook-after-save ()
  "Run copy-file-on-save hook for after-save."
  (if (copy-file-on-save--available)
      (progn
        (copy-file-on-save--update-lighter t)
        (copy-file-on-save--copy-file))
    (prog1 nil
      (copy-file-on-save--update-lighter nil))))

(defun copy-file-on-save--detect-project-root ()
  "Return path to project root directory."
  (let ((marker (or copy-file-on-save-project-root-marker
                    (if (fboundp 'projectile-project-root)
                        'projectile
                      copy-file-on-save-default-marker-file))))
    (if (eq marker 'projectile)
        (projectile-project-root)
      (file-truename (locate-dominating-file buffer-file-name marker)))))

(defun copy-file-on-save--base-dir ()
  "Return path to project directory."
  (cond
   ((null copy-file-on-save-base-dir) (copy-file-on-save--detect-project-root))
   ((stringp copy-file-on-save-base-dir) copy-file-on-save-base-dir)
   ((fboundp copy-file-on-save-base-dir) (funcall copy-file-on-save-base-dir))
   (t (error "Variable copy-file-on-save-base-dir `%s' is invalid value" copy-file-on-save-base-dir))))

(defun copy-file-on-save--copy-file ()
  "Copy a file using `copy-file'."
  (let* ((from-path buffer-file-name)
	 (to-path   (copy-file-on-save--replace-path buffer-file-name))
	 (to-dir (file-name-directory to-path)))
    (unless (file-exists-p to-dir)
      (make-directory to-dir t))
    (copy-file from-path to-path t)))

(defun copy-file-on-save--replace-path (src-file-path)
  "Return replace dest file path by `SRC-FILE-PATH'."
  (f-join copy-file-on-save-dest-dir (s-replace (copy-file-on-save--base-dir) "" src-file-path)))

;;;###autoload
(defun turn-on-copy-file-on-save ()
  "Turn on `copy-file-on-save-mode'."
  (copy-file-on-save--update-lighter (copy-file-on-save--available))
  (copy-file-on-save-mode 1))

;;;###autoload
(define-minor-mode copy-file-on-save-mode
  "Minor mode for automatic deployment/syncronize file when saved."
  :group 'copy-file-on-save
  :lighter copy-file-on-save-lighter
  (if copy-file-on-save-mode
      (add-hook 'after-save-hook 'copy-file-on-save--hook-after-save nil t)
    (remove-hook 'after-save-hook 'copy-file-on-save--hook-after-save t)))

;;;###autoload
(define-globalized-minor-mode global-copy-file-on-save-mode copy-file-on-save-mode
  turn-on-copy-file-on-save
  :group 'copy-file-on-save
  :require 'copy-file-on-save)

(provide 'copy-file-on-save)
;;; copy-file-on-save.el ends here
