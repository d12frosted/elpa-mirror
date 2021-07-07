Syntax highlighting support for "Modern C++" - until C++20 and
Technical Specification. This package aims to provide a simple
highlight of the C++ language without dependency.

It is recommended to use it in addition with the c++-mode major
mode for extra highlighting (user defined types, functions, etc.)
and indentation.

Melpa: [M-x] package-install [RET] modern-cpp-font-lock [RET]
In your init Emacs file add:
    (add-hook 'c++-mode-hook #'modern-c++-font-lock-mode)
or:
    (modern-c++-font-lock-global-mode t)

For the current buffer, the minor-mode can be turned on/off via the
command:
    [M-x] modern-c++-font-lock-mode [RET]

More documentation:
https://github.com/ludwigpacifici/modern-cpp-font-lock/blob/master/README.md

Feedback is welcome!
