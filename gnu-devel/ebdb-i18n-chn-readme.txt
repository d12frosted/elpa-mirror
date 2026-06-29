Bits of code for making EBDB nicer to use with China-based
contacts, both for handling Chinese characters, and for formatting
of phones and addresses.  Be aware that using this library will
incur a non-neglible slowdown at load time.  It shouldn't have any
real impact on search and completion times.

Generic methods don't play nice with autoloads: you'll need to
require this package after installing it.