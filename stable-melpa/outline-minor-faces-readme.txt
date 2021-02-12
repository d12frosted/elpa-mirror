Unlike `outline-mode', `outline-minor-mode' does not change
the appearance of headings to look different from comments.

This package defines the faces `outline-minor-N', which inherit
from the respective `outline-N' faces used in `outline-mode'
and arranges for them to be used in `outline-minor-mode'.

Usage:

  (use-package outline-minor-faces
    :after outline
    :config (add-hook 'outline-minor-mode-hook
                      'outline-minor-faces-add-font-lock-keywords))

If you want to only enable these faces in certain major-modes,
then add this function to their hooks instead of to the above
hook.
