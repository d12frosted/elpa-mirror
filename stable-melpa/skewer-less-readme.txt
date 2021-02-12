Minor mode allowing LESS stylesheet manipulation via `skewer-mode'.

Note that this is intended for use in place of `skewer-css-mode',
which does not work with lesscss.

Enable `skewer-less-mode' in a ".less" buffer.  Hit "C-c C-k" just
like in `skewer-css-mode'.  To reload the buffer when you save it,
use code like the following:

(add-hook 'skewer-less-mode
          (lambda ()
            (add-hook 'after-save-hook 'skewer-less-eval-buffer nil t)))
