This package provides a convenient method of selecting default fonts.

To bind keys to next/previous font.


; Usage

Example:

  (when (display-graphic-p)
    (define-key global-map (kbd "<M-prior>") 'default-font-presets-forward)
    (define-key global-map (kbd "<M-next>") 'default-font-presets-backward))
