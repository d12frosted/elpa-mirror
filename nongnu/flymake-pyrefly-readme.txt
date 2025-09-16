[https://elpa.nongnu.org/nongnu/flymake-pyrefly.svg]


[https://elpa.nongnu.org/nongnu/flymake-pyrefly.svg]
<https://elpa.nongnu.org/nongnu/flymake-pyrefly.html>


1 flymake-pyrefly
═════════════════

  [Pyrefly] is a fast Python type checker written in Rust.
  flymake-pyrefly is a Pyrefly backend for [Flymake] that helps you to
  see typing errors in your Python files.


[Pyrefly] <https://pyrefly.org/>

[Flymake]
<https://www.gnu.org/software/emacs/manual/html_node/flymake/index.html#Top>


2 How to install
════════════════

  flymake-pyrefly is available on [nonGNU Emacs Lisp Package Archive],
  so you can install it by `M-x package-install RET flymake-pyrefly
  RET'.

  To add flymake-pyrefly to the list of Flymake backends when editing
  Python files (notice the difference if you use eglot):

  ┌────
  │ (add-hook 'python-base-mode-hook #'pyrefly-setup-flymake-backend)
  │ 
  │ ;; alternatively, with use-package
  │ (use-package flymake-pyrefly
  │   :hook (python-base-mode . pyrefly-setup-flymake-backend))
  │ 
  │ ;; or if you use eglot
  │ (add-hook 'eglot-managed-mode-hook #'pyrefly-setup-flymake-backend)
  │ 
  │ ;; if you use eglot and use-package
  │ (use-package flymake-pyrefly
  │   :hook (eglot-managed-mode . pyrefly-setup-flymake-backend))
  └────

  If Pyrefly binary is not visible from current Python virtual
  environment, you can set it through the interface `M-x
  customize-variable RET flymake-pyrefly-binary-path RET'.


[nonGNU Emacs Lisp Package Archive] <https://elpa.nongnu.org/>
