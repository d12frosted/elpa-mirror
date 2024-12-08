Run the `fancy-urls-menu-list-urls' command to get the URLs of the current
buffer.  The Fancy URLs Menu provides a way of finding URLs in the
current buffer and opening them in a browser (Emacs EWW, links2, or
something terrible like Firefox).  It is hopefully an improvement
to the ffap-menu of the FFAP package (Find File At Point!  Look it
up, it's legit and not at all a cheeky joke!) and uses the
ffap-menu-rescan at its core.  It derives from
`Tabulated-list-mode', so it is similar in user experience to
`list-buffers', `list-processes', and `list-packages', as all three
derive from `Tabulated-list-mode'.
