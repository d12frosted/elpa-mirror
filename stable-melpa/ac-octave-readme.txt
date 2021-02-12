; Installation:

If you have `melpa' and `emacs24' installed, simply type:

 M-x package-install ac-octave

Add following lines to your init file:

```elisp
(require 'ac-octave)
(add-hook 'octave-mode-hook
          '(lambda () (ac-octave-setup)))
```
