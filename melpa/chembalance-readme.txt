
Balance chemical equations.

Installation:

After installing the package (or copying it to your load-path), add this
to your init file:

(require 'chembalance)

It works interactively (entering your equation at the minibuffer) and
also with region.

M-x chembalance => goes to the minibuffer.  Enter equation.
(Ex.  FeS + O2 => Fe2O3 + SO2)

It returns:

=> Balanced reaction : 4 FeS + 7 O2 => 2 Fe2O3 + 4 SO2

You can also use it to check if a reaction is already balanced.

You can mark a region with a chemical equation and then M-x
chembalance.  It will give you the balanced equation.

Chembalance supports formulas with parentheses (Ex: Fe(OH)2)

Customize:

To customize chembalance, do M-x customize-group RET chembalance.

There are two custom variables:

chembalance-arrow-syntax (list of accepted arrows).

chembalance-insert-string (if non-nil, when you call chembalance with
selected region, chembalance will kill that region and insert the
balanced reaction).

Please, email me your comments, bugs, improvements or opinions on
this package to sergi.ruiz.trepat@gmail.com
