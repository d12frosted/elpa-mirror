;;; rii.el --- Reversible input interface for multiple input  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  ROCKTAKEY

;; Author: ROCKTAKEY <rocktakey@gmail.com>
;; Keywords: extensions, tools
;; Package-Version: 20210317.1330
;; Package-Commit: d0cc3599129db735c23abe74d0876286a2fd6b6a

;; Version: 1.0.0
;; Package-Requires: ((emacs "24.3"))
;; URL: https://github.com/ROCKTAKEY/rii
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
;;; Rii: Reversible Input Interface for Emacs
;;   You can read multiple input from users.  Users can go back backward input
;;   through the buttons in the buffer.

;;     (rii ((editor (completing-read "Favorite editor: " '("Emacs" "Vim" "VSCode")))
;;           (fruit  (intern (completing-read "Favorite fruit: " '(apple orange lemon)))))
;;       (switch-to-buffer "*Welcome-to-Rii*")
;;       (erase-buffer)
;;       (insert "Welcome to Rii!\n\n"
;;               "Your favorite editor is " editor "!\n"
;;               "Your favorite fruit is " (pp fruit) "!\n"))
;;
;;
;;; How to Use?
;;   You can just use macro `rii' for the purpose.  Semantics is almost same as `let',
;;   but a little expanded.  Buffer is shown to provide backward input.
;;
;;     (rii (
;;           ;; You can bind any object, such as string, and symbol.
;;           (editor (completing-read "Favorite editor: " '("Emacs" "Vim" "VSCode")))
;;           (fruit  (intern (completing-read "Favorite fruit: " '(apple orange lemon))))
;;           ;; If you would like to display string in buffer instead of value,
;;           ;; use `rii-change-display-value'.
;;           (str-list (let* ((list-list '(("star" . ("Sun" "Vega" "Antares" "Sirius"))
;;                                         ("planet" . ("Mercury" "Venus" "Earth" "Mars"))))
;;                            (key (completing-read "Which list do you use: " list-list))
;;                            (value (cdr (assoc key list-list))))
;;                       (rii-change-display-value
;;                        value                ;Actual value
;;                        key)))               ;Displayed string
;;           ;; If you want to change string of button, use list instead of symbol as car.
;;           ;; Cdr the car list is plist.
;;           ((sport                            ;Symbol bound by value
;;             :display "Your favorite sports") ;String displayed on the buffer
;;            (completing-read "Favorite sports: "
;;                             '("soccer" "baseball" "basketball" "skiing"))))
;;       (switch-to-buffer "*Welcome-to-Rii*")
;;       (erase-buffer)
;;       (insert "Welcome to Rii!\n\n"
;;               "Your favorite editor is " editor "!\n"
;;               "Your favorite fruit is " (pp fruit) "!\n"
;;               "Your favorite sport is " sport "!\n\n")
;;       (dolist (x str-list)
;;         (insert x ", "))
;;       (insert "are very beautiful!\n"))
;;
;;
;;; Detail of `rii' macro
;;
;;     (rii ((VAR VALUE) ...)
;;       BODY...)
;;
;;
;;;; Basic structure
;;   Basical smantics is same as `let', except that `VAR' cannot be used instead of
;;   =(VAR nil)= (because binding by `nil' is unecessary).  Also constant or noninteractive
;;   sexp can be also accepted as `VALUE', but button is still displayed, so `let' is
;;   recommended for that case.
;;
;;     (rii (
;;           ;;Input string
;;           (str (read-string "Input some str: "))
;;           ;; Constant is accepted but not recommended
;;           (x 1))
;;       (message "%s / %d" str x))
;;
;;
;;;; Change button string
;;   If you want to change button string, use =((VAR :display "something") VALUE)=
;;   instead of =(VAR VALUE)=, in first argument of `rii'.  By default, string capitalized
;;   `VAR' and repleced "-" with " " is used.
;;
;;     (rii (((str :display "My string")       ;Button is shown as "My string" instead of "Str"
;;            (read-string "Hit some str: "))
;;           ((num :display "My number")       ;Button is shown as "My number" inttead of "Num"
;;            (read-number "Hit number: ")))
;;       (message "%s%d" str num))
;;
;;
;;;; Change displayed string of each value
;;    If you want to change string displayed after button instead of value returned by `VALUE',
;;    use `rii-change-display-value' or `rii-change-display-value-func'.
;;    First argument is commonly value returned by `VALUE'.
;;    On `rii-change-display-value', second argument is string displayed instead of `VALUE'.
;;    On `rii-change-display-value-func', second argument is function which recieves
;;    first argument and which returns displayed string.
;;
;;      (rii ((str1 (rii-change-display-value
;;                   (read-string "String1: ")
;;                   "xyz"))                    ;Always display "xyz"
;;            (str2 (let ((s (read-string "String1: ")))
;;                      (rii-change-display-value
;;                       s                      ;Actually bound value
;;                       (concat "xyz" s))))    ;Prefixed by "xyz"
;;            (num (rii-change-display-value-func
;;                  (read-number "Number: ")    ;Actually bound value
;;                  (lambda (x)                 ;x is bound by read number
;;                    (make-string x ?a)))))    ;display "a" X times.
;;        (message "%s\n%s\n%d" str1 str2 num))
;;
;;
;;;; Use custom variables prefixed by =rii-=
;;    When symbol prefixed by "rii-" is used as `VAR', the =(VAR VALUE)=
;;    is regarded as special.  While the other `VALUE' s are evaluated
;;    sequencially, `VALUE' s of "rii-"-prefixed `VAR' are evaluated
;;    earlier than any others.  These `VAR' is bound buffer-locally
;;    (not bound dynamically), so accessable only in the buffer.
;;
;;      (rii ((rii-buffer-name "*Welcome*")     ;Like this
;;            (str (read-string "str: ")))
;;        (message str))
;;
;;
;;; Keybinding in buffer
;;   | Key            | Function                | Description                   |
;;   |----------------+-------------------------+-------------------------------|
;;   | TAB            | forward-button          | Go to next button             |
;;   | backtab(S-TAB) | backward-button         | Go to previous button         |
;;   | SPC            | scroll-up-command       | Scroll up the buffer          |
;;   | S-SPC          | scroll-down-command     | Scroll down the buffer        |
;;   | M-p            | rii-previous-history    | Load previous history         |
;;   | M-n            | rii-next-history        | Load next history             |
;;   | q              | quit-window             | Quit this buffer (not killed) |
;;   | C-c C-k        | rii-kill-current-buffer | Kill buffer                   |
;;   | C-c C-c        | rii-apply               | Push apply button             |
;;
;;; Custom variables
;;   All custom variables below can use as `VAR' in first argument of `rii'.
;;   You can change default value by set variable globally.
;;
;;;; `rii-button-type', `rii-button-apply-type'
;;    Button type which is used to create input button or application button.
;;    See document of `define-button-type'.
;;
;;;; `rii-buffer-name'
;;    Buffer name used by `rii'.
;;
;;;; `rii-multiple-buffer'
;;    Whether create multiple buffers when buffer named `rii-buffer-name'
;;    is already exist.  when the value is `non-nil' and when buffer named
;;    `rii-buffer-name' is already exist, `rii' creates buffer named
;;    `rii-buffer-name' + "<N>" (N is serial number).  When the value is `nil',
;;    ask whether kill the buffer or not.
;;
;;;; `rii-separator-after-button'
;;    Separator string between section.
;;    (section means pair of button and displayed value).
;;
;;;; `rii-separator-between-section'
;;    Separator string between button and value.
;;
;;;; `rii-confirm-when-apply'
;;    Whether confirm before apply or not.
;;
;;;; `rii-header-document'
;;   Comment inserted on head of the buffer.
;;
;;;; `rii-ring-history-variable'
;;    Variable which has history.
;;    Set this on `rii' if you want to use isolated history.
;;
;;;; `rii-ring-history-size-default'
;;    Default size of history saved in `rii-ring-history-variable'.
;;
;;; License
;;   This package is licensed by GPLv3. See LICENSE.

;;

;;; Code:

(require 'cl-lib)
(require 'ring)

(defgroup rii ()
  "Group for rii."
  :group 'tools
  :prefix "rii-")

(cl-defstruct rii-variable
  "Structure which retains each variable in `rii'."
  symbol
  func
  value
  plist
  display
  button
  overlay)

(cl-defstruct rii-value
  "Structure which retains value and displayed string."
  value
  display)

(define-button-type 'rii-button
  'face 'rii-button-face)

(define-button-type 'rii-button-apply
  'face 'rii-button-apply-face)

(defcustom rii-button-type 'rii-button
  "Button type used by `rii'.  See `define-button-type'."
  :type 'symbol
  :group 'rii
  :risky t)

(defcustom rii-button-apply-type 'rii-button-apply
  "Button type used by `rii' as \"apply button\". See `define-button-type'."
  :type 'symbol
  :group 'rii
  :risky t)

(defcustom rii-buffer-name "*Rii*"
  "Buffer name for `rii'."
  :type 'string
  :group 'rii)

(defcustom rii-multiple-buffer t
  "Allow `rii' to create multiple buffers by adding suffix like <1>, or not."
  :type 'boolean
  :group 'rii)

(defcustom rii-separator-after-button "\n"
  "Separator between each section."
  :type 'string
  :group 'rii)

(defcustom rii-separator-between-section ": "
  "Separator between button and inputted string."
  :type 'string
  :group 'rii)

(defcustom rii-confirm-when-apply t
  "Confirm after pushing apply button before actual action."
  :type 'boolean
  :group 'rii)

(defcustom rii-header-document
  "\\[rii-apply] to apply, \\[rii-kill-current-buffer] to abort.

"
  "Document displayed on header of buffer made by `rii'."
  :type 'string
  :group 'rii)

(defcustom rii-ring-history-variable 'rii--ring-history-default
  "Variable to save history on `rii'."
  :type 'variable
  :group 'rii)

(defcustom rii-ring-history-size-default 50
  "Default size of history size."
  :type 'integer
  :group 'rii)

(defvar rii--ring-history-default nil
  "Default variable saved on, by `rii'.")

(defvar rii--variables nil
  "Alist whose KEY is variable and whose VALUE is value of the variable.")

(defvar rii--body nil
  "Body of `rii'.
Valid in `rii-mode' buffer.")

(defface rii-button-face
  ;; Copied from definition of `custom-button' in cus-edit.el
  '((((type x w32 ns) (class color))
     :box (:line-width 2 :style released-button)
     :background "lightgrey" :foreground "black"))
  "Face for button created by `rii'.")

(defface rii-button-apply-face
  '((t (:inherit rii-button-face)))
  "Face for apply button created by `rii'.")

(defun rii--update-overlay (overlay value display)
  "Update string in OVERLAY to VALUE.
Display DISPLAY instead of VALUE when display is not nil."
  (let ((inhibit-read-only t)
        (beg (overlay-start overlay))
        (end (overlay-end overlay)))
    (save-excursion
      (goto-char (overlay-start overlay))
      (insert
       (cond
        (display display)
        ((stringp value)
         value)
        (t
         (pp value))))
      (delete-char (- end beg)))))

(defun rii--alist-set (alist key value)
  "Re-assosiate VALUE on KEY in ALIST."
  (let ((cons (assq key alist)))
    (if cons
        (setcdr cons value)
      (error "No variable `%S' detected in `%S'" key alist))))

(defun rii-kill-current-buffer ()
  "Kill current buffer if input \"y\"."
  (interactive)
  (when (y-or-n-p "Really kill this buffer? ")
    (kill-buffer (current-buffer))))

(defvar rii-mode-map
  (let ((map (make-sparse-keymap)))
    (mapc
     (lambda (arg) (define-key map (kbd (car arg)) (cdr arg)))
     '(("TAB" . forward-button)
       ("S-TAB" . backward-button)
       ("<backtab>" . backward-button)
       ("q" . quit-window)
       ("SPC" . scroll-up-command)
       ("S-SPC" . scroll-down-command)
       ("M-p" . rii-previous-history)
       ("M-n" . rii-next-history)
       ("C-c C-c" . rii-apply)
       ("C-c C-k" . rii-kill-current-buffer)))
    map)
  "Keymap for `rii-mode'.")

(define-derived-mode rii-mode nil "Rii"
  "Used by `rii'."
  (setq buffer-read-only t))

(defvar rii--apply-button nil)

(defun rii-apply ()
  "Push \"apply\" button in current buffer."
  (interactive)
  (goto-char (button-start rii--apply-button))
  (button-activate rii--apply-button))

(defun rii--insert-button-and-overlay (rii-variable-list)
  "Insert button and overlay at point, and set as member of RII-VARIABLE-LIST.
Inserted button and overlay is indicated by RII-VARIABLE-LIST."
  (dolist (rii-v rii-variable-list)
    (setf (rii-variable-button rii-v)
          (insert-button
           (or
            (plist-get (rii-variable-plist rii-v) :display)
            (capitalize
            (symbol-name (rii-variable-symbol rii-v))))
           'type rii-button-type
           'action
           (lambda (&optional _)
             (pcase (funcall (rii-variable-func rii-v))
               ((and (pred rii-value-p) x)
                (setf (rii-variable-value rii-v) (rii-value-value x))
                (setf (rii-variable-display rii-v) (rii-value-display x)))
               (x
                (setf (rii-variable-value rii-v) x)))
             (rii--update-overlay
              (rii-variable-overlay rii-v)
              (rii-variable-value rii-v)
              (rii-variable-display rii-v)))))
    (insert rii-separator-between-section)
    (insert
     (or (car-safe (rii-variable-value rii-v))
         (rii-variable-value rii-v)
         " "))
    (setf (rii-variable-overlay rii-v)
          (make-overlay (1- (point)) (point)))
    (insert "\n" rii-separator-after-button)))

(defmacro rii--insert-apply-button (rii-variable-list &rest body)
  "Insert \"apply\" button at point, whose action is evaluating BODY.
BODY is evaluated in environment defined by RII-VARIABLE-LIST.
On the environment, symbol of each element is bound as local variable."
  (declare (indent 1))
  (let ((rii-v (cl-gensym))
        (system-variables (cl-gensym))
        (buffer (cl-gensym)))
    `(eval
      '(let ((,system-variables
              (sort
               (cl-remove-if-not
                (lambda (cons)
                  (string-prefix-p "rii-" (symbol-name (car cons))))
                (buffer-local-variables))
               (lambda (x y) (string< (symbol-name (car x))
                                      (symbol-name (car y))))))
             (,buffer (current-buffer)))
         (insert-button
          "Apply"
          'type rii-button-apply-type
          'action
          (lambda (_)
            (if (and rii-confirm-when-apply
                     (not (y-or-n-p "Really apply? ")))
                (message "Application canceled")

              (rii--alist-set
               ,system-variables
               ',rii-variable-list
               (mapcar
                (lambda (rii-v)
                  (setq rii-v (copy-rii-variable rii-v))
                  (setf (rii-variable-button rii-v) nil)
                  (setf (rii-variable-overlay rii-v) nil)
                  rii-v)
                ,rii-variable-list))
              (assq-delete-all 'rii--apply-button ,system-variables)

              (unless (symbol-value rii-ring-history-variable)
                (set rii-ring-history-variable (make-ring rii-ring-history-size-default)))

              (ring-insert
               (symbol-value rii-ring-history-variable)
               ,system-variables)

              (eval
               (append
                '(let)
                (list
                 (mapcar
                  (lambda (,rii-v)
                    (list
                     (rii-variable-symbol ,rii-v)
                     (list
                      'quote
                      (rii-variable-value ,rii-v))))
                  ,rii-variable-list))
                ',body))
              (kill-buffer ,buffer)))
          t))
      t)))

(defun rii--get-system-variable (symbol system-variables)
  "Evaluate `cadr' of `assq' of SYMBOL and SYSTEM-VARIABLES like `let'.

For example, (`rii--get-system-variable' x '((x (+ 1 2 3)) (y (* 1 2 4))))
returns 6, which (+ 1 2 3) returns."
  (let ((cons (assq symbol system-variables)))
    (if cons
        (eval (cadr cons))
      (symbol-value symbol))))

(defun rii-change-display-value (value display)
  "Display DISPLAY instead of VALUE on `rii' buffer."
  (make-rii-value :value value :display display))

(defun rii-change-display-value-func (value func)
  "Display (funcall FUNC VALUE) instead of VALUE on `rii' buffer."
  (make-rii-value :value value
                  :display (funcall func value)))

(defmacro rii (spec &rest body)
  "Display buffer, input string reversibly, and then run BODY.

You can write like `let'.  In the other words, first argument is SPEC, list of
\(VAR VALUE) and rest arguments are BODY, evaluated when apply button is pushed.
Each VALUE is evaluated sequentially, and VAR is set to the result when
BODY is evaluated.  VALUE can include interactive function such as
`completing-read', `read-from-minibuffer', and so on.

When you call this function, buffer with some buttons is shown and
VALUEs are evaluated sequentially.  Each result is displayed after the button.
If you hits `quit', you can evaluate VALUEs again to push buttons.

VALUE can return object of any type.  If you want to display the object
not with `pp' but as other string, you can use `rii-change-display-value'
or `rii-change-display-value-func'.  First argument is actual value, commonly.
On `rii-change-display-value', second argument is displayed string.
On `rii-change-display-value-func', second argument is function which recieves
the value as argumentand which returns displayed string.

If VAR is prefixed with \"rii-\", it is regarded special.  These (VAR VALUE)s are
evaluated earlier than any others.  Note that the VALUE of VAR prefixed with
\"rii-\" should not be interactive.

\(fn ((VAR VALUE) ...) BODY...)"
  (declare (indent 1))
  (let* ((system-variables
          (append
           (cl-remove-if-not
            (lambda (arg)
              (string-prefix-p "rii-" (symbol-name (or (car-safe (car arg))
                                                       (car arg)))))
            spec)))
         (spec
          (mapcar
           (lambda (arg)
             (cons (car arg)
                   `(lambda () ,(cadr arg))))
           (cl-delete-if
            (lambda (arg)
              (string-prefix-p "rii-" (symbol-name (or (car-safe (car arg))
                                                       (car arg)))))
            spec)))

         (buf (cl-gensym))
         (symbol (cl-gensym))
         (func (cl-gensym))
         (rii-v (cl-gensym))
         (cons (cl-gensym))
         (plist (cl-gensym)))
    `(let* ((rii-buffer-name
             (rii--get-system-variable 'rii-buffer-name
                                       ',system-variables))
            (,buf (get-buffer rii-buffer-name))
            (rii-multiple-buffer
             (rii--get-system-variable 'rii-multiple-buffer
                                       ',system-variables)))
       (if ,buf
           (if rii-multiple-buffer
               (setq ,buf (generate-new-buffer rii-buffer-name))
             (pop-to-buffer ,buf)
             (or (kill-buffer-ask ,buf)
                 (error "Cannot kill buffer"))
             (setq ,buf (get-buffer-create rii-buffer-name)))
         (setq ,buf (get-buffer-create rii-buffer-name)))

       (pop-to-buffer ,buf)

       (let ((inhibit-read-only t))
         (rii-mode)
         (insert (substitute-command-keys rii-header-document))

         (dolist (,cons ',system-variables)
           (eval (list
                  'setq-local (car ,cons) '(eval (cadr ,cons)))))

         (setq-local rii--body ',body)
         (setq-local
          rii--variables
          (mapcar
           (lambda (,cons)
             (let* ((,symbol (or (car-safe (car ,cons))
                                 (car ,cons)))
                    (,plist (mapcar #'eval (cdr-safe (car ,cons))))
                    ;; Eval lambda to create closure
                    (,func (eval (cdr ,cons)))
                    (,rii-v (make-rii-variable :symbol ,symbol
                                               :func ,func
                                               :plist ,plist)))
               ,rii-v))
           ',spec))

         (rii--insert-button-and-overlay rii--variables)

         (setq-local rii--apply-button
                     (rii--insert-apply-button rii--variables
                       ,@body))

         (set-buffer-modified-p nil)

         (dolist (,rii-v rii--variables)
           (goto-char (button-start (rii-variable-button ,rii-v)))
           (button-activate (rii-variable-button ,rii-v)))

         (button-activate rii--apply-button)))))

(defun rii-previous-history (arg)
  "Save current input and display previous history.
ARG should be integer, which indicate how many history you want to go back."
  (interactive "P")
  (unless (eq major-mode 'rii-mode)
    (error "Current buffer is not `rii-mode'"))

  (unless (symbol-value rii-ring-history-variable)
    (set rii-ring-history-variable (make-ring rii-ring-history-size-default)))

  (let ((arg (or arg 1))
        (inhibit-read-only t)
        (system-variables
         (sort
          (cl-remove-if-not
           (lambda (cons)
             (string-prefix-p "rii-" (symbol-name (car cons))))
           (buffer-local-variables))
          (lambda (x y) (string< (symbol-name (car x))
                                 (symbol-name (car y)))))))
    (rii--alist-set
     system-variables
     'rii--variables
     (mapcar
      (lambda (rii-v)
        (setq rii-v (copy-rii-variable rii-v))
        (setf (rii-variable-button rii-v) nil)
        (setf (rii-variable-overlay rii-v) nil)
        rii-v)
      rii--variables))
    (rii--alist-set system-variables 'rii--apply-button nil)

    (unless (ring-member (symbol-value rii-ring-history-variable)
                         system-variables)
      (ring-insert (symbol-value rii-ring-history-variable)
                   system-variables))

    (erase-buffer)
    (mapc #'kill-local-variable
          (mapcar #'car system-variables))

    (setq system-variables
          (mapcar
           #'cl-copy-list
           (ring-ref (symbol-value rii-ring-history-variable)
                     (+ (ring-member (symbol-value rii-ring-history-variable)
                                     system-variables)
                        arg))))
    (rii--alist-set
     system-variables
     'rii--variables
     (mapcar #'copy-rii-variable
             (cdr (assq 'rii--variables system-variables))))

    (dolist (cons system-variables)
      (eval `(setq-local ,(car cons) ',(cdr cons))))

    (insert (substitute-command-keys rii-header-document))
    (rii--insert-button-and-overlay rii--variables)
    (setq rii--apply-button
          (eval
           `(rii--insert-apply-button rii--variables
              ,@rii--body)))))

(defun rii-next-history (arg)
  "Save current input and display next history.
ARG should be integer, which indicate how many history you want to go forward."
  (interactive "P")
  (rii-previous-history (or (ignore-errors (- arg)) -1)))

(provide 'rii)
;;; rii.el ends here
