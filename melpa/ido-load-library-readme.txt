
Quickstart

    (require 'ido-load-library)
    M-x ido-load-library RET

Explanation

Ido-load-library is an alternative to `load-library' which
uses `ido-completing-read' for completion against all
available libraries in your `load-path'.

To use ido-load-library, place the ido-load-library.el file
somewhere Emacs can find it, and add the following to your
~/.emacs file:

    (require 'ido-load-library)

The interactive command `ido-load-library' is provided, though
not bound to any key.  It can be executed via

    M-x ido-load-library

or bound via something like

    (define-key global-map (kbd "C-c l") 'ido-load-library)

or safely aliased to `load-library'

    (defalias 'load-library 'ido-load-library)

The interactive command `ido-load-library-find' is also
provided.  Like `ido-load-library', it searches your
`load-path', but instead of loading the selected library,
it visits the file in a buffer.

See Also

    M-x customize-group RET ido-load-library RET
    M-x customize-group RET ido RET

Notes

    Defines the variable `library-name-history' outside of the
    `ido-load-library-' namespace.

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.3 and lower : no

    Uses if present: persistent-soft.el (Recommended)

Bugs

    When invalidating the disk cache, `ido-load-library' only checks
    whether `load-path' has changed, not whether new files were added
    to existing paths.  Workarounds:

        1. Install libraries using ELPA/package.el, in which case this
           assumption always works.
        2. Wait for the cache to expire (7 days).
        3. Give universal prefix argument to `ido-load-library'
           to force invalidation of the cache.

    Should not remove -autoloads and -pkg library names unless there
    is another name found with the same base.

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
