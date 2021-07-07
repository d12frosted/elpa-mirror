;;; company-manually.el --- A company backend that lets you manually build candidates  -*- lexical-binding: t -*-

;; Copyright (C) 2020 Yanghao Xie

;; Author: Yanghao Xie
;; Maintainer: Yanghao Xie <yhaoxie@gmail.com>
;; URL: https://github.com/yanghaoxie/company-manually
;; Package-Version: 20200709.913
;; Package-Commit: 44c7a655e5f2a462835a96d1f0ed2ce434848416
;; Version: 0.1.0
;; Keywords: convenience, company-mode, manually build candidates
;; Package-Requires: ((emacs "24.3") (company "0.9.0") (ivy "0.13.0"))

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

;; Manually build the candidates for company backend.

;;; Code:
(require 'cl-lib)
(require 'company)
(require 'ivy)

(defcustom company-manually-restore t
  "If non-nil, save candidates to `company-manually-file' when close Emacs.
Then the candidates will be restored after Emacs is reopened."
  :group 'company-manually
  :type 'boolean)

(defcustom company-manually-file
  (concat user-emacs-directory ".company-manually.el")
  "Default file for saving/loading `company-manually--candidates'."
  :group 'company-manually
  :type 'file)

(defvar company-manually--candidates nil)

(defun company-manually-add-candidate (candidate)
  "Add CANDIDATE to `company-manually--candidates'."
  (add-to-list 'company-manually--candidates candidate))

(declare-function evil-exit-visual-state "evil-states")

(defun company-manually-add-candidate-at-point ()
  "Add candidate formed from START to END as a candidate to the candidates."
  (interactive)
  (let ((candidate (buffer-substring-no-properties (mark) (point))))
    (company-manually-add-candidate candidate))
  (if (featurep 'evil)
      (evil-exit-visual-state)
    (deactivate-mark)))

(defun company-manually-delete-candidate (candidate)
  "Delete CANDIDATE from `company-manually--candidates'."
  (setq company-manually--candidates
	  (delete candidate company-manually--candidates)))

(defun company-manually-delete-candidate-at-point ()
  "Delete candidate formed from START to END candidate from `company-manually--candidates'."
  (interactive)
  (let ((candidate (buffer-substring-no-properties (mark) (point))))
    (company-manually-delete-candidate candidate)))

(defun company-manually-cleanup-candidates ()
  "Cleanup all candidates."
  (interactive)
  (setq company-manually--candidates nil))

(defun company-manually-grab-symbol ()
  "If point is at the end of a symbol, return it.
Otherwise, if point is not inside a symbol, return an empty string."
  (buffer-substring (point) (save-excursion (skip-chars-backward "\\\\a-zA-Z_")
						 (point))))

(defun company-manually (command &optional arg &rest ignored)
  "Define `company-mode' completion backend."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-manually))
    (prefix (company-manually-grab-symbol))
    (candidates
     (cl-remove-if-not
      (lambda (c) (string-prefix-p arg c))
      company-manually--candidates))))

(defun company-manually-dump (varlist buffer)
  "Insert into BUFFER the setq statement to recreate the variables in VARLIST."
  (cl-loop for var in varlist do
        (print (list 'setq var (list 'quote (symbol-value var)))
               buffer)))

(defun company-manually-dump-vars (varlist filename)
  "Simplistic dumping of variables in VARLIST to a file FILENAME."
  (save-excursion
    (let ((buf (find-file-noselect filename)))
      (set-buffer buf)
      (erase-buffer)
      (company-manually-dump varlist buf)
      (save-buffer)
      (kill-buffer))))

(defun company-manually-dump-candidates ()
  "Save candidates to file."
  (interactive)
  (company-manually-dump-vars '(company-manually--candidates) company-manually-file))

(defun company-manually-restore-candidates ()
  "Restore candidates from file."
  (if (file-exists-p company-manually-file)
      (load company-manually-file)))

(when company-manually-restore
  (add-hook 'kill-emacs-hook #'company-manually-dump-candidates)
  (add-hook 'after-init-hook #'company-manually-restore-candidates))

(defun company-manually-company-posframe-visible-p (buffer-or-name)
  "Return whether company posframe buffer called BUFFER-OR-NAME is visible.."
  (cl-dolist (frame (frame-list))
    (let ((buffer-info (frame-parameter frame 'posframe-buffer)))
      (when (or (equal buffer-or-name (car buffer-info))
                (equal buffer-or-name (cdr buffer-info)))
	(when (frame-visible-p frame)
	  (cl-return t))))))

(declare-function cdlatex-number-of-backslashes-is-odd "cdlatex")
(declare-function cdlatex-ensure-math "cdlatex")
(declare-function texmathp "texmathp")

(defvar cdlatex-make-sub-superscript-roman-if-pressed-twice)
(defvar cdlatex-sub-super-scripts-outside-math-mode)
(defvar company-posframe-buffer)

(defun company-manually-cdlatex-sub-superscript ()
  "Insert ^ or _ if company tooltip or company posframe are visible.
Insert ^{} or _{} unless the number of backslashes before point is odd.
When not in LaTeX math environment, _{} and ^{} will have
dollars.  When pressed twice, make the sub/superscript roman."
  (interactive)
  (if (and cdlatex-make-sub-superscript-roman-if-pressed-twice
           (equal this-command last-command))
      (insert "\\rm ")
    (if (cdlatex-number-of-backslashes-is-odd)
        ;; Quoted
        (insert (event-basic-type last-command-event))
      ;; Check if we are in math mode, if not switch to or only add _ or ^
      (if (and (not (texmathp))
	       (not cdlatex-sub-super-scripts-outside-math-mode))
          (insert (event-basic-type last-command-event))
	(if (or (company-manually-company-posframe-visible-p company-posframe-buffer)
		(company-tooltip-visible-p))
	    (insert (event-basic-type last-command-event))
          (if (not (texmathp)) (cdlatex-ensure-math))
          ;; Insert the normal template.
          (insert (event-basic-type last-command-event))
          (insert "{}")
          (forward-char -1))))))

(when (featurep 'cdlatex)
  (advice-add 'cdlatex-sub-superscript :override #'company-manually-cdlatex-sub-superscript))

(declare-function ivy-read "ivy")
(declare-function ivy-thing-at-point "ivy")

(defun company-manually-delete-candidate-ivy ()
  "Delete candidate from `company-manually--candidates' using ivy."
  (interactive)
  (ivy-read "Delete: "
	    company-manually--candidates
	    :action (lambda (x)
		      (company-manually-delete-candidate x))
	    :preselect (ivy-thing-at-point)
	    :require-match t
	    :caller 'company-manually-delete-candidate-ivy))

(defun company-manually-add-candidate-ivy ()
  "Add candidate to `company-manually--candidates' using ivy."
  (interactive)
  (ivy-read "Add: "
	    company-manually--candidates
	    :action (lambda (x)
		      (company-manually-add-candidate x))
	    :preselect (ivy-thing-at-point)
	    :caller 'company-manually-add-candidate-ivy))

(provide 'company-manually)

;; Local Variables:
;; coding: utf-8-unix
;; End:

;;; company-manually.el ends here
