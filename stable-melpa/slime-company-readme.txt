
This is a backend implementation for the completion package
company-mode by Nikolaj Schumacher. More info about this package
is available at http://company-mode.github.io/

As of version 1.0 this completion backend supports the normal and
the fuzzy completion modes of SLIME.

; Installation:

 Put this file somewhere into your load-path
 (or just into slime-path/contribs) and then call

  (slime-setup '(slime-company))

I also have the following, IMO more convenient key bindings for
company mode in my .emacs:

  (define-key company-active-map (kbd "\C-n") 'company-select-next)
  (define-key company-active-map (kbd "\C-p") 'company-select-previous)
  (define-key company-active-map (kbd "\C-d") 'company-show-doc-buffer)
  (define-key company-active-map (kbd "M-.") 'company-show-location)
