## Install:

Please install the ImageMagick before installing this elisp.

Put this file into load-path'ed directory, and byte compile it if
desired. And put the following expression into your ~/.emacs.

    (eval-after-load 'image '(require 'image+))

## Usage:

* [__Recommended__] Sample Hydra setting. Instead of `imagex-global-sticky-mode' .

 https://github.com/abo-abo/hydra

    (eval-after-load 'image+
      `(when (require 'hydra nil t)
         (defhydra imagex-sticky-binding (global-map "C-x C-l")
           "Manipulating Image"
           ("+" imagex-sticky-zoom-in "zoom in")
           ("-" imagex-sticky-zoom-out "zoom out")
           ("M" imagex-sticky-maximize "maximize")
           ("O" imagex-sticky-restore-original "restore original")
           ("S" imagex-sticky-save-image "save file")
           ("r" imagex-sticky-rotate-right "rotate right")
           ("l" imagex-sticky-rotate-left "rotate left"))))

 Then try to type `C-x C-l +` to zoom-in the current image.
 You can zoom-out with type `-` .

* To manipulate a image under cursor.

    M-x imagex-sticky-mode

 Or to activate globally:

    M-x imagex-global-sticky-mode

 Or in .emacs:

    (eval-after-load 'image+ '(imagex-global-sticky-mode 1))

* `C-c +` / `C-c -`: Zoom in/out image.
* `C-c M-m`: Adjust image to current frame size.
* `C-c C-x C-s`: Save current image.
* `C-c M-r` / `C-c M-l`: Rotate image.
* `C-c M-o`: Show image `image+` have not modified.

* Adjusted image when open image file.

    M-x imagex-auto-adjust-mode

  Or in .emacs:

    (eval-after-load 'image+ '(imagex-auto-adjust-mode 1))

* If you do not want error message in minibuffer:

    (setq imagex-quiet-error t)
