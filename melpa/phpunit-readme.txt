Thanks to tox.el(https://github.com/chmouel/tox.el) from Chmouel Boudjnah.

To use this code, bind the functions `phpunit-current-test', `phpunit-current-class',
and `phpunit-current-project' to convenient keys with something like :

(define-key web-mode-map (kbd "C-x t") 'phpunit-current-test)
(define-key web-mode-map (kbd "C-x c") 'phpunit-current-class)
(define-key web-mode-map (kbd "C-x p") 'phpunit-current-project)
