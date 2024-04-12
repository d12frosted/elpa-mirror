This uses the httpgd package in R to display R plots within an
Emacs buffer.

Prerequisites

R: You will need to install httpgd from CRAN.  Emacs: This code has
been tested on Emacs 29.2.  It requires a recent version of two
packages: ESS and websocket.  Both of these packages are available
from MELPA.

Your version of Emacs must be compiled with native JSON support.  To check
this, check that the feature JSON is included in the variable
`system-configuration-features'.

Using the code

Load this package and start an R session.  Within an *R* buffer,
or an .R buffer that is linked to a *R* buffer, start the graphics
device using M-x essgd-start.  Plots should then appear in the buffer.
You can navigate through the plot history using p, n keys.  Press
r to refresh the buffer if a plot doesn't appear correctly.  Press
q to quit the buffer and close the R device.

Acknowledgements

Thanks to Florian Rupprecht for help getting started with the httpgd()
device.
