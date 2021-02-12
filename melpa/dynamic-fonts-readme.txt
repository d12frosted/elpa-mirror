
Quickstart

    (require 'dynamic-fonts)

    (dynamic-fonts-setup)     ; finds "best" fonts and sets faces:
                              ; default, fixed-pitch, variable-pitch

Explanation

Dynamic-fonts.el makes font configuration more portable between
machines.  When Emacs is starting up, dynamic-fonts chooses fonts
for your basic faces based on which fonts are actually available
on your system.

You may set a list of fonts in order of preference using customize.

See Also

    M-x customize-group RET dynamic-fonts RET
    M-x customize-group RET font-utils RET

Notes

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.3 and lower : no

    Requires font-utils.el

Bugs

    Checking for font availability is slow on most systems.  This
    library can add up to several seconds to startup time.
    Workaround: where supported, font information will be cached
    to disk.  See customization options for font-utils.

TODO

; License

Simplified BSD License:

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

   1. Redistributions of source code must retain the above
      copyright notice, this list of conditions and the following
      disclaimer.

   2. Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials
      provided with the distribution.

This software is provided by Roland Walker "AS IS" and any express
or implied warranties, including, but not limited to, the implied
warranties of merchantability and fitness for a particular
purpose are disclaimed.  In no event shall Roland Walker or
contributors be liable for any direct, indirect, incidental,
special, exemplary, or consequential damages (including, but not
limited to, procurement of substitute goods or services; loss of
use, data, or profits; or business interruption) however caused
and on any theory of liability, whether in contract, strict
liability, or tort (including negligence or otherwise) arising in
any way out of the use of this software, even if advised of the
possibility of such damage.

The views and conclusions contained in the software and
documentation are those of the authors and should not be
interpreted as representing official policies, either expressed
or implied, of Roland Walker.
