;;; gnu-indent.el --- Indent your code with GNU Indent -*- lexical-binding:t -*-

;; Copyright (C) 2022 Akib Azmain Turja.

;; Author: Akib Azmain Turja <akib@disroot.org>
;; Version: 1.0
;; Package-Version: 20220326.1423
;; Package-Commit: 81acd6470e13ae699e2ee184d7cdc80b225f1089
;; Package-Requires: ((emacs "27.2"))
;; Keywords: tools, c
;; URL: https://codeberg.org/akib/emacs-why-this

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
;; your file will be reindented by GNU Indent just before saving it
;; maintaining the position of point.  Customize or set
;; `gnu-indent-options' as file local variable to change indentation style
;; according to your taste.

;; GNU Indent supports C, C++ is also partially supported.

;;; Code:

(defgroup gnu-indent nil
  "Indent your code with GNU Indent."
  :group 'tools)

(defcustom gnu-indent-program "indent"
  "Name of GNU Indent executable."
  :type 'string
  :group 'gnu-indent)

;; Autoload so that users can set it as file local variable without
;; warning.
;;;###autoload
(progn
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
    :group 'gnu-indent))

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
              (display-buffer (process-buffer process))
              (error "GNU Indent exited with non-zero status"))
            (save-restriction
              (let ((inhibit-read-only t))
                (narrow-to-region beg end)
                (insert-file-contents temp-file nil nil nil
                                      t))))
        (delete-file temp-file)))
    (when (called-interactively-p 'interactive)
      (message "Indenting...done"))))

;;;###autoload
(defun gnu-indent-buffer ()
  "Indent current buffer with GNU Indent."
  (interactive)
  (gnu-indent-region (point-min) (point-max)))

;;;###autoload
(define-minor-mode gnu-indent-mode
  "Indent buffer automatically with GNU Indent."
  nil nil nil
  (if gnu-indent-mode
      (add-hook 'before-save-hook #'gnu-indent-buffer nil t)
    (remove-hook 'before-save-hook #'gnu-indent-buffer t)))

(provide 'gnu-indent)
;;; gnu-indent.el ends here
