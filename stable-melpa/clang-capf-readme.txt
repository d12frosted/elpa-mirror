
Emacs built-in `completion-at-point' completion mechanism doesn't
support C in any meaningful by default, which this package tries to
remedy, by using clang's completion mechanism.  Hence this package
requires clang to be installed (see `clang-capf-clang') .

If a header file is not automatically found or in the default path,
extending `clang-capf-include-paths' or `clang-capf-extra-flags' might
help.

`clang-capf' is based on/inspired by:
- https://opensource.apple.com/source/lldb/lldb-167.2/llvm/tools/clang/utils/clang-completion-mode.el.auto.html
- https://github.com/company-mode/company-mode/blob/master/company-clang.el
- https://github.com/brianjcj/auto-complete-clang/blob/master/auto-complete-clang.el
- https://www.reddit.com/r/vim/comments/2wf3cn/basic_clang_autocompletion_query/
- https://foicica.com/wiki/cpp-clang-completion
