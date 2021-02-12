
In scientific literature, it is common to format the symbols for
chemical elements, molecules and unit names by using roman (as
opposed to italic) letters for the names.  This makes such things
cumbersome to type, because one would have to do either
$\mathrm{H_2O}$ or H$_2$O.  This package make this typing easier by
providing the function mu2tex.  This function converts plain
ASCII molecule names and unit expressions into either of the above
forms.  It also makes it easier to write numbers times powers of 10.

INSTALLATION
------------
Put this file on your load path, byte compile it (not required),
and copy the following code into your .emacs file.  Change the key
definition to your liking.

  (autoload 'mu2tex "mu2tex"
    "Insert constants into source code" t)
  (define-key global-map "\C-cm" 'mu2tex)

USAGE
-----

To use this package, just type the name of a molecule or a unit
expression into the buffer.  The expression must not contain
spaces.  Then, with the cursor right after the types expression,
press the key to which mu2tex has been assigned.

Example              Conversion result
-----------------    -----------------
H2O                  H$_2$O
C18O                 C$^18$O
H2C17O               H$_2$C$^17$O
m2s-2                m$^2$ s$^{-2}
2.74e-13             $2.74\times10^{-13}$

A dot can be used as a separator where one is needed:

H2.18O               H$_2${}$^{18}$O
erg.cm-2s-1          erg cm$^{-2}$ s$^-1$
2.7e-2Jy.arcsec-2    $2.7\times10^{-2}$ Jy arcsec$^-2$

The dot can also be used to force interpretation of a number as either
isotope number or stoichiometric number.  By default, mu2tex assumes
that numbers smaller than 10 are stoichiometric coefficients that need
to be turned into a subscript, and numbers 10 and larger are isotope
numbers that need to become superscripts.  In the cases where this
heuristics fails, you can use the dot to force assignment to left or
right and in this way break the ambiguity:

H.6Li                H{}$^{6}$Li
C18.H                C$_{18}$H

Inside (La)TeX math mode, a different conversion is needed.  In this
case, the resulting string should be put into a \mathrm macro, to get
the correct fonts, and no $ characters are needed to switch mode.
If you have the texmathp.el package, recognition of the environment will
be automatic.  If you don't, you can use the command `mu2tex-math' to
get the math-mode version of the conversion.

CUSTOMIZATION
-------------
You can use the following variables to customize this mode:

mu2tex-use-mathrm
   Do you prefer $\mathrm{H_2O}$ or H$_2$O in math mode?

mu2tex-use-texmathp
   Should texmathp.el be used to determine math or text mode?

mu2tex-isotope-limit
   Numbers larger than or equal to this are interpreted as isotope numbers.

mu2tex-molecule-exceptions
   Special molecules for which the automatic converter fails.

mu2tex-units
   Units that can be used to distinguish a unit expression from a molecule.

mu2tex-space-string
   What should be inserted as separator between different units?

Heuristics, and fixes where needed
----------------------------------
- Mu2tex uses a heuristic method to decide if the expression to convert
  is a unit expression or a molecule name.  This method is based on a
  built-in list of unit names that never show up in molecule names.
  This list (stored in the constant `mu2tex-default-units') may or may not
  work for you.  See the variable `mu2tex-units'.  Also, an initial
  floating point number containing a decimal point or exponent does force
  unit interpretation.  You can call `mu2tex' with single C-u prefix to
  force interpretation as a molecule name.  A double prefix C-c C-u enforces
  interpretation as a unit expression.  Finally, you can also use the
  special commands `mu2tex-unit' and `mu2tex-molecule'.

- If you have specific molecules that you need often and that defy the
  heuristics for isotope numbers and stoichiometric coefficients, you
  can simply hard-code the conversion for these molecules using the
  variable `mu2tex-molecule-exceptions'.  For example:

       (setq mu2tex-exceptions
             '((\"HC18H\" . \"HC$_{18}$H\")
               (\"H6Li\"  . \"H$^{6}$Li\")))


AUTHOR
------
Carsten Dominik <dominik@.uva.nl>

ACKNOWLEDGEMENTS
----------------
Cecilia Ceccarelli made me write papers about chemistry, and in this way
prompted this program.  She also had the idea for the unit formatter.

CHANGES
-------
Version 1.0
- Initial release
Version 1.1
- Add formatting of numbers
Version 1.2
- Allow point to force isotope/stoichiometric assignment like C18.H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
