;;; ac-octave.el --- An auto-complete source for Octave

;; Copyright (c) 2012 - 2017 coldnew <coldnew.tw@gmail.com>
;;
;; Author: coldnew <coldnew.tw@gmail.com>
;; Keywords: Octave, auto-complete, completion
;; Package-Version: 20180406.334
;; Package-Commit: fe0f931f2024f43de3c4fff4b1ace672413adeae
;; Package-Requires: ((auto-complete "1.4.0"))
;; URL: https://github.com/coldnew/ac-octave
;; Version: 0.7

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;;; Installation:

;; If you have `melpa' and `emacs24' installed, simply type:
;;
;;  M-x package-install ac-octave
;;
;; Add following lines to your init file:
;;
;; ```elisp
;; (require 'ac-octave)
;; (add-hook 'octave-mode-hook
;;           '(lambda () (ac-octave-setup)))
;; ```

;;; Note:

;; If you can't use ac-octave in octave-mode,
;; check whether `auto-complete-mode' is running or not.

;;; Code:

(eval-when-compile (require 'cl))
(require 'auto-complete)

;; octave-inf.el merge to octave.el since emacs version 24.3.1
;; see issue #6: Error when require octave-inf
(if (or (and (= emacs-major-version 24) (> emacs-minor-version 3))
        (>= emacs-major-version 25))
    (require 'octave)
    ;; for emacs 24.3 or below
    (require 'octave-inf))

;;;;##########################################################################
;;;; User Options, Variables
;;;;##########################################################################


;;;;;;;; faces
(defface ac-octave-candidate-face
  '((t (:inherit ac-candidate-face)))
  "face for octave candidate"
  :group 'auto-complete)

(defface ac-octave-selection-face
  '((t (:inherit ac-selection-face)))
  "face for the octave selected candidate."
  :group 'auto-complete)


;;;;;;;; local variables

(defvar ac-octave-complete-list nil)

;;;;;;;; functions

(defun ac-octave-init ()
  "Start inferior-octave in background before use ac-octave."
  (run-octave t)
  ;; Update current directory of inferior octave whenever completion starts.
  ;; This allows local functions to be completed when user switches
  ;; between octave buffers that are located in different directories.
  (when (file-readable-p default-directory)
    (inferior-octave-send-list-and-digest
     (list (concat "cd " default-directory ";\n")))))

(defun ac-octave-do-complete ()
  (interactive)
  (let* ((end (point))
         (command (save-excursion
                    (skip-syntax-backward "w_")
                    (buffer-substring-no-properties (point) end))))

    (inferior-octave-send-list-and-digest
     (list (concat "completion_matches (\"" command "\");\n")))

    (setq ac-octave-complete-list
          (sort inferior-octave-output-list 'string-lessp))

    ;; remove dulpicates lists
    (delete-dups ac-octave-complete-list)))

(defun ac-octave-candidate ()
  (let (table)
    (ac-octave-do-complete)
    (dolist (s ac-octave-complete-list)
      (push s table))
    table))

(defun ac-octave-documentation (symbol)
  (with-local-quit
    (ignore-errors
      (inferior-octave-send-list-and-digest
       (list (concat "help " symbol ";\n")))
      (mapconcat #'identity
                 inferior-octave-output-list
                 "\n"))))

;;;###autoload
(autoload 'ac-define-source "auto-complete" "Source definition macro. It defines a complete command also."  nil nil)
(declare-function ac-define-source "auto-complete")

;;;###autoload
(ac-define-source octave
  '((candidates . ac-octave-candidate)
    (document . ac-octave-documentation)
    (candidate-face . ac-octave-candidate-face)
    (selection-face . ac-octave-selection-face)
    (init . ac-octave-init)
    (requires . 0)
    (cache)
    (symbol . "f")))

;;;###autoload
(defun ac-octave-setup ()
  "Add the Octave completion source to the front of `ac-sources'."
  (add-to-list 'ac-sources 'ac-source-octave))

(provide 'ac-octave)
;;; ac-octave.el ends here
