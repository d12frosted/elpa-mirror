
`imenu-anywhere` provides navigation for imenu tags across all buffers that
satisfy grouping criteria. Available criteria include - all buffers with the
same major mode, same project buffers and user defined list of friendly mode
buffers.

To activate, just bind `imenu-anywhere' to a convenient key:

   (global-set-key (kbd "C-.") 'imenu-anywhere)

By default `imenu-anywhere' uses plain `completing-read'. `ido-imenu-anywhere',
`ivy-imenu-anywhere' and `helm-imenu-anywhere' are specialized interfaces.

Several filtering strategies are available - same-mode buffers, same-project
buffers and user defined friendly buffers. See
`imenu-anywhere-buffer-filter-functions' and `imenu-anywhere-friendly-modes'.
