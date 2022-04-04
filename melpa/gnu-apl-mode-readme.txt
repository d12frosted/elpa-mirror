Emacs mode for GNU APL

This mode provides both normal editing facilities for APL code as
well as an interactive mode. The interactive mode is started using
the command ‘gnu-apl’.

The mode provides two different ways to input APL symbols. The
first method is enabled by default, and simply binds keys with the
"super" modifier. The problem with this method is that the "super"
modifier has to be enabled, and any shortcuts added by the
operating system that uses this key has to be changed.

The other method is a bit more cumbersome to use, but it's pretty
much guaranteed to work everywhere. Simply enable the input mode
using C-\ (‘toggle-input-method’) and choose APL-Z. Once this mode
is enabled, press "." (period) followed by a letter to generate
the corresponding symbol.
