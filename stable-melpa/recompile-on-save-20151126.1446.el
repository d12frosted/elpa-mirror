;;; recompile-on-save.el --- Trigger recompilation on file save.

;; Copyright © 2014 Marian Schubert <marian.schubert@gmail.com>

;; Author: Marian Schubert <marian.schubert@gmail.com>
;; URL: https://github.com/maio/recompile-on-save.el
;; Package-Version: 20151126.1446
;; Package-Commit: 92e11446869d878803d4f3dec5d2101380c12bb2
;; Created: 9 Mar 2014
;; Version: 1.1
;; Package-Requires: ((dash "1.1.0") (cl-lib "0.5"))
;; Keywords: convenience files processes tools

;; This file is not part of GNU Emacs.

;;; License:

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 2 of the License, or
;; (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a way to automatically trigger recompilation
;; when associated source buffer changes.

;;; Installation:

;; The easiest and preferred way to install recompile-on-save is to use
;; the package available on MELPA.
;;
;; Manual installation:
;;
;; Save recompile-on-save.el to a directory on your load-path (e.g.,
;; ~/.emacs.d/elisp), then add the following to your .emacs file:
;;
;;  (require 'recompile-on-save)
;;

;;; Using recompile-on-save:

;; You should have at least one source buffer and one compilation
;; buffer. When you run M-x recompile-on-save in the source buffer it
;; will ask you for a compilation buffer which you want to associate
;; with it. After that, each save of the source buffer will trigger
;; recompilation in the associated compilation buffer.
;;
;; To make this process even easier you might advice any compilation
;; function (e.g., compile) using recompile-on-save-advice.
;;
;; (recompile-on-save-advice compile)
;;
;; This way source <-> compilation buffer association will happen
;; automatically when you run M-x compile.
;;
;; To (temporarily) disable automatic recompilation turn off
;; recompile-on-save-mode.
;;
;; To reset compilation buffers associations for current source buffer
;; use M-x reset-recompile-on-save

;;; Code:

(require 'dash)
(require 'cl-lib)

(defvar recompile-on-save-list nil
  "Compilation buffers associated with current buffer.")

;;;###autoload
(defun recompile-on-save (cbuf)
  (interactive
   (list
    (completing-read "Compilation buffer: "
                     (mapcar (lambda (buffer) (cons (buffer-name buffer) buffer))
                             (cl-remove-if-not (lambda (buffer) (with-current-buffer buffer (eql major-mode 'compilation-mode)))
                                            (buffer-list)))
                     (lambda (info) (cdr info)) t)))
  (recompile-on-save-mode t)
  (add-to-list 'recompile-on-save-list (get-buffer cbuf)))

;;;###autoload
(defun reset-recompile-on-save ()
  (interactive)
  (setq recompile-on-save-list nil))

;;;###autoload
(defmacro recompile-on-save-advice (function)
  `(unless (ad-find-advice ',function 'around 'recompile-on-save)
     (defadvice ,function (around recompile-on-save activate)
       (let ((buf (current-buffer)))
         ad-do-it
         (with-current-buffer buf
           (recompile-on-save compilation-last-buffer))))))

(defun ros--recompile-on-save ()
  (setq recompile-on-save-list (--filter (buffer-live-p it) recompile-on-save-list))
  (--each recompile-on-save-list (with-current-buffer it (recompile))))

;;;###autoload
(define-minor-mode recompile-on-save-mode
  "Trigger recompilation on file save."
  :lighter " RoS"
  (make-local-variable 'recompile-on-save-list)
  (if recompile-on-save-mode
      (add-hook 'after-save-hook 'ros--recompile-on-save t t)
    (remove-hook 'after-save-hook 'ros--recompile-on-save t)))

(provide 'recompile-on-save)

;;; recompile-on-save.el ends here
