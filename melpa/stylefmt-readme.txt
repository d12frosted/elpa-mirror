This is a thin wrapper of [stylefmt](https://github.com/morishitter/stylefmt)

; Installation:
1. install stylefmt. If you have installed npm, just type `npm install -g stylefmt`
2 Add your init.el
  (load "path/to/stylefmt.el)
  ;optional
  (add-hook 'css-mode-hook 'stylefmt-enable-on-save)
