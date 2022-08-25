;;; uncrustify-mode.el --- Minor mode to automatically uncrustify.

;; Copyright (C) 2012  tabi
;; Author: Tabito Ohtani <koko1000ban@gmail.com>
;; Version: 0.01
;; Package-Version: 20130707.1359
;; Package-Commit: 2c00d5cf2d1868a5955347438746f4dd82b3b9fc
;; Keywords: uncrustify

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

;;; Installation:

;; drop requirements and this file into a directory in your `load-path',
;; and put these lines into your .emacs file.

;; (require 'uncrusfify-mode)
;; (add-hook 'c-mode-common-hook
;;    '(lambda ()
;;        (uncrustify-mode 1)))

;;; ChangeLog:
;; * 0.0.1:
;;   Initial version.


;; case
(eval-when-compile
  (require 'cl))

;;; Variables:

(defcustom uncrustify-config-path
  "~/.uncrustify.cfg"
  "uncrustify config file path"
  :group 'uncrustify
  :type 'file)
(make-variable-buffer-local 'uncrustify-config-path)

(defcustom uncrustify-bin
  "uncrustify -q"
  "The command to run uncrustify."
  :group 'uncrustify)

;;; Functions:

(defun uncrustify-get-lang-from-mode (&optional mode)
  "uncrustify lang option"
  (let ((m (or mode major-mode)))
    (case m
      ('c-mode "C")
      ('c++-mode "CPP")
      ('d-mode "D")
      ('java-mode "JAVA")
      ('objc-mode "OC")
      (t
       nil))))

(defun uncrustify-point->line (point)
  "Get the line number that POINT is on."
  ;; I'm not bothering to use save-excursion because I think I'm
  ;; calling this function from inside other things that are likely to
  ;; use that and all I really need to do is restore my current
  ;; point. So that's what I'm doing manually.
  (let ((line 1)
        (original-point (point)))
    (goto-char (point-min))
    (while (< (point) point)
      (incf line)
      (forward-line))
    (goto-char original-point)
    line))

(defun uncrustify-invoke-command (lang start-in end-in)
  "Run uncrustify on the current region or buffer."
  (if lang
      (let ((start (or start-in (point-min)))
            (end   (or end-in   (point-max)))
            (original-line (uncrustify-point->line (point)))
            (cmd (concat uncrustify-bin " -c " uncrustify-config-path " -l " lang))
            (out-buf (get-buffer-create "*uncrustify-out*"))
            (error-buf (get-buffer-create "*uncrustify-errors*")))

        (with-current-buffer error-buf (erase-buffer))
        (with-current-buffer out-buf (erase-buffer))

        ;; Inexplicably, save-excursion doesn't work to restore the
        ;; point. I'm using it to restore the mark and point and manually
        ;; navigating to the proper new-line.
        (let ((result
               (save-excursion
                 (let ((ret (shell-command-on-region start end cmd t t error-buf nil)))
                   (if (and
                        (numberp ret)
                        (zerop ret))
                       ;; Success! Clean up.
                       (progn
                         (message "Success! uncrustify modify buffer.")
                         (kill-buffer error-buf)
                         t)
                     ;; Oops! Show our error and give back the text that
                     ;; shell-command-on-region stole.
                     (progn (undo)
                            (with-current-buffer error-buf
                              (message "uncrustify error: <%s> <%s>" ret (buffer-string)))
                            nil))))))

          ;; This goto-line is outside the save-excursion becuase it'd get
          ;; removed otherwise.  I hate this bug. It makes things so ugly.
          (goto-line original-line)
          (not result)))
    (message "uncrustify not support this mode : %s" major-mode)))

(defun uncrustify ()
  (interactive)
  (save-restriction
    (widen)
    (uncrustify-invoke-command (uncrustify-get-lang-from-mode) (region-beginning) (region-end))))

(defun uncrustify-buffer ()
  (interactive)
  (save-restriction
    (widen)
    (uncrustify-invoke-command (uncrustify-get-lang-from-mode) (point-min) (point-max))))

;;; mode

(defun uncrustify-write-hook ()
  "Uncrustifys a buffer during `write-file-hooks' for `uncrustify-mode'.
   if uncrustify returns not nil then the buffer isn't saved."
  (if uncrustify-mode
      (save-restriction
        (widen)
        (uncrustify-invoke-command (uncrustify-get-lang-from-mode) (point-min) (point-max)))))

;;;###autoload
(define-minor-mode uncrustify-mode
  "Automatically `uncrustify' when saving."
  :lighter " Uncrustify"
  (if (not (uncrustify-get-lang-from-mode))
      (message "uncrustify not support this mode : %s" major-mode)
  (if (version<= "24" emacs-version)
    (if uncrustify-mode
        (add-hook 'write-file-hooks 'uncrustify-write-hook nil t)
      (remove-hook 'uncrustify-write-hook t))
    (make-local-hook 'write-file-hooks)
    (funcall (if uncrustify-mode #'add-hook #'remove-hook)
             'write-file-hooks 'uncrustify-write-hook))))

(provide 'uncrustify-mode)

;;; uncrustify-mode.el ends here
