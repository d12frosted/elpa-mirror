;;; dmacro.el --- Repeated detection and execution of key operation

;; Copyright (C) 1993 Toshiyuki Masui

;; Author: Toshiyuki Masui <masui@ptiecan.com>
;;         Makoto Owada
;;         Eiji Obata
;;         Nobuyuki Mine
;; Maintainer: USAMI Kenta <tadsan@zonu.me>
;; Created: 14 Apr 1993
;; Version: 2.0
;; Package-Version: 20200803.633
;; Package-Commit: 0008e7d2403a20f444b29a63fad65819aefabe18
;; Keywords: convenience
;; URL: https://github.com/emacs-jp/dmacro
;; Package-Requires: ((emacs "24.1") (cl-lib "0.6"))

;; License: FSFAP
;; Copying and distribution of this file, with or without modification,
;; are permitted in any medium without royalty provided the copyright
;; notice and this notice are preserved.  This file is offered as-is,
;; without any warranty.

;;; Commentary:

;; Tired of performing the same editing operations again and again?
;; Using the Dynamic Macro system on GNU Emacs, you can make the system
;; perform repetitive operations automatically, only by typing the special
;; key after doing the same operations twice.

;; To use this package, simply add belo code to your init.el:
;;   (setq dmacro-key (kbd "C-S-e"))
;;   (dmacro-mode)

;; If you want to use `dmacro-mode' in global, you can turn on global one:
;;   (global-dmacro-mode)

;; NOTE: If you change `dmacro-key', you need to restart `dmacro-mode'
;; to reflect the change.


;;; Code:

(require 'cl-lib)

(defgroup dmacro nil "Dynamic Macro"
  :group 'convenient
  :prefix "dmacro-")

(defcustom dmacro-key (kbd "C-S-e")
  "Key sequences for dmacro."
  :type 'key-sequence
  :group 'dmacro)


;;; Functions

(defvar dmacro--input-keys)
(defvar dmacro--input-subkeys)

(defalias 'dmacro--user-error
  (eval-when-compile (if (fboundp 'user-error) #'user-error #'message)))

(defun dmacro--ensure-keycode (key)
  "Return key code or symbol `KEY' by `recent-keys'."
  (if (integerp key)
      key
    (cl-case key
      ('backspace ?\C-h)
      ('tab       ?\C-i)
      ('enter     ?\C-m)
      ('return    ?\C-m)
      ('escape    ?\C-\[)
      ('delete    ?\C-?)
      (t          key))))

(defun dmacro-get ()
  "Get repeated sequence."
  (let ((keys (vconcat dmacro-key dmacro-key))
        (rkeys (recent-keys)) arry)
    (if (equal keys (cl-subseq rkeys (- (length keys))))
        (progn
          (setq dmacro--input-subkeys nil)
          dmacro--input-keys)
      (setq arry (dmacro-search (cl-subseq rkeys 0 (- (length dmacro-key)))))
      (if (null arry)
          (setq dmacro--input-keys nil)
        (let ((s1 (car arry))
              (s2 (cdr arry)))
          (setq dmacro--input-keys (vconcat s2 s1))
          (setq dmacro--input-subkeys (if (equal s1 "") nil s1))
          (setq last-kbd-macro dmacro--input-keys)
          (if (equal s1 "") dmacro--input-keys s1))))))

(defun dmacro-search (array)
  "Search `ARRAY'."
  (let* ((arry (reverse array))
         (sptr 1)
         (dptr0 (dmacro-array-search (cl-subseq arry 0 sptr) arry sptr))
         (dptr dptr0)
         maxptr)
    (while (and dptr0
                (not (dmacro-array-search dmacro-key (cl-subseq arry sptr dptr0))))
      (when (= dptr0 sptr)
        (setq maxptr sptr))
      (setq sptr (1+ sptr))
      (setq dptr dptr0)
      (setq dptr0 (dmacro-array-search (cl-subseq arry 0 sptr) arry sptr)))
    (if (null maxptr)
        (let ((predict-arry (reverse (cl-subseq arry (1- sptr) dptr))))
          (if (dmacro-array-search dmacro-key predict-arry)
              nil
            (cons predict-arry (reverse (cl-subseq arry 0 (1- sptr))))))
      (cons "" (reverse (cl-subseq arry 0 maxptr))))))

(defun dmacro-array-search (pat arry &optional start)
  "Search pattern `PAT' by `ARRY'.  `START'."
  (let* ((len (length pat))
	 (max (- (length arry) len))
	 (p (or start 0))
         found)
    (while (and (not found) (<= p max))
      (setq found (equal pat (cl-subseq arry p (+ p len))))
      (unless found (setq p (1+ p))))
    (if found p nil)))


;;; Main

;;;###autoload
(define-minor-mode dmacro-mode
  "Dynamic Macro"
  :group 'dmacro
  :lighter " dmac"
  :keymap
  `((,dmacro-key
     . (lambda ()
         (interactive)
         (let ((keys (dmacro-get)))
           (if keys
               (execute-kbd-macro keys)
             (dmacro--user-error "There is no repetitive operation")))))))

;;;###autoload
(define-globalized-minor-mode global-dmacro-mode dmacro-mode
  dmacro-mode
  :group 'dmacro)

(provide 'dmacro)
;;; dmacro.el ends here
