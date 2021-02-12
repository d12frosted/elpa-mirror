Automatically make the buffer-file to read-only based on `buffer-file-name'.
For example, it can protect library code provided by third parties.

Setup:

put into your own =.emacs= file (=init.el=)

    (require 'auto-read-only)
    (auto-read-only-mode 1)

Customize:

    ;; Third party codes are installed in vendor/ directory.
    (add-to-list 'auto-read-only-file-regexps "/vendor/")
