Image-dired extensions

- Non-blocking thumbnail creating
- Adjust image to window

## Install:

* Please install the ImageMagick before install this package.

* This package is registered at MELPA. (http://melpa.milkbox.net/)
  Please install from here.

* If you need to install manually, put this file into load-path'ed
  directory, and byte compile it if desired. And put the following
  expression into your ~/.emacs.

    (eval-after-load 'image-dired '(require 'image-dired+))

## Usage:

* Toggle the asynchronous image-dired feature

    M-x image-diredx-async-mode

 Or put following to your .emacs

    (eval-after-load 'image-dired+ '(image-diredx-async-mode 1))


* Toggle the adjusting image in image-dired feature

    M-x image-diredx-adjust-mode

 Or put following to your .emacs

    (eval-after-load 'image-dired+ '(image-diredx-adjust-mode 1))

### Optional:

* Key bindings to replace `image-dired-next-line' and `image-dired-previous-line'

    (define-key image-dired-thumbnail-mode-map "\C-n" 'image-diredx-next-line)
    (define-key image-dired-thumbnail-mode-map "\C-p" 'image-diredx-previous-line)

* Although default key binding is set, but like a dired buffer,
  revert all thumbnails if `image-diredx-async-mode' is on:

    (define-key image-dired-thumbnail-mode-map "g" 'revert-buffer)

* Delete confirmation prompt with thumbnails.

    (define-key image-dired-thumbnail-mode-map "x" 'image-diredx-flagged-delete)

### Recommend:

* Suppress unknown cursor movements:

    (setq image-dired-track-movement nil)
