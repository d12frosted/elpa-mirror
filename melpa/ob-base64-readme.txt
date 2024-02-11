This package extends org-mode with a way to evaluate base64-encoded content
either within Emacs or view it externally via some 3rd-party opener.

(add-to-list 'org-babel-load-languages '(base64 . t))

NB: After a fresh install a restart of Emacs (or org-babel at least) might
be required.
