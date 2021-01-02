powershell.el is a combination of powershell.el by Dino Chiesa
<dpchiesa@hotmail.com> and powershell-mode.el by Frédéric Perrin
and Richard Bielawski.  Joe Schafer combined the work into a single
file.

; Frédéric Perrin Comments:

The original powershell-mode.el was written from scratch, without
using Vivek Sharma's code: it had issues I wanted to correct, but
unfortunately there were no licence indication, and Vivek didn't
answered my mails.

; Rick Bielawski Comments 2012/09/28:

On March 31, 2012 Frédéric gave me permission to take over support
for powershell-mode.el.  I've added support for multi-line comments
and here-strings as well as enhancement/features such as: Functions
to quote, unquote and escape a selection, and one to wrap a
selection in $().  Meanwhile I hope I didn't break anything.

Joe Schafer Comments 2013-06-06:

I combined powershell.el and powershell-mode.el.  Since
powershell.el was licensed with the new BSD license I combined the
two files using the more restrictive license, the GPL.  I also
cleaned up the documentation and reorganized some of the code.
