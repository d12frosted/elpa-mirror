
* Installation

To use without using a package manager:

 - Put the library in a directory in the emacs load path, like ~/.emacs.d
 - Add (require 'ess-smart-underscore) in your ~/.emacs file

This is in emacswiki, so this package can also be installed using el-get.

After installing el-get, Type M-x el-get-install ess-smart-underscore.
* Ess-Smart Underscore Package Information
Smart "_" key: insert `ess-S-assign', unless:

  1. in string/comment
  2. after a $ (like d$one_two) (toggle with `ess-S-underscore-after-$')
  3. when the underscore is part of a variable definition previously defined.
     (toggle with `ess-S-underscore-after-defined')
  4. when the underscore is after a "=" or "<-" on the same line.
  5. inside a parenthetical statement () or [].
     (toggle with `ess-S-underscore-when-inside-paren')
  6. At the beginning of a line.
  7. In a variable that contains underscores already (for example foo_a)
     (toggle with `ess-S-underscore-when-variable-contains-underscores')
  8. The preceding character is not a tab/space (toggle with
     `ess-S-underscore-when-last-character-is-a-space'.  Not enabled
     by default.)

An exception to


a <- b |


Pressing an underscore here would produce



a <- b <-


However when in the following situation


a <- b|


Pressing an underscore would produce


a <- b_


This behavior can be toggled by `ess-S-space-underscore-is-assignment'

If the underscore key is pressed a second time, the assignment
operator is removed and replaced by the underscore.  `ess-S-assign',
typically " <- ", can be customized.  In ESS modes other than R/S,
an underscore is always inserted.

In addition the ess-smart-underscore attempts to work with noweb-mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
