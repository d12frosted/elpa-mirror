At the time of this writing, the closest thing that Emacs had to
adding machine functionality is the `calc' "trail" window (see
variable `calc-display-trail'), with all its oddities, benefits,
and drawbacks. Other methods required either: 1) selecting a
rectangle of numbers and sending it to 'calc' for that package to
use internally in its own dedicated buffer; 2) transforming a
rectangle of numbers (and possibly their annotations) into an
'org-mode' table and having that package handle it.

This package provides an easy-to-use tape calculator functionality
natively and intuitively IN ANY BUFFER. You can use it to sum an
existing column of numbers, without even having to select the
entire region, and even if the numbers are badly aligned. You can
use it to create a "tape" in any writable buffer, include
annotations for each line, and "live-edit" a pre-existing tape. The
package auto-aligns its tapes, supports memory operations, performs
VAT / sales tax calculations, and seamlessly handles integers,
floats, and scientific notation on the same tape.

As a sneaky bonus, a wrapper function to Emacs `quick-calc' is
provided for outputting numbers with thousands delimiters.

