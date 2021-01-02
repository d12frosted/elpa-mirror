wandbox.el is wandbox (online compiler) client tool.
You can compile and run code snippets by using wandbox API.

Wandbox Home: https://wandbox.org

Example
-------

## Use Interactive

M-x wandbox                 - Alias `wandbox-compile-buffer'
M-x wandbox-compile-file    - Compile with file contents
M-x wandbox-compile-region  - Compile marked region
M-x wandbox-compile-buffer  - Compile current buffer
M-x wandbox-insert-template - Insert template snippet
M-x wandbox-list-compilers  - Display copilers list

Note: if `#wandbox param: value` token found on selected file/buffer,
wandbox-compile-file/buffer compiles using those params.

## Use on Emacs Lisp

(wandbox :compiler "gcc-head" :options "warning" :code "main(){}")
(wandbox :lang "C" :compiler-option "-lm" :file "/path/to/prog.c" :save t)
(wandbox :lang "perl" :code "while (<>) { print uc($_); }" :stdin "hello")
(wandbox :lang "ruby" :code "p ARGV" :runtime-option '("1" "2" "3"))
(wandbox :profiles [(:name "php HEAD") (:name "php")] :code "<? echo phpversion();")

(add-to-list 'wandbox-profiles '(:name "User Profile" :compiler "clang-head"))
(wandbox-compile :name "User Profile" :code "...")

(wandbox-add-server "fetus" "https://wandbox.fetus.jp")
(wandbox :code "<?php echo phpversion();" :name "HHVM" :server-name "fetus")
