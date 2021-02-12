
Quickstart

    (require 'hippie-namespace)

    (global-hippie-namespace-mode 1)

    (define-key global-map (kbd "M-/") 'hippie-expand)

    hi [M-/]     ; The first one or two letters of a namespace
                 ; found in the current buffer, followed by the
                 ; key bound to `hippie-expand'.

Explanation

The purpose of hippie-namespace is to save typing.

Enabling this minor mode adds a limited number of very common
prefixes to the `hippie-expand' expansion list.  These prefixes
(deduced from buffer content) will be the first completions
considered.

Furthermore, hippie-namespace completions are treated specially:
when `hippie-expand' proposes a namespace completion, it will not
cycle.  Instead, the namespace completion is implicitly accepted,
and further invocations of `hippie-expand' will build on the
expansion.

For example, the common prefix of all symbols in this library is
"hippie-namespace-".  If, while editing this library, the user
types "hi [hippie-expand]" or even just "h [hippie-expand]",
the full prefix is expanded.

"hi [hippie-expand] [hippie-expand] ..." will then cycle through
all completions which match the prefix.

To use this library, install the file somewhere that Emacs can find
it and add the following to your ~/.emacs file

    (require 'hippie-namespace)
    (global-hippie-namespace-mode 1)

The minor mode will examine each buffer to guess namespace prefixes
dynamically.  If the guess is not good enough, you may add to the
list by executing

    M-x hippie-namespace-add

or by adding a file-local variable at the end of your file:

    ;; Local Variables:
    ;; hippie-namespace-local-list: (namespace-1 namespace-2)
    ;; End:

Note that you should also have `hippie-expand' bound to a key.
Many people override dabbrev expansion:

    (define-key global-map (kbd "M-/") 'hippie-expand)

See Also

    M-x customize-group RET hippie-namespace RET
    M-x customize-group RET hippie-expand RET

Notes

    This mode makes more sense for some languages and less sense for
    others.  In most languages, the declared "namespace" is
    infrequently used in its own context.  (For Emacs Lisp that is
    not the case.)

    Some attempt is made to detect the import of external
    namespaces, and a textual analysis is done, but nothing fancy.

    Integrates with `expand-region', adding an expansion which is
    aware of the namespace and non-namespace portions of a symbol.

    Mode-specific namespace plugins are easy to write.  Search for
    "Howto" in the source.

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    Uses if present: expand-region.el

Bugs

    Breaks using C-u [hippie-expand] to undo.  Workaround: use
    regular undo commands.

TODO

    more and better language-specific functions

    JavaScript namespaces are implicit, and a pain to deduce

    clever interface to support identical subsequences in the
    namespace list

    periodic refresh: idle-timer and save hook?

; License

 Simplified BSD License

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

