This package provides a more powerful alternative to `ido-mode''s
built-in flex matching.

; Acknowledgments

Scott Frazer's blog entry
http://scottfrazersblog.blogspot.com.au/2009/12/emacs-better-ido-flex-matching.html
provided a lot of inspiration.

ido-hacks was helpful for ido optimization and fontification ideas

; Installation:

Add the following code to your init file:

    (require 'flx-ido)
    (ido-mode 1)
    (ido-everywhere 1)
    (flx-ido-mode 1)
    ;; disable ido faces to see flx highlights.
    (setq ido-enable-flex-matching t)
    (setq ido-use-faces nil)
