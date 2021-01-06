elegant-agenda-mode uses fonts, Yanone Kaffeesatz and typography to give your org-agenda some
breathing room and elegance. Screenshots can be found in the project repository.

elegant-agenda-mode has a very small amount of customization.

If you want to change the font family used in the buffer you could would set elegant-agenda-font
ex: (setq elegant-agenda-font "Roboto Mono")

Then if you use a mono spaced font you'll also want to let elegant-agenda to know about that.
ex: (setq elegant-agenda-is-mono-font 't)

This package was inspired by work from Nicolas Rougier.
