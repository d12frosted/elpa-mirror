A major mode that provides syntax highlighting an indentation for
editing Shakespearean templates (hamlet, lucius, julius).

Currently, this mode support almost all of the features provided
with Shakespeare templates. Most notable (see the README for a complete list):

- Variable interpolation syntax highlighting
  #{..}, @{..}, ^{..}, _{..}, @?{..}
- Control flow statements syntax highlighting
  $if, $forall, $maybe, etc
- Indentation for these modes (mostly derived from their parent modes,
  but it works well).

There are two packages that helped me out greatly while creating this one
that I'd like to give credit to since I borrowed a few line from each
of them (also see the README):

* hamlet-mode (https://github.com/lightquake/hamlet-mode)
* less-css-mode (https://github.com/purcell/less-css-mode)

Submit issues at https://github.com/CodyReichert/shakespeare-mode
or email me directly at cody@reichertbrothers.com.
