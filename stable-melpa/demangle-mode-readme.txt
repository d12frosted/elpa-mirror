`demangle-mode' is an Emacs minor mode that automatically demangles
C++, D, and Rust symbols.  For example, in this mode:

- the mangled C++ symbol `_ZNSaIcED2Ev' displays as
  `std::allocator<char>::~allocator()'

- the mangled C++ symbol `_GLOBAL__I_abc' displays as `global
  constructors keyed to abc'

- the mangled D symbol `_D4test3fooAa' displays as `test.foo'

- the mangled Rust symbol `_RNvNtNtCs1234_7mycrate3foo3bar3baz'
  displays as `mycrate::foo::bar::baz'

See <https://github.com/liblit/demangle-mode#readme> for additional
documentation: usage suggestions, background & motivation,
compatibility notes, and known issues & design limitations.

Visit <https://github.com/liblit/demangle-mode/issues> or use
command `demangle-mode-submit-bug-report' to report bugs or offer
suggestions for improvement.
