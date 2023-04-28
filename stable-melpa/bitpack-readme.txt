bitdat is similar to the built-in bindat package.  However, this
package can encode IEEE 754 floating point values, both single
(32-bit) and double precision (64-bit).  Requires a 64-bit build of
Emacs.

IEEE 754 NaN have a sign, and this library is careful to store that
sign when packing NaN values.  So be mindful of negative NaN:

http://lists.gnu.org/archive/html/emacs-devel/2018-07/msg00816.html

NaNs are always stored in quiet form (i.e. non-signaling).

Ref: https://stackoverflow.com/a/14955046
