The compile-angel package speeds up Emacs by ensuring that all Elisp
libraries are both byte-compiled and native-compiled:
- Byte compilation reduces the overhead of loading Emacs Lisp code at
  runtime.
- Native compilation improves performance by generating machine code that
  runs directly on the hardware, leveraging the full capabilities of the host
  CPU. The actual speedup varies with the characteristics of the Lisp code,
  but it is typically 2.5 to 5 times faster than the equivalent byte-compiled
  version.

This package offers:
- `compile-angel-on-load-mode': A global mode that compiles .el files both
  before they are loaded via `load' or `require', and after they are loaded,
  using `after-load-functions'.
- `compile-angel-on-save-local-mode': A local mode that compiles .el files
  whenever the user saves them.

Installation from MELPA:
------------------------
(use-package compile-angel
  :demand t
  :custom
  (compile-angel-verbose t)

  :config
  ;; Set `compile-angel-verbose' to nil to disable compile-angel messages.
  ;; (When nil, compile-angel won't show which file is being compiled.)
  (setq compile-angel-verbose t)

  ;; Uncomment the line below to auto compile when an .el file is saved
  ;; (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode)

  ;; The following directive prevents compile-angel from compiling your init
  ;; files. If you choose to remove this push to
  ;; `compile-angel-excluded-files' and compile your pre/post-init files,
  ;; ensure you understand the implications and thoroughly test your code.
  ;; For example, if you're using the `use-package' macro, you'll need to
  ;; explicitly add: (eval-when-compile (require 'use-package)) at the top of
  ;; your init file.
  (push "/init.el" compile-angel-excluded-files)
  (push "/early-init.el" compile-angel-excluded-files)

  ;; A global mode that compiles .el files before they are loaded
  ;; using `load' or `require'.
  (compile-angel-on-load-mode 1))

Links:
------
- More information about compile-angel (Frequently asked questions, usage...):
  https://github.com/jamescherti/compile-angel.el
