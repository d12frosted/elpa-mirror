;;; gnu-indent.el --- Indent your code with GNU Indent -*- lexical-binding:t -*-

;; Copyright (C) 2022 Akib Azmain Turja.

;; Author: Akib Azmain Turja <akib@disroot.org>
;; Version: 1.0
;; Package-Version: 20221127.2112
;; Package-Commit: f31dbe60478b6270bb57b6b05998df8eec56f801
;; Package-Requires: ((emacs "25.1"))
;; Keywords: tools, c
;; URL: https://codeberg.org/akib/emacs-gnu-indent

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Keeping code correctly indented can be tedious.  And when the project is
;; large, maintaining a consistent style everywhere by hand can become
;; almost impossible.  `gnu-indent' solves this problem by doing the job
;; itself.  Enable `gnu-indent-mode' and continue with the your editing;
;; your file will be reindented by GNU Indent just before saving it,
;; maintaining the position of point.  Customize or set
;; `gnu-indent-options' as file local variable to change indentation style
;; according to your taste.

;; GNU Indent supports C, C++ is also partially supported.

;;; Code:

(defgroup gnu-indent nil
  "Indent your code with GNU Indent."
  :group 'tools
  :link '(url-link "https://codeberg.org/akib/emacs-gnu-indent"))

(defcustom gnu-indent-program "indent"
  "Name of GNU Indent executable."
  :type 'string
  :group 'gnu-indent)

;; Autoload so that users can set it as file local variable without
;; warning.
;;;###autoload
(defcustom gnu-indent-options nil
  "Arguments to pass to GNU Indent."
  :type '(repeat string)
  :safe (lambda (val)
          (let ((valid t))
            (while (and valid val)
              (unless (stringp (car val))
                (setq valid nil))
              (setq val (cdr val)))
            valid))
  :group 'gnu-indent)

;;;###autoload
(defun gnu-indent-region (beg end)
  "Indent current region with GNU Indent.

When called non-interactively, indent text between BEG and END."
  (interactive (if (use-region-p)
                   (list (region-beginning) (region-end) t)
                 (list (point) (point) t)))
  (unless (eq beg end)
    (when (called-interactively-p 'interactive)
      (message "Indenting..."))
    (let ((buffer (get-buffer-create " *gnu-indent*"))
          (temp-file (make-temp-file "gnu-indent-")))
      (with-current-buffer buffer
        (erase-buffer))
      (unwind-protect
          (let ((process (make-process :name "gnu-indent"
                                       :buffer buffer
                                       :command `(,gnu-indent-program
                                                  ,@gnu-indent-options
                                                  "-o" ,temp-file))))
            (send-region process beg end)
            (process-send-eof process)
            (redisplay)
            (while (process-live-p process)
              (sleep-for 0.01))
            (unless (eq (process-exit-status process) 0)
              (pop-to-buffer (process-buffer process))
              (error "GNU Indent exited with non-zero status"))
            (save-restriction
              (let ((inhibit-read-only t))
                (narrow-to-region beg end)
                (insert-file-contents temp-file nil nil nil t))))
        (delete-file temp-file)))
    (when (called-interactively-p 'interactive)
      (message "Indenting...done"))))

;;;###autoload
(defun gnu-indent-defun-or-fill (arg)
  "Indent current function with GNU Indent.
If point is in a comment, call `fill-paragraph' instead.  A
prefix argument ARG is passed to `fill-paragraph'."
  (interactive "P")
  (if (nth 8 (syntax-ppss))           ; If in a comment.
      (fill-paragraph arg)
    (let ((bounds (bounds-of-thing-at-point 'defun)))
      (if (consp bounds)
          (gnu-indent-region (car bounds) (cdr bounds))
        (user-error "No defun at point")))))


;;;###autoload
(defun gnu-indent-buffer ()
  "Indent current buffer with GNU Indent."
  (interactive)
  (gnu-indent-region (point-min) (point-max)))

;;;###autoload
(define-minor-mode gnu-indent-mode
  "Indent buffer automatically with GNU Indent."
  :lighter " GNU-Indent"
  (if gnu-indent-mode
      (add-hook 'before-save-hook #'gnu-indent-buffer nil t)
    (remove-hook 'before-save-hook #'gnu-indent-buffer t)))

(provide 'gnu-indent)
;;; gnu-indent.el ends here
