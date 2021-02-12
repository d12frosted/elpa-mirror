Description: This library use font-locking to change the way Emacs displays
  various latex commands, like \Gamma, \Phi, etc.  It does not actually
  change the content of the file, only the way it is displayed.

Quick start:
  add this file to load path, then (require 'latex-pretty-symbols)


; TODO: The most pressing isue is a way to let not only single symbols be
  displayed, but also strings.  Then we can e.g display "⟨⟨C⟩⟩" instead of
  atldiamond.  Currently the 5 symbols gets placed on top of each other,
  resulting in a mighty mess.  This problem might be demomposed into two
  types: When the replaced string is bigger than the string replacing it
  (probably the easiest case), and the converse case.

  Package it as a elpa/marmelade package.
  --A problem here is that marmelade destroys the unicode encoding. A
  possible fix for this is to change this code, so instead of containing the
  unicode characters directly, it can contain the code for each of them as an
  integer. This would probably be more portable/safe, but in some way less
  userfriendly, as one can not scan through the file to see which symbols it
  has, and to enter one one needs to find the code

  Also it would be nice if it had some configuration possibilities. Eg the
  ability to add own abreviations through the customization interface, or
  toggle the display of math-curly-braces.

  On a longer timeline, it would be nice if it could understand some basic
  newcommands, and automatically deduce the needed unicode (but this seems
  super hard).
