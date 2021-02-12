Add the function `awscli-capf' to the list of completion functions, for example:

(require 'awscli-capf)
(add-hook 'shell-mode-hook (lambda ()
                            (add-to-list 'completion-at-point-functions 'awscli-capf)))

or with use-package:

(use-package awscli-capf
  :commands (awscli-add-to-capf)
  :hook (shell-mode . awscli-add-to-capf))

For more details  see https://github.com/sebasmonia/awscli-capf/blob/master/README.md
