This package provides the ability to quickly open a corresponding
file for the current buffer by using a bi-directional mapping of
regular expression pairs. You can select a mapping style from
`toggle-mapping-styles' using the `toggle-style' function or set
your default style via the `toggle-mapping-style' variable.

There are 7 different mapping styles in this version: zentest,
rspec, rails, ruby, objc, c, and cpp. Feel free to submit more and
I'll incorporate them.

; Example Mapping (ruby style):

blah.rb <-> test_blah.rb
lib/blah.rb <-> test/test_blah.rb
