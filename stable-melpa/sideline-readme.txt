
This library provides the frontend UI to display information either on the
left/right side of the buffer window.

1) You would need to first set up the backends,

  (setq sideline-backends-left '(sideline-flycheck))

2) Then enable the sideline in the target buffer,

  M-x sideline-mode

For backends choice, see https://github.com/emacs-sideline/sideline#-example-projects
