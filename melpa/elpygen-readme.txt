
`elpygen.el' uses the symbol name and it's arguments under point to
insert a method or a function stub into a suitable place. It also
makes sure the symbol is not already defined, and the requested
symbol is really a function/method call.

To use the package just bind the main function to a suitable key:

(define-key python-mode-map (kbd "C-c i") 'elpygen-implement).
