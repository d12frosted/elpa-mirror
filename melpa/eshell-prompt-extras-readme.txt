This library display remote user, remote host, python virtual
environment info, git branch, git dirty info and git unpushed
number for eshell prompt.

If you want to display the python virtual environment info, you
need to install `virtualenvwrapper.el'.
M-x: package-install: virtualenvwrapper

Installation
It is recommended installed by the ELPA package system.
You could install it by M-x: with
package-install: eshell-prompt-extras.

Usage
before emacs24.4
(eval-after-load 'esh-opt
  (progn
    (autoload 'epe-theme-lambda "eshell-prompt-extras")
    (setq eshell-highlight-prompt nil
          eshell-prompt-function 'epe-theme-lambda)))

If you want to display python virtual environment information:
(eval-after-load 'esh-opt
  (progn
    (require 'virtualenvwrapper)
    (venv-initialize-eshell)
    (autoload 'epe-theme-lambda "eshell-prompt-extras")
    (setq eshell-highlight-prompt nil
          eshell-prompt-function 'epe-theme-lambda)))

after emacs24.4
(with-eval-after-load "esh-opt"
  (autoload 'epe-theme-lambda "eshell-prompt-extras")
  (setq eshell-highlight-prompt nil
        eshell-prompt-function 'epe-theme-lambda))

If you want to display python virtual environment information:
(with-eval-after-load "esh-opt"
  (require 'virtualenvwrapper)
  (venv-initialize-eshell)
  (autoload 'epe-theme-lambda "eshell-prompt-extras")
  (setq eshell-highlight-prompt nil
        eshell-prompt-function 'epe-theme-lambda))
