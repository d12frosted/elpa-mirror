;;; register-quicknav.el --- Quickly jump to next/previous register -*- lexical-binding: t; -*-

;; Copyright (C) 2020  tastytea

;; Author: tastytea <tastytea@tastytea.de>
;; Version: 0.4.3
;; Package-Version: 20200524.2006
;; Package-Commit: c15ea92b0946c28b3f14986d42b15b0b534aa6a2
;; Package-Requires: ((emacs "25.3"))
;; Keywords: convenience
;; URL: https://schlomp.space/tastytea/register-quicknav

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

;; This package is built on top of `register.el' and allows you to quickly jump
;; to the next/previous position register.  If you reach the end, the search
;; wraps around and continues with the first (or last) register.  It can be used
;; across all files or individually for each buffer.

;; Features:
;;
;; * Cycle through all position registers in both directions.
;; * Clear current register.
;; * Store point in unused register (range configurable).
;; * Clear all registers in the unused registers range.

;; Installation:
;;
;; To use `register-quicknav.el', get it from
;; [MELPA](https://melpa.org/#/register-quicknav) or put it in your load-path
;; and add the following to your init.el:
;;
;; (require 'register-quicknav)
;; (global-set-key (kbd "<C-f5>") #'register-quicknav-prev-register)
;; (global-set-key (kbd "<C-f6>") #'register-quicknav-next-register)
;; (global-set-key (kbd "<C-f7>") #'register-quicknav-point-to-unused-register)
;; (global-set-key (kbd "<C-S-<f7>") #'register-quicknav-clear-current-register)
;;
;; Or, with use-package:
;;
;; (use-package register-quicknav
;;   :bind (("C-<f5>"   . register-quicknav-prev-register)
;;          ("C-<f6>"   . register-quicknav-next-register)
;;          ("C-<f7>"   . register-quicknav-point-to-unused-register)
;;          ("C-S-<f7>" . register-quicknav-clear-current-register)))

;; Variables:
;;
;; * `register-quicknav-buffer-only': Cycle only through position registers in
;;   current buffer.  Can be safely set as file- and/or dir-local variable.
;; * `register-quicknav-unused-registers-begin': Beginning of the range that is
;;   used to search for unused registers.  Defaults to `?A'.
;; * `register-quicknav-unused-registers-end': End of the range that is used to
;;   search for unused registers.  Defaults to `?Z'.

;; Differences to similar packages:
;;
;; [iregister](https://github.com/atykhonov/iregister.el):
;;
;; * Opens a minibuffer on each jump (thereby requiring an extra keystroke).
;; * Doesn't work with file-query registers
;; * Can't be restricted to the current buffer.
;; * Doesn't look like it's still maintained.
;;
;; [register-channel](https://github.com/YangZhao11/register-channel):
;;
;; * Is limited to 5 position registers by default, needs an extra keybinding
;;   for each additional register.
;; * Can't be restricted to the current buffer.
;; * Has no ability to jump to the next/previous register.

;;; Code:

(require 'cl-lib)

(defgroup register-quicknav nil
  "Variables for register-quicknav."
  :group 'editing)

;;;###autoload
(defcustom register-quicknav-buffer-only nil
  "Cycle only through position registers in current buffer."
  :type 'boolean
  :group 'register-quicknav
  :safe #'booleanp)

(defcustom register-quicknav-unused-registers-begin ?A
  "Begin looking for unused register at this register."
  :type 'character
  :group 'register-quicknav)

(defcustom register-quicknav-unused-registers-end ?Z
  "End looking for unused register at this register."
  :type 'character
  :group 'register-quicknav)

(defvar register-quicknav--last-register-v nil
  "The last jumped-to position register.")

(defun register-quicknav--last-register (&optional val)
  "Return `register-quicknav--last-register-v' or set it if VAL is non-nil.
Use the local value if `register-quicknav-buffer-only' is set and
the global value otherwise."
  (if val
      (if register-quicknav-buffer-only
          (setq register-quicknav--last-register-v val)
        (setq-default register-quicknav--last-register-v val))
    (if register-quicknav-buffer-only
        register-quicknav--last-register-v
      (default-value 'register-quicknav--last-register-v))))

(defun register-quicknav--file-name (register)
  "Return file-name of REGISTER.
Works on markers and file-queries."
  (if (markerp (cdr register))
      (buffer-file-name (marker-buffer (cdr register)))
    (nth 2 register)))

(defun register-quicknav--is-current-buffer? (register)
  "Return t if REGISTER is in current buffer.
Works on markers and file-queries."
  (if (markerp (cdr register))
      (eq (current-buffer) (marker-buffer (cdr register)))
    (string= (buffer-file-name (current-buffer))
             (register-quicknav--file-name register))))

(defun register-quicknav--position (register)
  "Return position of REGISTER.
Works on markers and file-queries."
  (if (markerp (cdr register))
      (marker-position (cdr register))
    (nth 3 register)))

(defun register-quicknav--registers ()
  "Return all position registers, sorted by file name and position.
If `register-quicknav-buffer-only' is t, return only registers in
current buffer."
  (cl-flet ((sort-registers
             (lambda (a b)
               "Return t if position of A is < B.
Works on markers and file-queries."
               (and (string= (register-quicknav--file-name a)
                             (register-quicknav--file-name b))
                    (< (register-quicknav--position a)
                       (register-quicknav--position b))))))
    (let ((result))
      (dolist (register register-alist)
        (if (or (markerp (cdr register))
                (ignore-errors (eq (nth 1 register) 'file-query)))
            (if register-quicknav-buffer-only
                (when (register-quicknav--is-current-buffer? register)
                  (push register result))
              (push register result))))
      (sort result #'sort-registers))))

(defun register-quicknav--jump-to-register (next)
  "Jump to next position register if NEXT is t, to previous otherwise."
  (let* ((register-list (register-quicknav--registers))
         (index (cl-position (register-quicknav--last-register) register-list))
         (stop-searching))
    (when index
      (if next
          (cl-incf index)
        (cl-decf index)))
    ;; Try to find the position register closest to point.
    (dolist (register register-list)
      (when (register-quicknav--is-current-buffer? register)
        (let ((register-pos (register-quicknav--position register)))
          (if next
              (when (and (not stop-searching)
                         (> register-pos (point)))
                (setq index (cl-position register register-list)
                      stop-searching t))
            (when (< register-pos (point))
              (setq index (cl-position register register-list)))))))
    (if index
        (progn          ; If index is invalid, set it to first or last register.
          (when (or (>= index (length register-list))
                    (< index 0))
            (if next
                (setq index 0)
              (setq index (- (length register-list) 1))))
          (register-to-point (car (nth index register-list)))
          (register-quicknav--last-register (nth index register-list)))
      ;; No suitable register found, jump to first register.
      (register-to-point (car (car register-list)))
      (register-quicknav--last-register (car register-list)))))

;;;###autoload
(defun register-quicknav-next-register ()
  "Jump to next position register."
  (interactive)
  (register-quicknav--jump-to-register t))

;;;###autoload
(defun register-quicknav-prev-register ()
  "Jump to previous position register."
  (interactive)
  (register-quicknav--jump-to-register nil))

;;;###autoload
(defun register-quicknav-clear-current-register ()
  "Clear last jumped-to position register from `register-alist'.
Deletes the value of `register-quicknav--last-register' from `register-alist'."
  (interactive)
  (setq register-alist
        (delq (register-quicknav--last-register) register-alist))
  (message "Cleared register %c." (car (register-quicknav--last-register))))

;;;###autoload
(defun register-quicknav-point-to-unused-register ()
  "Store current location of point in next unused register.
Searches the range between
`register-quicknav-unused-registers-begin' and
`register-quicknav-unused-registers-end'."
  (interactive)
  (let* ((begin register-quicknav-unused-registers-begin)
         (end register-quicknav-unused-registers-end)
         (char begin))
    (while (and (get-register char)
                (not (> char end)))
      (cl-incf char))
    (if (<= char end)
        (progn
          (point-to-register char)
          (register-quicknav--last-register (assoc char register-alist))
          (message "Position stored in register %c." char))
      (message "No unused register in the range %c - %c found." begin end))))

;;;###autoload
(defun register-quicknav-clear-unused-registers-range ()
  "Clear all registers in the range used by `register-quicknav-point-to-unused-register'."
  (interactive)
  (let ((begin register-quicknav-unused-registers-begin)
        (end register-quicknav-unused-registers-end))
    (dolist (register register-alist)
      (when (and (>= (car register) begin)
                 (<= (car register) end))
        (setq register-alist
              (delq register register-alist))))
    (message "Cleared unused registers in the range %c - %c." begin end)))

(provide 'register-quicknav)
;;; register-quicknav.el ends here
