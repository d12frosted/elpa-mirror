Uses ``curl`` as its backend or Emacs's native ``url.el`` library if
``curl`` is not found.

The default encoding for requests is ``utf-8``.  Please explicitly specify
``:encoding 'binary`` for binary data.
