This package allows to filter code through clang-format to fix its formatting.
clang-format is a tool that formats C/C++/Obj-C code according to a set of
style options, see <http://clang.llvm.org/docs/ClangFormatStyleOptions.html>.
Note that clang-format 3.4 or newer is required.

clang-format.el is available via MELPA and can be installed via

  M-x package-install clang-format

when ("melpa" . "http://melpa.org/packages/") is included in
`package-archives'.  Alternatively, ensure the directory of this
file is in your `load-path' and add

  (require 'clang-format)

to your .emacs configuration.

You may also want to bind `clang-format-region' to a key:

  (global-set-key [C-M-tab] 'clang-format-region)
