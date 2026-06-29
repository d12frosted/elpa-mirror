Commentary:

When I write small programs to calculate something, I often need
the values of some physical constants and units.  I could of course
always link a big module with all those definitions.  But often I
want the program to run stand-alone, so I prefer to define
variables for these constants directly.  This package provides the
command `constants-insert'.  It prompts for one or more variable
names and inserts definition statements for numerical constants
into source code.  It does this in the appropriate syntax for many
different programming languages.
There are also the commands `constants-get' and `constants-replace'
which just display the value of a constant in the echo area, or replace
the name of a constant in a buffer with its value.

The package knows many constants and units, both in the SI and in
the cgs unit system.  It also understands the usual unit prefixes
(like "M" for Mega=10^6 or "m" for milli=10^-3).  So the built-in
constant "pc" (parsec, an astronomical distance), can also be used
in kpc (1000 pc), Mpc (10^6 pc) etc.  For a full list of all
available constants, units, and prefixes, use `M-x constants-help',
or press "?" while the command is prompting for names.

The unit system (SI or cgs) can be selected using the option
`constants-unit-system'.  Additional constants or units can be
defined by customizing `constants-user-defined'.  You can tell the
package to use different names for some of the constants (option
`constants-rename'), and you may also specify a different variable
name on the fly (see "Mlunar" in the example below).

The code inserted into the buffer is mode dependent.  Constants.el
has defaults for some programming languages: FORTRAN, C, IDL,
MATLAB, OCTAVE, PERL, EMACS-LISP, GP.  You can change these
defaults and add definitions for other languages with the variable
`constants-languages'.

INSTALLATION
------------
Put this file on your load path, byte compile it, and copy the
following code into your .emacs file.  Change the key definitions,
variable name aliasing and the unit system to your liking.

  (autoload 'constants-insert "constants" "Insert constants into source." t)
  (autoload 'constants-get "constants" "Get the value of a constant." t)
  (autoload 'constants-replace "constants" "Replace name of a constant." t)
  (define-key global-map "\C-cci" 'constants-insert)
  (define-key global-map "\C-ccg" 'constants-get)
  (define-key global-map "\C-ccr" 'constants-replace)
  (setq constants-unit-system 'SI)   ;  this is the default

  ;; Use "cc" as the standard variable name for speed of light,
  ;; "bk" for Boltzmann's constant, and "hp" for Planck's constant
  (setq constants-rename '(("cc" . "c") ("bk" . "k") ("hp" . "h")))

  ;; A default list of constants to insert when none are specified
  (setq constants-default-list "cc,bk,hp")

USAGE
-----
In a programming mode, call the function and at the prompt enter
for example

   Name[, Name2...}: cc,k,Mlunar=Mmoon,Mpc

In a FORTRAN buffer, this would insert

     doubleprecision cc=2.99792458d8     ! Speed of light [SI]
     doubleprecision k=1.3806503d-23     ! Boltzmann's constant [SI]
     doubleprecision Mlunar=7.35d22      ! Moon mass [SI]
     doubleprecision Mpc=3.085677582d+22 ! Mega-Parsec [SI]

while in a C buffer you would get

     double cc=2.99792458e8;           /* Speed of light [SI] */
     double k=1.3806503e-23;           /* Boltzmann's constant [SI] */
     double Mlunar=7.35e22;            /* Moon mass [SI] */
     double Mpc=3.085677582e+22;       /* Mega-Parsec [SI] */

When entering the names, you can optionally precede a name with
"varname=", in order to change the variable name that will be used
for the definition.  While entering the name of a constant, you can
use completion.  Press `?' during completion to display a detailed
list of all available constants.  You can scroll the Help window
with S-TAB while entering text in the minibuffer.

If you add "si" or "cgs" to the comma-separated list of
constant/unit names, this will switch the unit system for the
burrent buffer and editing session.


CUSTOMIZATION
-------------
The following customization variables are available:

constants-unit-system
  The unit system to be used for the constants (`cgs' or `SI').

constants-rename
  Alist with additional names for some existing constants.

constants-user-defined
  User defined constants.

constants-default-list
  Default constants to insert if none are specified.

constants-languages
  Format descriptions for different major programming modes.

constants-indent-code
  Non-nil means, indent the newly inserted code according to mode.

constants-allow-prefixes
  Non-nil means, interpret prefixes like M (mega) etc.

constants-prefixes
  Allowed prefixes for constants and units.

CONTEXT SENSITIVITY
-------------------
For some languages, it might be usefull to adapt the inserted code
to context.  For example, in Emacs Lisp mode, the default settings
insert "(VARIABLE VALUE)" with surrounding parenthesis for a `let'
form.  However, if you'd like to use this in a `setq' form, the
parenthesis are incorrect.  To customize for such a case, set the
variable `constants-language-function' to a function which returns,
after checking the context, the correct language entry of the form
(MAJOR-MODE FORMAT EXP-STRING PREFIX-EXPRESSION).  For the above
example, you could do this:

  (defun my-constants-elisp-function ()
    "Check context for constants insertion."
    (save-excursion
      (condition-case nil
          (progn (up-list -1)
                 (if (looking-at "(setq\\>")
                     '(emacs-lisp-mode "%n %v%t; %d %u" "e" "(* %p %v)")
                   '(emacs-lisp-mode "(%n %v)%t; %d %u" "e" "(* %p %v)")))
        (error nil))))     ; return value nil means use default

  ;; The variable is buffer-local and must be set in the mode hook.
  (add-hook 'emacs-lisp-mode-hook
            (lambda ()
              (setq constants-language-function
                    'my-constants-elisp-function)))

BUGS
----
- Completion does not consider prefixes.  For example, you cannot
  complete "MGa" to "MGauss" (meaning "Mega-Gauss").  This was not
  implemented because it would cause too many matches during
  completion.  But you can still use completion for this by separating
  the prefix from the unit with a star:  After typing "M*Ga", completion
  will work and result in "M*Gauss".  Both "MGauss" and "M*Gauss" will
  result in a variable "MGauss" being defined.
- When using cgs units, be very careful with the electric constants
  and units.  This library uses E.S.U., not E.M.U.  Note that the
  *equations* involving charges, currents and magnetism are all
  different for SI, CGS/ESU and CGS/EMU.  So when switching to a
  different system, you must make sure to use the right equations.
- I have tried to implement the cgs units correctly, but I have
  some doubt about the electrical and radiation units.
  Double-check before blindly using these.

AUTHOR
------
Carsten Dominik <carsten.dominik@gmail.com>

Let me know if you are missing a constant in the default setup, if
you notice that a value of a constant is not correct, or if you
would like to see support for another language mode.

ACKNOWLEDGEMENTS
----------------
Thanks to Kees Dullemond.  Watching him writing programs has
inspired this package.

Thanks to the following people for reporting bugs and/or suggesting
features/constants/languages:
Bruce Ignalis, Dave Pearson, Jacques L'helgoualc'h, Federico Beffa

CHANGES
-------
Version 2.10
- Ready for becoming an ELPA package

Version 2.8
- Allow the interactive prompt to change the unit system.  That
  change will be stored locally for the current buffer and editing
  session.

Version 2.7
- Add support for Python

Version 2.5
- Better Lisp indentation (patch by Federico Beffa <beffa@ieee.org>)

Version 2.3
- Add a few more constants

Version 2.0
- New commands `constants-get' and `constants-replace'.

Version 1.8
- Completion now preserves up/downcase as typed.
- Completion with prefixes can be done, by adding a star as in "M*Gauss".
- A different variable name may be specified directly at the prompt with
  the syntax "varname=const".
- Support for shell-like modes like idlwave-shell-mode.
- XEmacs support (fixed a small bug)

TO DO
-----
- Support more programming languages.
- Add expression values tcl and others.
- Add calc mode?
- add these units?
  - g[u]age,
  - (circular) mill
  - ampere-turn
- add a command to get info about a certain variable.  Only useful if
  the variable name really is the constant name.  Not sure if this will
  be used at all, so until someones asks for it, this will not be done.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
