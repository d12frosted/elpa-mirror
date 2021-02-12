Put this file in a folder where Emacs can find it.

Add following lines to your .emacs initialization file
to enable auto save in all programming modes.

    (require 'real-auto-save)
    (add-hook 'prog-mode-hook 'real-auto-save-mode)

Auto save interval is 10 seconds by default.
You can change it to whatever value you want at any point.

    (setq real-auto-save-interval 5) ;; in seconds
