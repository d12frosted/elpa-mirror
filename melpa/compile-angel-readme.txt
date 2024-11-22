The compile-angel package automatically byte-compiles and native-compiles
Emacs Lisp libraries. It offers:
- (compile-angel-on-load-mode): A global mode that compiles .el files before
  they are loaded.
- (compile-angel-on-save-local-mode): A local mode that compiles .el files
  whenever the user saves them.

The compile-angel modes speed up Emacs by ensuring all libraries are
byte-compiled and native-compiled. Byte-compilation reduces the overhead of
loading Emacs Lisp code at runtime, while native compilation optimizes
performance by generating machine code specific to your system.

The author of compile-angel was previously a user of auto-compile but
encountered an issue where several .el files were not being compiled by
auto-compile, resulting in Emacs performance degradation due to the lack of
native compilation. After extensive experimentation and research, the author
developed compile-angel to address this problem. The compile-angel package
guarantees that all .el files are both byte-compiled and native-compiled,
which significantly speeds up Emacs.

The compile-angel package was created to offer an alternative to auto-compile
that guarantees all .el files are both byte-compiled and native-compiled,
which significantly speeds up Emacs.

Before installing:
------------------
It is highly recommended to set the following variables in your init file:
  (setq load-prefer-newer t)
  (setq native-comp-jit-compilation t)
  (setq native-comp-deferred-compilation t) ; Deprecated in Emacs > 29.1

Additionally, ensure that native compilation is enabled; this should
return t: `(native-comp-available-p)`.

Installation from MELPA:
------------------------
(use-package compile-angel
  :ensure t
  :demand t
  :custom
  (compile-angel-verbose nil)
  :config
  (compile-angel-on-load-mode)
  (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode))

Links:
------
- More information about compile-angel (Frequently asked questions, usage...):
  https://github.com/jamescherti/compile-angel.el
