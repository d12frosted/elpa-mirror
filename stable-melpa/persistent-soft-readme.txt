
Quickstart

    (require 'persistent-soft)
    (persistent-soft-store 'hundred 100 "mydatastore")
    (persistent-soft-fetch 'hundred "mydatastore")    ; 100
    (persistent-soft-fetch 'thousand "mydatastore")   ; nil

    quit and restart Emacs

    (persistent-soft-fetch 'hundred "mydatastore")    ; 100

Explanation

This is a wrapper around pcache.el, providing "soft" fetch and
store routines which never throw an error, but instead return
nil on failure.

There is no end-user interface for this library.  It is only
useful from other Lisp code.

The following functions are provided:

    `persistent-soft-store'
    `persistent-soft-fetch'
    `persistent-soft-exists-p'
    `persistent-soft-flush'
    `persistent-soft-location-readable'
    `persistent-soft-location-destroy'

To use persistent-soft, place the persistent-soft.el library
somewhere Emacs can find it, and add the following to your
~/.emacs file:

    (require 'persistent-soft)

See Also

    M-x customize-group RET persistent-soft RET

Notes

    Using pcache with a more recent version of CEDET gives

        Unsafe call to `eieio-persistent-read'.
        eieio-persistent-read: Wrong type argument: class-p, nil

    This library provides something of a workaround.

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.3 and lower : no

    Uses if present: pcache.el (all operations are noops when
    not present)

Bugs

    Persistent-soft is a wrapper around pcache which is a wrapper
    around eieio.  Therefore, persistent-soft should probably be
    rewritten to use eieio directly or recast as a patch to pcache.

TODO

    Setting print-quoted doesn't seem to influence EIEIO.
    It doesn't seem right that the sanitization stuff
    is needed.

    Detect terminal type as returned by (selected-terminal)
    as unserializable.

    Correctly reconstitute cyclic list structures instead of
    breaking them.

    Notice and delete old data files.

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
