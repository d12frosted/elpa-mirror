wrap-region is a minor mode that wraps a region with
punctuations. For tagged markup modes, such as HTML and XML, it
wraps with tags.

To use wrap-region, make sure that this file is in Emacs load-path:
  (add-to-list 'load-path "/path/to/directory/or/file")

Then require wrap-region:
  (require 'wrap-region)

To start wrap-region:
  (wrap-region-mode t) or M-x wrap-region-mode

If you only want wrap-region active in some mode, use hooks:
  (add-hook 'ruby-mode-hook 'wrap-region-mode)

Or if you want to activate it in all buffers, use the global mode:
  (wrap-region-global-mode t)

To wrap a region, select that region and hit one of the punctuation
keys. In "tag-modes"" (see `wrap-region-tag-active-modes'), "<" is
replaced and wraps the region with a tag. To activate this behavior
in a mode that is not default:
  (add-to-list 'wrap-region-tag-active-modes 'some-tag-mode)

`wrap-region-table' contains the default punctuations
that wraps. You can add and remove new wrappers by using the
functions `wrap-region-add-wrapper' and
`wrap-region-remove-wrapper' respectively.
  (wrap-region-add-wrapper "`" "'")                  ; hit ` then region -> `region'
  (wrap-region-add-wrapper "/*" "*/" "/")            ; hit / then region -> /*region*/
  (wrap-region-add-wrapper "$" "$" nil 'latex-mode)  ; hit $ then region -> $region$ in latex-mode
  (wrap-region-remove-wrapper "(")
  (wrap-region-remove-wrapper "$" 'latex-mode)

Some modes may have conflicting key bindings with wrap-region. To
avoid conflicts, the list `wrap-region-except-modes' contains names
of modes where wrap-region should not be activated (note, only in
the global mode). You can add new modes like this:
  (add-to-list 'wrap-region-except-modes 'conflicting-mode)
