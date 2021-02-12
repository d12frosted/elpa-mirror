Note: this package is still early stage.  I'm going to
support [nim-mode](https://github.com/nim-lang/nim-mode) first and
then other programming major-modes.

You can see the instruction here:
 https://github.com/yuutayamada/suggestion-box-nim-el

This package is more or less for major-mode maintainers who want to
show type information on the cursor and currently only tested on
nim-mode (https://github.com/nim-lang/nim-mode).

The tooltip will be placed above on the current cursor, so most of
the time, the tooltip doesn't destruct your auto-completion result.

## Tutorial

- Step1: format string

----------------
(progn
(require 'suggestion-box)

(cl-defmethod suggestion-box-normalize ((_backend (eql test)) raw-str)
   (format "foo %s bar" raw-str))

(let ((str "string"))
  (suggestion-box-put str :backend 'test)
  (insert "()")
  (backward-char 1)
  (suggestion-box str))) <- you can C-x C-e after the close parenthesis and
                            this will popup "foo string bar" on the cursor.

----------------

- Step2: more complex logic (work in progress)
  this is just example of nim-mode.  Basically Nim's type signature is
  like this: "proc (a: string, b: int) {.gcsafe.}" and below
  configuration strip annoying part (outside of parenthesis).
  Output example: "a: string" if cursor is inside 1th arg's position.

----------------
(cl-defmethod suggestion-box-normalize ((_backend (eql nim)) raw-str)
  "Return normalized string."
  (suggestion-box-h-filter
   :content    (suggestion-box-h-trim raw-str "(" ")")
   :split-func (lambda (content) (split-string content ", "))
   :nth-arg    (suggestion-box-h-compute-nth "," 'paren)
   :sep "" :mask1 "" :mask2 ""))
----------------


- Step3: work with company-capf backend (work in progress)
  here is what I did in nim-mode:

----------------
(defcustom nim-capf-after-exit-function-hook 'nimsuggest-after-exit-function
  "A hook that is called with an argument.
The argument is string that has some properties."
  :type 'hook
  :group 'nim)

(defun nimsuggest-after-exit-function (str)
  "Default function that is called after :exit-function is called.
The STR is string that has several property you can utilize."
  (when-let ((type (and str (get-text-property 0 :nim-type str))))
    (suggestion-box-put type :backend 'nim)
    (suggestion-box type)))

;; note I simplified this function because it was too long
(defun nim-capf-nimsuggest-completion-at-point ()
  (list beg end (completion-table-with-cache 'nim-capf--nimsuggest-complete)
    ;; ... some properties ...
    :exit-function #'nim-capf--exit-function))

(defun nim-capf--exit-function (str status)
  "Insert necessary things for STR, when completion is done.
You may see information about STATUS at `completion-extra-properties'.
But, for some reason, currently this future is only supporting
company-mode.  See also: https://github.com/company-mode/company-mode/issues/583"
  (unless (eq 'completion-at-point this-command)
    (cl-case status
      ;; finished -- completion was finished and there is no other completion
      ;; sole -- completion was finished and there is/are other completion(s)
      ((finished sole)
       (when-let ((type-sig (get-text-property 0 :nim-sig str)))
         (cl-case (intern type-sig)
           ((f T) ; <- this means current completion was function or
                  ;    template, which needs "()"
            (insert "()")
            (backward-char 1)
            (run-hook-with-args 'nim-capf-after-exit-function-hook str)))))
      (t
       ;; let other completion backends
       (setq this-command 'self-insert-command)))))
----------------
