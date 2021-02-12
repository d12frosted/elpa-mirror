
This package defines poly-ruby-mode, which introduces polymode for
here-documents in a ruby script.

Currently editing actions against sexps does not work properly in
polymode, so it is advised you turn this mode on only when
necessary.

  (define-key ruby-mode-map (kbd "C-c m") 'toggle-poly-ruby-mode)

This package also has experimental support for enh-ruby-mode and
defines poly-enh-ruby-mode and toggle-poly-enh-ruby-mode.

  (define-key enh-ruby-mode-map (kbd "C-c m") 'toggle-poly-enh-ruby-mode)
