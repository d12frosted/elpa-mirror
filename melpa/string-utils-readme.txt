
Quickstart

    (require 'string-utils)

    (string-utils-squeeze-filename (buffer-file-name (current-buffer)) 20)

    (string-utils-stringify-anything (selected-frame))

    (progn
      (message (string-utils-pad (buffer-name (current-buffer)) (window-width) 'right))
      (sit-for 1)
      (message (string-utils-pad (buffer-name (current-buffer)) (window-width) 'center))
      (sit-for 1)
      (message (string-utils-pad (buffer-name (current-buffer)) (window-width) 'left))
      (sit-for 1))

Explanation

String-utils is a collection of functions for string manipulation.
This library has no user-level interface; it is only useful
for programming in Emacs Lisp.

The following functions are provided:

    `string-utils-stringify-anything'
    `string-utils-has-darkspace-p'
    `string-utils-has-whitespace-p'
    `string-utils-trim-whitespace'
    `string-utils-compress-whitespace'
    `string-utils-string-repeat'
    `string-utils-escape-double-quotes'
    `string-utils-quotemeta'
    `string-utils-pad'
    `string-utils-pad-list'
    `string-utils-propertize-fillin'
    `string-utils-plural-ending'
    `string-utils-squeeze-filename'
    `string-utils-squeeze-url'
    `string-utils-split'
    `string-utils-truncate-to'

To use string-utils, place the string-utils.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'string-utils)

Notes

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    Uses if present: list-utils.el, obarray-fns.el

Bugs

    (defun string-utils-test-func nil "doc" (keymap 95))
    (string-utils-stringify-anything (symbol-function 'string-utils-test-func))

    Some objects such as window-configuration are completely
    opaque and won't be stringified usefully.

TODO

    Stringification of autoload data type
        http://www.gnu.org/software/emacs/manual/html_node/elisp/Autoload-Type.html

    Maybe args should not be included when stringifying lambdas and
    macros.

    In string-utils-propertize-fillin, strip properties which are
    set to nil at start, which will create more contiguity in the
    result.  See this example, where the first two characters have
    the same properties

        (let ((text "text"))
          (add-text-properties 0 1 '(face nil) text)
          (add-text-properties 2 3 '(face error) text)
          (string-utils-propertize-fillin text 'face 'highlight)
          text)

     String-utils-squeeze-url needs improvement, sometimes using
     two elisions where one would do.

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
