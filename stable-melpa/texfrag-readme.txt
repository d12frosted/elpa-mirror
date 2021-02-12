Enable AUCTeX-preview in non-LaTeX modes.
Strategy:
- collect all header contents and latex fragments from the source buffer
- prepare a LaTeX document from this information
- let preview do its stuff in the LaTeX document
- move the preview overlays from the LaTeX document to the source buffer

Install texfrag via Melpa by M-x package-install texfrag.

If texfrag is activated for some buffer the image overlays for LaTeX fragments
such as equations known from AUCTeX preview can be generated
with the commands from the TeX menu (e.g. "Generate previews for document").

The major mode of the source buffer should have a
texfrag setup function registered in `texfrag-setup-alist'.
Thereby, it is sufficient if the major mode is derived
from one already registered in `texfrag-setup-alist'.

The default prefix-key sequence for texfrag-mode is the same as for preview-mode, i.e., C-c C-p.
You can change the default prefix-key sequence by customizing `texfrag-prefix'.
If you want to modify the prefix key sequence just for one major mode use
`texfrag-set-prefix' in the major mode hook before you run texfrag-mode.

You can adapt the LaTeX-header to your needs by buffer-locally setting
the variable `texfrag-header-function' to a function without arguments
that returns the LaTeX header as a string.  Inspect the definition of
`texfrag-header-default' as an example.

There are three ways to add TeXfrag support for your new major mode.

 1. Derive your major mode from one of the already supported major modes
    (see doc of variable `texfrag-setup-alist').
    You do not need to do anything beyond that if your major mode does not
    change the marks for LaTeX equations (e.g., "\f$...\f$" for LaTeX equations
    in doxygen comments for `prog-mode').

 2. Add a setup function to `texfrag-setup-alist' (see the doc for that variable).
    The minor mode function `texfrag-mode' calls that setup function
    if it detects that your major mode out of all major modes
    registered in `texfrag-setup-alist' has the closest relationship
    to the major mode of the current buffer.
    The setup function should adapt the values of the buffer local special variables
    of texfrag to the needs of the major mode.
    In many cases it is sufficient to set `texfrag-comments-only' to nil
    and `texfrag-frag-alist' to the equation syntax appropriate for the major mode.

 3. Sometimes it is necessary to call `texfrag-mode' without corresponding
    setup function.  For an instance editing annotations with `pdf-annot-edit-contents-mouse'
    gives you a buffer in `text-mode' and the minor mode `pdf-annot-edit-contents-minor-mode'
    determines the equation syntax.
    One should propably not setup such general major modes like `text-mode' for texfrag.  Thus, it is
    better to call `TeXfrag-mode' in the hook of `pdf-annot-edit-contents-minor-mode'.
    Note, that the initial contents is not yet inserted when `pdf-annot-edit-contents-minor-mode' becomes active.
    Therefore, one needs to call `texfrag-region' in an advice of `pdf-annot-edit-contents-noselect'
    to render formulas in the initial contents.
    Further note, that there is already a working version for equation preview in pdf-tools annotations.
    Pityingly, that version is not ready for public release.

The easiest way to adapt the LaTeX fragment syntax of some major mode
is to set `texfrag-frag-alist' in the mode hook of that major mode.
For `org-mode' the function `texfrag-org'
can be used as minimal implementation of such a hook function.
Note that this function only handles the most primitive
syntax for LaTeX fragments in org-mode buffers, i.e., $...$ and \[\].

For more complicated cases you can install your own
parsers of LaTeX fragments in the variable
`texfrag-next-frag-function' (see the documentation of that variable).


; Requirements:
- depends on Emacs "25" (because of when-let)
- requires AUCTeX with preview.el.

; Important changes
Here we list changes that may have an impact on the user configuration.

2018-03-05:
- `texfrag-header-function' is now called with `texfrag-source-buffer' as current buffer.
- adopted LaTeX header generation from `org-latex-make-preamble'

2019-05-04:
- `texfrag-region' for `texfrag-preview-buffer-at-start' has been moved to `post-command-hook'
  That is an important step to make `texfrag-preview-buffer-at-start' really work.
  (No repeated LaTeX processing on the same document within one command.)
- This version of texfrag is tagged 1.0.

2019-11-29:
- Let TeXfrag scale the images according to `text-scale-mode'.
- That is actually like a bugfix for `preview.el'.  In the original version of preview
  the function registered at `preview-scale-function' is run in the TeX process buffer and not in
  the associated LaTeX source buffer.  The newly registered function `texfrag-scale-from-face'
  switches to `TeX-command-buffer' (which is actually the source buffer) before it
  calculates the scaling factor.  In that way the settings in the source buffer are taken into account.
  Added the scaling factor `texfrag-scale'.  You can use that factor to scale all preview images up.
