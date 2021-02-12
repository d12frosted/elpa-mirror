
Quickstart

    (require 'dired-x)
    (require 'ignoramus)

    (ignoramus-setup)    ; sets `vc-directory-exclusion-list',
                         ; `dired-omit-files', `ido-ignore-directories',
                         ; `completion-ignored-extensions', etc.

    C-x C-j              ; backups and build files now omitted from dired

Explanation

Every library has its own method for defining uninteresting files
to ignore.  Ignoramus puts the listing of ignorable-file patterns
and the logic for applying those patterns together in one place.

To use ignoramus, place the ignoramus.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'ignoramus)
    (ignoramus-setup)

By default, `ignoramus-setup' will apply every action that it
knows about for ignoring files.  Currently these are

    comint
    completions
    dired
    eshell
    grep
    ido
    nav
    pcomplete
    projectile
    shell
    speedbar
    vc

You can specify a shorter list of actions as an argument

    (ignoramus-setup '(pcomplete shell ido))

or customize the value of `ignoramus-default-actions'.

See Also

    M-x customize-group RET ignoramus RET

Notes

Three functions are provided to be called from Lisp:

    `ignoramus-boring-p'
    `ignoramus-register-datafile'
    `ignoramus-matches-datafile'

Compatibility and Requirements

    GNU Emacs version 25.1-devel     : not tested
    GNU Emacs version 24.5           : not tested
    GNU Emacs version 24.4           : yes
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    No external dependencies

Bugs

    The one-size-fits-all approach necessarily makes this library
    a blunt instrument.

    Grep commands may become inconveniently long.

    File names and directory names are conflated.

    Works poorly on built-in completions (eg find-file).

    Overwrites customizable variables from other libraries.

    Hardcoded directory separator.

    Different results may be obtained from the datafile
    functions depending on whether external libraries are
    loaded.

TODO

    Separate variables for directory names.

    Complete eshell action.

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
