This package provides integration between the `symbol-overlay'
package (which will highlight all instances in the current buffer of
the symbol currently under the cursor) and the `multiple-cursors'
package.  Invoke function `symbol-overlay-mc-mark-all' to place a
cursor on every symbol currently highlighted.

If you wish to add this to the transient menu provided by the
`casual-symbol-overlay' package, add the following to your init file:
(with-eval-after-load 'casual-symbol-overlay
  (symbol-overlay-mc-insert-into-casual-tmenu)
