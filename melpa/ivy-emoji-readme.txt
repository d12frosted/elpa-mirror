ivy-emoji provides a convenient way to insert any emoji in any buffer using
ivy to select the emoji by its name.

A font that supports emoji is needed.  The best results are obtained with Noto
Color Emoji or Symbola.  It might be necessary to instruct Emacs to use such
font with a line like the following.

(set-fontset-font t 'symbol
                     (font-spec :family "Noto Color Emoji") nil 'prepend)
