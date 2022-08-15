Highlight indentation by syntax (or user configurable methods).
Currently this works for C-like and Lisp-like languages, with special
support for C/C++ & CMake.
Tabs are currently not supported.

; Usage

(hl-indent-scope-mode) ;; activate in the current buffer.

; Developer Notes:

- It's important never to use `char-syntax' when reading characters,
  as the same character may represent different brackets.
  (C++ can use <> for angle brackets for as well as operators for e.g.)
  Instead read the syntax table from the point e.g. `syntax-after'.
