;;; yapfify.el --- (automatically) format python buffers using YAPF.

;; Copyright (C) 2016 Joris Engbers

;; Author: Joris Engbers <info@jorisengbers.nl>
;; Homepage: https://github.com/JorisE/yapfify
;; Version: 0.0.9
;; Package-Version: 20200406.830
;; Package-Commit: 3df4e8ce65f55fd69479b3417525ce83a2b00b45
;; Package-Requires: ()

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your
;; option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Yapfify uses yapf to format a Python buffer. It can be called explicitly on a
;; certain buffer, but more conveniently, a minor-mode 'yapf-mode' is provided
;; that turns on automatically running YAPF on a buffer before saving.
;;
;; Installation:
;;
;; Add yapfify.el to your load-path.
;;
;; To automatically format all Python buffers before saving, add the function
;; yapf-mode to python-mode-hook:
;;
;; (add-hook 'python-mode-hook 'yapf-mode)
;;
;;; Code:

(require 'cl-lib)

(defcustom yapfify-executable "yapf"
  "Executable used to start yapf."
  :type 'string
  :group 'yapfify)

(defun yapfify-call-bin (input-buffer output-buffer start-line end-line)
  "Call process yapf on INPUT-BUFFER saving the output to OUTPUT-BUFFER.

Return the exit code.  START-LINE and END-LINE specify region to
format."
  (with-current-buffer input-buffer
    (call-process-region (point-min) (point-max)
                         yapfify-executable nil output-buffer
                         nil "-l" (concat (number-to-string start-line) "-"
                                           (number-to-string end-line)))))

(defun get-buffer-string (buffer)
  "Return the contents of BUFFER."
  (with-current-buffer buffer
    (buffer-string)))

;;;###autoload
(defun yapfify-region (beginning end)
  "Try to yapfify the current region.

If yapf exits with an error, the output will be shown in a help-window."
  (interactive "r")
  (let* ((original-buffer (current-buffer))
         (original-point (point))  ; Because we are replacing text, save-excursion does not always work.
         (buffer-windows (get-buffer-window-list original-buffer nil t))
         (original-window-pos (mapcar 'window-start buffer-windows))
         (start-line (line-number-at-pos beginning))
         (end-line (line-number-at-pos (if (or (= (char-before end) 10)
                                               (= (char-before end) 13))
                                           (- end 1)
                                         end)))
         (tmpbuf (generate-new-buffer "*yapfify*"))
         (exit-code (yapfify-call-bin original-buffer tmpbuf start-line end-line)))
    (deactivate-mark)
    ;; There are three exit-codes defined for YAPF:
    ;; 0: Exit with success (change or no change on yapf >=0.11)
    ;; 1: Exit with error
    ;; 2: Exit with success and change (Backward compatibility)
    ;; anything else would be very unexpected.
    (cond ((or (eq exit-code 0) (eq exit-code 2))
           (with-current-buffer tmpbuf
             (copy-to-buffer original-buffer (point-min) (point-max))))
          ((eq exit-code 1)
           (error "Yapf failed, see %s buffer for details" (buffer-name tmpbuf))))
    ;; Clean up tmpbuf
    (kill-buffer tmpbuf)
    ;; restore window to similar state
    (goto-char original-point)
    (cl-mapcar 'set-window-start buffer-windows original-window-pos))) 

;;;###autoload
(defun yapfify-buffer ()
  "Yapfify whole buffer."
  (interactive)
  (yapfify-region (point-min) (point-max)))

;;;###autoload
(defun yapfify-region-or-buffer ()
  "Yapfify the region if it is active. Otherwise, yapfify the buffer"
  (interactive)
  (if (region-active-p)
      (yapfify-region (region-beginning) (region-end))
    (yapfify-buffer)))

;;;###autoload
(define-minor-mode yapf-mode
  "Automatically run YAPF before saving."
  :lighter " YAPF"
  (if yapf-mode
      (add-hook 'before-save-hook 'yapfify-buffer nil t)
    (remove-hook 'before-save-hook 'yapfify-buffer t)))

(provide 'yapfify)

;;; yapfify.el ends here
