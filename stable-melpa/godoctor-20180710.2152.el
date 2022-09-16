;;; godoctor.el --- Frontend for godoctor

;; Copyright (C) 2016, 2018 Sangho Na <microamp@protonmail.com>
;;
;; Author: Sangho Na <microamp@protonmail.com>
;; Version: 0.6.0
;; Package-Version: 20180710.2152
;; Package-Commit: 4b45ff3d0572f0e84056e4c3ba91fcc178199859
;; Keywords: go golang refactoring
;; Homepage: https://github.com/microamp/godoctor.el

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Frontend for godoctor

;;; Code:

(defgroup godoctor nil
  "Frontend for godoctor."
  :group 'languages)

(defcustom godoctor-executable "godoctor"
  "Default executable for godoctor."
  :type 'string
  :group 'godoctor)

(defcustom godoctor-scope ""
  "The scope of the analysis.  See `godoctor-set-scope'."
  :type 'string
  :group 'godoctor)

(defvar godoctor-refactoring-rename "rename")
(defvar godoctor-refactoring-extract "extract")
(defvar godoctor-refactoring-toggle "toggle")
(defvar godoctor-refactoring-godoc "godoc")
(defvar godoctor--scope-history nil "History of values supplied to `godoctor-set-scope'.")

(defun godoctor-cmd (args dry-run)
  (let ((cmd (list godoctor-executable nil t nil))
        (with-dry-run (if dry-run args (cons "-w" args)))
        (scope (if (string= "" godoctor-scope) nil (list "-scope" godoctor-scope))))
    (append cmd scope with-dry-run)))

(defun godoctor-rename-cmd (pos new-name &optional dry-run)
  (godoctor-cmd (list "-file" (buffer-file-name) "-pos" pos
                      godoctor-refactoring-rename new-name)
                dry-run))

(defun godoctor-extract-cmd (pos new-name &optional dry-run)
  (godoctor-cmd (list "-file" (buffer-file-name) "-pos" pos
                      godoctor-refactoring-extract new-name)
                dry-run))

(defun godoctor-toggle-cmd (pos &optional dry-run)
  (godoctor-cmd (list "-file" (buffer-file-name) "-pos" pos
                      godoctor-refactoring-toggle)
                dry-run))

(defun godoctor-godoc-cmd (&optional dry-run)
  (godoctor-cmd (list "-file" (buffer-file-name)
                      godoctor-refactoring-godoc)
                dry-run))

(defun godoctor--get-pos-region ()
  (let* ((start (region-beginning))
         (end (region-end))
         (len (- end start)))
    (format "%d,%d" start len)))

(defun godoctor--execute-command (compilation-buffer cmd &optional dry-run)
  (with-current-buffer (get-buffer-create compilation-buffer)
    (setq buffer-read-only nil)
    (erase-buffer)
    (message "Running godoctor...")
    (let* ((win (display-buffer (current-buffer)))
           (proc (apply #'call-process cmd))
           (successful (= proc 0)))
      (compilation-mode)
      (if (and successful (not dry-run))
          ;; If successful *and* not dry run, quit the window
          (progn (quit-restore-window win)
                 ;; TODO: Revert multiple buffers if necessary
                 (revert-buffer t t t))
        ;; Otherwise, keep it displayed with errors or diffs
        (shrink-window-if-larger-than-buffer win)
        (set-window-point win (point-min)))
      (message (if successful "godoctor completed"
                 (format "godoctor exited with %d" proc))))))

(defun godoctor--check-executable ()
  (unless (executable-find godoctor-executable)
    (error (format "%s not installed" godoctor-executable))))

(defun godoctor--error-if-unsaved ()
  (when (buffer-modified-p)
    (error (format "Please save the current buffer before invoking %s" godoctor-executable))))

;;;###autoload
(defun godoctor-rename (&optional dry-run)
  (interactive)
  (godoctor--check-executable)
  (godoctor--error-if-unsaved)
  (let ((symbol (symbol-at-point)))
    (unless symbol
      (error "No symbol at point"))
    (let* ((compilation-buffer "*godoctor rename*")
           (new-name (symbol-name symbol))
           (len (length new-name))
           (pos (format "%d,%d" (1- (car (bounds-of-thing-at-point 'symbol))) len))
           (new-name (read-string "New name: " new-name))
           (cmd (godoctor-rename-cmd pos new-name dry-run)))
      (godoctor--execute-command compilation-buffer cmd dry-run))))

;;;###autoload
(defun godoctor-rename-dry-run ()
  (interactive)
  (godoctor-rename t))

;;;###autoload
(defun godoctor-extract (&optional dry-run)
  (interactive)
  (godoctor--check-executable)
  (godoctor--error-if-unsaved)
  (let* ((compilation-buffer "*godoctor extract*")
         (pos (godoctor--get-pos-region))
         (new-name (read-string "New name: "))
         (cmd (godoctor-extract-cmd pos new-name dry-run)))
    (godoctor--execute-command compilation-buffer cmd dry-run)))

;;;###autoload
(defun godoctor-extract-dry-run ()
  (interactive)
  (godoctor-extract t))

;;;###autoload
(defun godoctor-toggle (&optional dry-run)
  (interactive)
  (godoctor--check-executable)
  (godoctor--error-if-unsaved)
  (let* ((compilation-buffer "*godoctor toggle*")
         (pos (godoctor--get-pos-region))
         (cmd (godoctor-toggle-cmd pos dry-run)))
    (godoctor--execute-command compilation-buffer cmd dry-run)))

;;;###autoload
(defun godoctor-toggle-dry-run ()
  (interactive)
  (godoctor-toggle t))

;;;###autoload
(defun godoctor-godoc (&optional dry-run)
  (interactive)
  (godoctor--check-executable)
  (godoctor--error-if-unsaved)
  (let ((compilation-buffer "*godoctor godoc*")
        (cmd (godoctor-godoc-cmd dry-run)))
    (godoctor--execute-command compilation-buffer cmd dry-run)))

;;;###autoload
(defun godoctor-godoc-dry-run ()
  (interactive)
  (godoctor-godoc t))

;;;###autoload
(defun godoctor-set-scope ()
  ;; The set-scope command adapted from go-guru project.
  "Set the scope for the godoctor, prompting the user to edit the previous scope.

The scope restricts analysis to the specified packages.
Its value is a comma-separated list of patterns of these forms:
	golang.org/x/tools/cmd/guru     # a single package
	golang.org/x/tools/...          # all packages beneath dir
	...                             # the entire workspace.

A pattern preceded by '-' is negative, so the scope
	encoding/...,-encoding/xml
matches all encoding packages except encoding/xml."
  (interactive)
  (let ((scope (read-from-minibuffer "Godoctor scope: "
                                     godoctor-scope
                                     nil
                                     nil
                                     'godoctor--scope-history)))
    (setq godoctor-scope scope)))

(provide 'godoctor)
;;; godoctor.el ends here
