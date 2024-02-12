These are like a Python "doctest", but for Emacs Lisp and with an Emacs
twist. A doctest is a test written inside a docstring.  They look like:

>> (+ 1 1)
=> 2

Inline comments are fine, but quotation marks must be escaped:

>> (concat nil \"Hello world\")  ; concat should ignore nils
=> \"Hello world\"               ; ...and return a string

Some benefits:
- It's a clean way to test elisp code without any heavy dependencies
- It encourages functions that are pure or at least side-effect-free
- Your unit tests turn into documentation that your users can read!

Use ~M-x doctest~ to run doctests on an entire buffer.
Use ~M-x doctest-here~ to run the doctest on the current line.
Use ~M-x doctest-defun~ to run the current defun's doctests.
