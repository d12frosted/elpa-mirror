Read Dilbert comics from the comfort of Emacs.

;; Installation

;;; MELPA

If you installed from MELPA, you're done.

;;; Manual

Install these required packages:

+ enlive
+ dash

Then put this file in your load-path, and put this in your init
file:

(require 'dilbert)

;; Usage

Run one of these commands:

`dilbert': Get the latest Dilbert comic strip.

;; Tips

+ You can customize settings in the `dilbert' group.

;; Credits

This package would not have been possible without the following
packages: xkcd[1].

 [1] https://github.com/vibhavp/emacs-xkcd
