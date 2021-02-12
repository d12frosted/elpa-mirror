This is extension for Flycheck.

From https://github.com/SlexAxton/css-colorguard:
CSS Colorguard helps you maintain the color set that you want, and warns
you when colors you've added are too similar to ones that already exist.

For more information about CSS Colorguard, please check the GitHub
https://github.com/SlexAxton/css-colorguard

For more information about Flycheck:
http://www.flycheck.org/
https://github.com/flycheck/flycheck

For more information about this Flycheck extension:
https://github.com/Simplify/flycheck-css-colorguard


;; Setup

Install CSS Colorguard:
npm install -g colorguard

Add following to your Emacs init.el file:
(eval-after-load 'flycheck
  '(progn
     (require 'flycheck-css-colorguard)
     (flycheck-add-next-checker 'css-csslint
                                'css-colorguard 'append)))
