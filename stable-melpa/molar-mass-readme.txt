After installing the package (or copying it to your load-path), add this
to your init file:

(require 'molar-mass)

It works interactively (entering your formula at the minibuffer) and
also with region.

M-x molar-mass => goes to the minibuffer.  Enter formula
(Ex.  KMnO4)

It returns:

=> Molar mass of KMnO4  : 158.034 g/mol (uma)

You can mark a region with a formula and it will give you its molar
mass.

Example:

Mark region : H2O
Call M-x molar-mass

=> Molar mass of H2O : 18.015 g/mol (uma)

Molar-mass supports formulas with parentheses (Ex: Fe(OH)2), and it
works in LaTeX sintax (Ex: Fe(OH)_{2}).

You can customize the result's significant decimals (default is 3):
M-x customize-variable > molar-mass-significant-decimals
