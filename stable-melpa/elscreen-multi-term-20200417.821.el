;;; elscreen-multi-term.el --- Multi term for elscreen

;; Author: wamei <wamei.cho@gmail.com>
;; Keywords: elscreen, multi term
;; Package-Version: 20200417.821
;; Package-Commit: 4ea89bae0444d9d4377515929f76cb3e98140f1f
;; Version: 0.1.3
;; Package-Requires: ((emacs "24.4") (elscreen "1.4.6") (multi-term "1.3"))

;; License:

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

;; This makes elscreen can manage multi term buffer each screen.
;;
;; To use this, add the following line somewhere in your init file:
;; ;; When you use this with elscreen-separate-buffer-list, you need to
;; ;; add this before (require 'elscreen-separate-buffer-list)
;;
;;      (require 'elscreen-multi-term)
;;
;; Function: emt-multi-term
;;   Create multi-term buffer related to screen.
;;   When the multi-term  buffer already exists, switch to the buffer.
;;
;; Function: emt-toggle-multi-term
;;   Toggle between current buffer and the multi-term buffer.
;;
;; Function: emt-pop-multi-term
;;   Pop to the multi-term buffer.

;;; Code:

(eval-when-compile (require 'cl))
(require 'elscreen)
(require 'multi-term)

(defvar emt-term-buffer-name "*screen terminal<%s-%d>*")
(defvar emt-pop-to-buffer-function 'pop-to-buffer)

;;;###autoload
(defun emt-multi-term (&optional number)
  "NUMBERに対応するTERMに切り替える.なければ作成する."
  (interactive)
  (switch-to-buffer (emt-get-or-create-multi-term-buffer number)))

;;;###autoload
(defun emt-toggle-multi-term (&optional number)
  "NUMBERに対応するTERMと現在のBUFFERを切り替える."
  (interactive)
  (let ((buffer (emt-get-or-create-multi-term-buffer number)))
    (cond ((equal buffer (current-buffer))
           (switch-to-prev-buffer))
          (t
           (switch-to-buffer buffer)))))

;;;###autoload
(defun emt-pop-multi-term (&optional number)
  "NUMBERに対応するTERMをPOPさせる."
  (interactive)
  (let* ((number (or number (elscreen-get-current-screen)))
         (buffer (emt-get-or-create-multi-term-buffer number))
         (is-current-buffer (eq (current-buffer) buffer))
         (is-shown nil)
         (window))
    (cond ((and (not (one-window-p)) is-current-buffer)
           (delete-window)
           (jump-to-register (intern (concat "emt-pop-multi-term-" (number-to-string (elscreen-get-current-screen)))))
           )
          ((not is-current-buffer)
           (walk-windows
            (lambda (win)
              (when (eq (window-buffer win) buffer)
                (setq window win)
                (setq is-shown t))))
           (cond (is-shown
                  (select-window window)
                  (switch-to-buffer buffer))
                 (t
                  (window-configuration-to-register (intern (concat "emt-pop-multi-term-" (number-to-string (elscreen-get-current-screen)))))
                  (funcall emt-pop-to-buffer-function buffer)))))))

(defun emt-get-or-create-multi-term-buffer (&optional number)
  "NUMBERに対応するTERM-BUFFERを取得する.なければ作成する."
  (let* ((number (or number (elscreen-get-current-screen)))
         (fname (emt-get-frame-name (selected-frame)))
         (buffer (get-buffer (format emt-term-buffer-name fname number))))
    (unless buffer
      (save-current-buffer
        (letf (((symbol-function 'switch-to-buffer) (symbol-function 'emt-nothing-to-buffer)))
          (multi-term)
          (setq buffer (current-buffer))))
      (with-current-buffer buffer
        (rename-buffer (format emt-term-buffer-name fname number))))
    buffer))

(defun emt-get-multi-term-buffer (&optional number)
  "NUMBERに対応するTERM-BUFFERを取得する."
  (let* ((number (or number (elscreen-get-current-screen)))
         (fname (emt-get-frame-name (selected-frame)))
         (buffer (get-buffer (format emt-term-buffer-name fname number))))
    buffer))

(defun emt-nothing-to-buffer (buffer-or-name &optional norecord force-same-window)
  (interactive)
  buffer-or-name)

(defun emt-screen-kill:around (origin &rest args)
  "SCREENの削除時に対応するTERMを削除する."
  (let* ((screen (or (and (integerp (car args)) (car args))
                     (elscreen-get-current-screen)))
         (fname (emt-get-frame-name (selected-frame)))
         (buffer (get-buffer (format emt-term-buffer-name fname screen)))
         (origin-return (apply origin args)))
    (when origin-return
      (letf (((symbol-function 'switch-to-buffer) (symbol-function 'emt-nothing-to-buffer)))
        (cond (buffer
               (delete-process buffer)
               (kill-buffer buffer)))))
    origin-return))

(defun emt-screen-swap:around (origin &rest args)
  "SCREENのSWAP時に対応するTERMを入れ替える."
  (let ((origin-return (apply origin args)))
    (when origin-return
      (let* ((current-screen (elscreen-get-current-screen))
             (previous-screen (elscreen-get-previous-screen))
             (fname (emt-get-frame-name (selected-frame)))
             (current-buffer (get-buffer (format emt-term-buffer-name fname current-screen)))
             (previous-buffer (get-buffer (format emt-term-buffer-name fname previous-screen))))
        (if current-buffer
          (with-current-buffer current-buffer
            (rename-buffer (format (concat emt-term-buffer-name "-tmp") fname previous-screen))
            (when previous-buffer
              (with-current-buffer previous-buffer
                (rename-buffer (format emt-term-buffer-name fname current-screen))))
            (rename-buffer (format emt-term-buffer-name fname previous-screen)))
          (when previous-buffer
            (with-current-buffer previous-buffer
              (rename-buffer (format emt-term-buffer-name fname current-screen)))))))
    origin-return))

(defun emt-get-frame-name (frame)
  "FRAMEのユニークな文字列表現を返す."
  (if window-system
      (frame-parameter frame 'window-id)
    (frame-parameter frame 'name)))

(advice-add 'elscreen-kill :around 'emt-screen-kill:around)
(advice-add 'elscreen-swap :around 'emt-screen-swap:around)

(provide 'elscreen-multi-term)

;;; elscreen-multi-term.el ends here
