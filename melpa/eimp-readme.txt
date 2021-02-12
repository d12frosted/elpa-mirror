
This package allows interactive image manipulation from within
Emacs.  It uses the mogrify utility from ImageMagick to do the
actual transformations.

Switch the minor mode on programmatically with:

    (eimp-mode 1)

or toggle interactively with M-x eimp-mode RET.

Switch the minor mode on for all image-mode buffers with:

    (autoload 'eimp-mode "eimp" "Emacs Image Manipulation Package." t)
    (add-hook 'image-mode-hook 'eimp-mode)
