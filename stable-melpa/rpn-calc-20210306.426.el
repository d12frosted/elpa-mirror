;;; -*- lexical-binding: t -*-
;;; rpn-calc.el --- quick RPN calculator for hackers

;; Copyright (C) 2015 zk_phi

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

;; Author: zk_phi
;; URL: https://github.com/zk-phi/rpn-calc
;; Package-Version: 20210306.426
;; Package-Commit: 320123ede874a8fc6cde542baa0d106950318071
;; Version: 1.1.1
;; Package-Requires: ((popup "0.4"))

;;; Commentary:

;; Try: "M-x rpn-calc[RET] 1[SPC]2+3/sinnumber-to-string[SPC]"

;;; Change Log:

;; 1.0.0 first release
;; 1.1.0 changed quote behavior for symbols
;; 1.1.1 show ASCII char in the tooltip

;;; Code:

(require 'popup)
(require 'help-fns)                     ; help-function-arglist

(defgroup rpn-calc nil
  "quick RPN calculator for hackers"
  :group 'emacs)

;; + custom

(defcustom rpn-calc-operator-table
  '(
    ;; math
    ("+"   2 . +)
    ("--"  2 . -) ; if operator name is "-", we cannot insert negative number
    ("/"   2 . /)
    ("*"   2 . *)
    ("%"   2 . mod)
    ("sin" 1 . sin)
    ("cos" 1 . cos)
    ("tan" 1 . tan)
    ("lg" 1 . (lambda (x) (log x 10)))
    ("ln" 1 . log)
    ("log" 2 . (lambda (base value) (log value base)))
    ;; bitwise
    ("&" 2 . logand)
    ("|" 2 . logor)
    ("^" 2 . logxor)
    ("~" 1 . lognot)
    ("<<"  2 . ash)
    (">>"  2 . (lambda (value count) (ash value (- count))))
    ;; int <-> float
    ("float" 1 . float)
    ("int" 1 . truncate)
    ("trunc" 1 . truncate)
    ("floor" 1 . floor)
    ("ceil" 1 . ceiling)
    ("round" 1 . round)
    )
  "list of (NAME ARITY . FUNCTION)."
  :group 'rpn-calc
  :type 'sexp)

(defcustom rpn-calc-incompatible-minor-modes
  '(phi-autopair-mode key-combo-mode wrap-region-mode)
  "list of minor-modes that should be disabled while RPN calc is
active."
  :group 'rpn-calc
  :type '(repeat symbol))

(defcustom rpn-calc-apply-optional-args 'guess
  "when nil, optional arguments are NOT applied to pushed
  functions. when 'guess, optional arguments are applied only
  when all arguments are either optional or rest. otherwise,
  optional arguments are always applied."
  :group 'rpn-calc
  :type 'symbol)

(defcustom rpn-calc-apply-rest-args t
  "when non-nil, rest arguments are applied to pushed
  functions."
  :group 'rpn-calc
  :type 'boolean)

;; + utils

(defun rpn-calc--int-to-bin (int)
  (let* ((str (make-string 32 0)))
    (dotimes (n 32)
      (aset str (- 32 1 n) (if (zerop (logand int 1)) ?0 ?1))
      (setq int (ash int -1)))
    (cond ((string-match "^1*111\\(1\\|[^1].*\\)$" str)
           (concat "..1" (match-string 1 str)))
          ((string-match "^0*\\(0\\|[^0].*\\)$" str)
           (match-string 1 str))
          (t
           str))))

(defun rpn-calc--int-to-hex (int)
  (let* ((str (make-string 8 0)))
    (dotimes (n 8)
      (aset str (- 8 1 n)
            (cl-case (logand int 15)
              ((0) ?0) ((1) ?1) ((2) ?2) ((3) ?3)
              ((4) ?4) ((5) ?5) ((6) ?6) ((7) ?7)
              ((8) ?8) ((9) ?9) ((10) ?A) ((11) ?B)
              ((12) ?C) ((13) ?D) ((14) ?E) ((15) ?F)))
      (setq int (ash int -4)))
    (cond ((string-match "^F*FFF\\(F\\|[^F].*\\)$" str)
           (concat "..F" (match-string 1 str)))
          ((string-match "^0*\\(0\\|[^0].*\\)$" str)
           (match-string 1 str))
          (t
           str))))

(defun rpn-calc--int-to-char (int)
  (cl-case int
    ((0) "[NUL]")  ((1) "[SOH]")  ((2) "[STX]")  ((3) "[ETX]")  ((4) "[EOT]")
    ((5) "[ENQ]")  ((6) "[ACK]")  ((7) "[BEL]")  ((8) "[BS]")   ((9) "[HT]")
    ((10) "[LF]")  ((11) "[VT]")  ((12) "[FF]")  ((13) "[CR]")  ((14) "[SO]")
    ((15) "[SI]")  ((16) "[DLE]") ((17) "[DC1]") ((18) "[DC2]") ((19) "[DC3]")
    ((20) "[DC4]") ((21) "[NAK]") ((22) "[SYN]") ((23) "[ETB]") ((24) "[CAN]")
    ((25) "[EM]")  ((26) "[SUB]") ((27) "[ESC]") ((28) "[FS]")  ((29) "[GS]")
    ((30) "[RS]")  ((31) "[US]")  ((32) "[SPC]") ((127) "[DEL]")
    (t (if (and (> int 32) (< int 127)) (char-to-string int) "[N/A]"))))

(defun rpn-calc--float-to-ieee754 (float)
  ;; based on ieee-754.el
  (let (IEEE-sign IEEE-exp IEEE-mantissa exp)
    (if (isnan float) "NaN"
      (when (< float 0)                  ; negative
        (setq IEEE-sign t
              float (- float)))
      (cond ((= float 0)                   ; zero
             (setq IEEE-exp 0
                   IEEE-mantissa 0))
            ((= float 1e+INF)              ; infinite
             (setq IEEE-exp 255
                   IEEE-mantissa 0))
            ((<= (setq exp (floor (log float 2.0))) -127) ; subnormal (very small)
             (setq IEEE-exp 0
                   IEEE-mantissa (round (* float 0.5 (expt 2.0 127) (lsh 1 23)))))
            (t                                      ; normal
             (setq IEEE-exp (+ exp 127)
                   IEEE-mantissa (round (* (- (/ float (expt 2.0 exp)) 1) (lsh 1 23))))))
      (let ((str (format "%x%06x"
                         (+ (if IEEE-sign 128 0) (lsh IEEE-exp -1))
                         (+ (lsh (logand IEEE-exp 1) 23) IEEE-mantissa))))
        (string-match "^0*\\(0\\|[^0].*\\)$" str)
        (match-string 1 str)))))

(defun rpn-calc--function-args (fn)
  "return (ARGS OPTIONAL-ARGS . REST-ARGS) of FN."
  (let ((lst (help-function-arglist fn t))
        args optional-args)
    (while (and lst (not (memq (car lst) '(&optional &rest))))
      (push (pop lst) args))
    (when (eq (car lst) '&optional)
      (pop lst)
      (while (and lst (not (eq (car lst) '&rest)))
        (push (pop lst) optional-args)))
    (cons (nreverse args) (cons (nreverse optional-args) (cadr lst)))))

;; + core

(defvar rpn-calc--saved-minor-modes nil)
(defvar rpn-calc--stack-prepend nil)
(defvar rpn-calc--temp-buffer nil)
(defvar rpn-calc--buffer nil)
(defvar rpn-calc--stack nil)
(defvar rpn-calc--popup nil)

(defconst rpn-calc-map
  (let ((kmap (make-sparse-keymap)))
    (define-key kmap [remap self-insert-command]  'rpn-calc-self-insert)
    (define-key kmap [remap delete-backward-char] 'rpn-calc-backspace)
    (define-key kmap [remap backward-delete-char] 'rpn-calc-backspace)
    (define-key kmap [remap backward-kill-word]   'rpn-calc-backward-kill-word)
    (define-key kmap (kbd "C-n")                  'rpn-calc-next)
    (define-key kmap (kbd "C-p")                  'rpn-calc-previous)
    (define-key kmap (kbd "<down>")               'rpn-calc-next)
    (define-key kmap (kbd "<up>")                 'rpn-calc-previous)
    (define-key kmap (kbd "SPC")                  'rpn-calc-self-insert)
    (define-key kmap (kbd "DEL")                  'rpn-calc-backspace)
    (define-key kmap (kbd "RET")                  'rpn-calc-select)
    kmap))

;;;###autoload
(define-minor-mode rpn-calc
  "quick RPN calculator for hackers"
  :init-value nil
  :keymap rpn-calc-map
  (cond (rpn-calc
         (setq rpn-calc--stack         nil
               rpn-calc--stack-prepend nil
               rpn-calc--buffer        (current-buffer)
               rpn-calc--temp-buffer   (get-buffer-create " *rpn-calc*")
               rpn-calc--saved-minor-modes
               (delq nil
                     (mapcar (lambda (mode) (when (and (boundp mode) (symbol-value mode))
                                              (prog1 mode (funcall mode -1))))
                             rpn-calc-incompatible-minor-modes))
               rpn-calc--popup
               (popup-create (point) 60 10 :selection-face 'popup-menu-selection-face))
         (when (use-region-p)
           (let ((str (buffer-substring (region-beginning) (region-end))) obj)
             (with-temp-buffer
               (insert str)
               (goto-char (point-min))
               (ignore-errors
                 (while (setq obj (read (current-buffer)))
                   (rpn-calc--push obj))))))
         (add-hook 'post-command-hook 'rpn-calc--post-command-hook)
         (add-hook 'pre-command-hook 'rpn-calc--pre-command-hook)
         (rpn-calc--post-command-hook))
        (t
         (remove-hook 'post-command-hook 'rpn-calc--post-command-hook)
         (remove-hook 'pre-command-hook 'rpn-calc--pre-command-hook)
         (popup-delete rpn-calc--popup)
         (mapc 'funcall rpn-calc--saved-minor-modes)
         (kill-buffer rpn-calc--temp-buffer))))

(defun rpn-calc--pre-command-hook ()
  (unless (and (symbolp this-command)
               (string-prefix-p "rpn-" (symbol-name this-command)))
    (rpn-calc -1)))

(defun rpn-calc--post-command-hook ()
  (condition-case err
      (rpn-calc--maybe-commit-current-input)
    (error (message (error-message-string err))))
  (rpn-calc--refresh-popup))

(defun rpn-calc--take (n)
  "take first N elements from the stack."
  (when (> n 0)
    (let ((last-cell (nthcdr (1- n) rpn-calc--stack)))
      (prog1 rpn-calc--stack
        (setq rpn-calc--stack (cdr last-cell))
        (setcdr last-cell nil)))))

(defun rpn-calc--push (obj)
  (with-current-buffer rpn-calc--buffer
    (let (arglst n-args n-optionals n-required req-optionals)
      (cond ((and (consp obj) (integerp (car obj)) (functionp (cdr obj))) ; RPN operator
             (setq n-args (car obj))
             (when (< (length rpn-calc--stack) n-args)
               (error (format "too few arguments (required:%d)" n-args)))
             (push (apply (cdr obj) (nreverse (rpn-calc--take n-args))) rpn-calc--stack))
            ((functionp obj)            ; function
             (setq arglst        (rpn-calc--function-args obj)
                   n-args        (length (car arglst))
                   n-optionals   (length (cadr arglst))
                   req-optionals (and rpn-calc-apply-optional-args
                                      (or (not (eq rpn-calc-apply-optional-args 'guess))
                                          (zerop n-args)))
                   n-required    (+ n-args (if req-optionals n-optionals 0)))
             (when (< (length rpn-calc--stack) n-required)
               (error (format "too few arguments (required:%d)" n-required)))
             (if (or (null (cddr arglst)) (not rpn-calc-apply-rest-args))
                 (push (apply obj (nreverse (rpn-calc--take n-required))) rpn-calc--stack)
               (setq rpn-calc--stack (nreverse rpn-calc--stack))
               (let* ((args (rpn-calc--take n-args))
                      (optionals (if req-optionals
                                     (rpn-calc--take n-optionals)
                                   (make-list n-optionals nil)))
                      (rest-args (prog1 rpn-calc--stack
                                   (setq rpn-calc--stack nil))))
                 (setq rpn-calc--stack
                       (list (apply obj (nconc args optionals rest-args)))))))
            ((symbolp obj)              ; symbol
             (if (fboundp obj)
                 (rpn-calc--push (symbol-function obj))
               (push (symbol-value obj) rpn-calc--stack)))
            (t                          ; other expressions
             (push (eval obj) rpn-calc--stack))))))

(defun rpn-calc--maybe-commit-current-input ()
  (with-current-buffer rpn-calc--temp-buffer
    (catch 'read-error
      (let* ((obj  (condition-case nil
                       (read (buffer-string))
                     (error (throw 'read-error nil))))
             (name (when (symbolp obj) (symbol-name obj))))
        (cond ((eq obj ':)             ; command: duplicate
               (erase-buffer)
               (if rpn-calc--stack
                   (push (car rpn-calc--stack) rpn-calc--stack)
                 (error "too few arguments (required:1)")))
              ((eq obj '\\)            ; command: swap
               (erase-buffer)
               (if (cdr rpn-calc--stack)
                   (let ((tmp (car rpn-calc--stack)))
                     (setcar rpn-calc--stack (cadr rpn-calc--stack))
                     (setcar (cdr rpn-calc--stack) tmp))
                 (error "too few arguments (required:2)")))
              ((looking-back "\\(^\\|[^\\]\\)[])}\"\s\t\n]" (point-min)) ; complete input
               (erase-buffer)
               (rpn-calc--push (or (when (symbolp obj)
                                     (assoc (symbol-name obj) rpn-calc-operator-table))
                                   obj)))
              ((null name)             ; obj is not a symbol -> fail
               nil)
              ((string-match           ; a number + incomplete symbol
                "^[+-]?[0-9]*\\(?:[0-9]\\|\\.[0-9]+\\)\\(?:e[+-]?\\(?:[0-9]+\\|INF\\)\\)?"
                name)
               (let ((num (read (match-string 0 name))))
                 (erase-buffer)
                 (insert (substring name (match-end 0)))
                 (rpn-calc--push num)
                 ;; recurse
                 (rpn-calc--maybe-commit-current-input)))
              ((setq obj (let (val)    ; a complete operator
                           (catch 'ret
                             (dolist (entry rpn-calc-operator-table)
                               (when (string-prefix-p name (car entry))
                                 (if (not (string= name (car entry)))
                                     (throw 'ret nil)
                                   (setq val (cdr entry)))))
                             val)))
               (erase-buffer)
               (rpn-calc--push obj)))))))

(defun rpn-calc--refresh-popup ()
  (with-current-buffer rpn-calc--temp-buffer
    (let* ((obj-to-item (lambda (item)
                          (let ((str (prin1-to-string item)))
                            (concat str (rpn-calc--annotation item)))))
           (prepend (nreverse (mapcar obj-to-item rpn-calc--stack-prepend)))
           (head (let* ((str (buffer-string))
                        (expr (ignore-errors (read str))))
                   (concat str (rpn-calc--annotation expr t))))
           (stack (mapcar obj-to-item rpn-calc--stack)))
      (popup-set-list rpn-calc--popup (nconc prepend (cons head stack)))
      (popup-draw rpn-calc--popup))))

(defun rpn-calc--annotation (item &optional raw)
  (cond ((and raw (symbolp item))       ; unevaluated symbol
         (or (and (fboundp item) (rpn-calc--annotation (symbol-function item)))
             (and (boundp item) (not (eq item (symbol-value item)))
                  (format " (%s)" (prin1-to-string (symbol-value item))))))
        ((and raw (consp item) (memq (car item) '(quote function))) ; quoted expression
         (when (functionp (cadr item))
           (rpn-calc--annotation (cadr item) raw)))
        ((integerp item)                ; integer
         (format " (HEX:#x%s, BIN:#b%s, ASCII:%s)"
                 (rpn-calc--int-to-hex item)
                 (rpn-calc--int-to-bin item)
                 (rpn-calc--int-to-char item)))
        ((floatp item)                  ; float
         (format " (IEEE754:%s)" (rpn-calc--float-to-ieee754 item)))
        ((functionp item)               ; function
         (let ((arglst (rpn-calc--function-args item))
               lst)
           (when (and (cddr arglst) rpn-calc-apply-rest-args) ; rest-args
             (push (concat ". " (prin1-to-string (cddr arglst))) lst))
           (when (and (cadr arglst)   ; optional-args
                      rpn-calc-apply-optional-args
                      (or (not (eq rpn-calc-apply-optional-args 'guess))
                          (null (car arglst))))
             (push (mapconcat 'prin1-to-string (cadr arglst) " ") lst))
           (when (car arglst)
             (push (mapconcat 'prin1-to-string (car arglst) " ") lst)) ; args
           (concat " (" (mapconcat 'identity lst " ") ")")))))

;; + commands

(defun rpn-calc-self-insert ()
  (interactive)
  (with-current-buffer rpn-calc--temp-buffer
    (goto-char (point-max))
    (call-interactively 'self-insert-command)))

(defun rpn-calc-backspace (n)
  (interactive "p")
  (with-current-buffer rpn-calc--temp-buffer
    (if (zerop (buffer-size))
        (dotimes (_ n) (pop rpn-calc--stack))
      (backward-delete-char n))))

(defun rpn-calc-backward-kill-word (n)
  (interactive "p")
  (with-current-buffer rpn-calc--temp-buffer
    (backward-kill-word n)))

(defun rpn-calc-next (n)
  (interactive "p")
  (dotimes (_ n)
    (when rpn-calc--stack
      (push (pop rpn-calc--stack) rpn-calc--stack-prepend)
      (popup-next rpn-calc--popup))))

(defun rpn-calc-previous (n)
  (interactive "p")
  (dotimes (_ n)
    (when rpn-calc--stack-prepend
      (push (pop rpn-calc--stack-prepend) rpn-calc--stack)
      (popup-previous rpn-calc--popup))))

(defun rpn-calc-select ()
  (interactive)
  (let ((val (with-current-buffer rpn-calc--temp-buffer
               (if (not (= (point-min) (point-max)))
                   (buffer-string)
                 (and rpn-calc--stack (prin1-to-string (car rpn-calc--stack)))))))
    (when val (insert val))
    (rpn-calc -1)))

;; + provide

(provide 'rpn-calc)

;;; rpn-calc.el ends here
