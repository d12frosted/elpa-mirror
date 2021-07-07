  GNU Emacs major mode for editing Zephir code.  Provides syntax
  highlighting, indentation, movement, Imenu and navigation support.

  Zephir -- is a high level language that eases the creation and
maintainability of extensions for PHP.  Zephir extensions are
exported to C code that can be compiled and optimized by major C
compilers such as gcc/clang/vc++.  Functionality is exposed to the
PHP language.  For more information see URL `https://zephir-lang.com'.

;; Subword Mode:

  GNU Emacs comes with `subword-mode', a minor mode that allows you to
navigate the parts of a “camelCase” as if they were separate words.  For
example, Zephir Mode treats the variable “fooBarBaz” as a whole name by
default.  But if you enable `subword-mode' then Emacs will treat the variable
name as three separate words, and therefore word-related commands
(e.g. “M-f”, “M-b”, “M-d”, etc.) will only affect the “camelCase” part of the
name under the cursor.

  If you want to always use `subword-mode' for Zephir files then you can add
this to your Emacs configuration:

   (add-hook 'zephir-mode-hook
     #(lambda () (subword-mode 1)))
