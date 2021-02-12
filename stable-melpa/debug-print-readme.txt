This program provides a nice ``printf debugging'' environment by
the way Gauche do. Sometimes printf debugging with `message' bothers you.
For example, if you want to observe the variable `foo' in the expression
  (let ((foo (something-with-side-effect)
        (bar (something-depends-on foo))
    ...)
you have to use frustrating idiom:
  (let ((foo (progn
               (let ((tmp (something-with-side-effect)))
                 (message "%s" tmp)
                 tmp)))
        (bar (something-depends-on foo))
    ...)
(In this case one can use `let*' but it is an example.) This program
allows you to write as follows:
  (let ((foo ::?= (something-with-side-effect)
        (bar (something-depends-oidn foo))
    ...)
After rewrite, move point to the last of expression as usual, and do
`debug-print-eval-last-sexp'. It is the same as `eval-last-sexp' except rewrite
the read expression recursively as follows:
  ... ::?= expr ...
    => ... (debug-print expr) ...
Here `debug-print' is a macro, which does that the above frustrating idiom does.
(Note that this needs initialization.) For who kwons Gauche note that it is
not implemented by reader macro. So one have to use some settings to inform
emacs that the expression needs preprocessed.

Initialization and configuration: To use the above feature, write as follows
in your .emacs.d/init.el (after setting of load-path):
  (require 'debug-print)
  (debug-print-init)
  (define-key global-map (kbd "C-x C-e") 'debug-print-eval-last-sexp)
debug-print.el use some variables:
  `debug-print-symbol'
  `debug-print-buffer-name'
  `debug-print-width'
(See definitions below.) You have to set these before calling of `debug-print-init'.

Example of code:
  (debug-print-init)
  (eval-with-debug-print
   (defun fact (n)
     (if (zerop n)
         1
         (* n ::?= (fact (- n 1))))))
  (fact 5)
Result: <buffer *debug-print*>
  ::?="fact"::(fact (- n 1))
  ::?="fact"::(fact (- n 1))
  ::?="fact"::(fact (- n 1))
  ::?="fact"::(fact (- n 1))
  ::?="fact"::(fact (- n 1))
  ::?-    1
  ::?-    1
  ::?-    2
  ::?-    6
  ::?-    24
For more detail, see debug-print-test.el .
