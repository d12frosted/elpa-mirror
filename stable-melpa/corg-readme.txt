*corg.el* (as in *C*omplete *ORG*) is an Emacs package that
provides completion-at-point for Org-mode source block and dynamic
block headers.  corg auto-completes programming language names,
their parameters, and possible parameter values for source blocks.
For dynamic blocks, it completes block names, their parameters, and
possible parameter values.  It also completes block names inside
noweb references and in #+call syntax.

;; Usage

To enable corg in current Org buffer, do M-x `corg-setup' or to
automatically enable it on Org mode buffers by adding a hook use
the following:

  (add-hook \\='org-mode-hook #\\='corg-setup)
