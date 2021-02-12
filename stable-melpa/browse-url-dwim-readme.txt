
Quickstart

    (require 'browse-url-dwim)

    (browse-url-dwim-mode 1)

    place the cursor on a URL
    press "C-c b"

    select some text
    press "C-c g"

    ;; to turn off confirmations
    (setq browse-url-dwim-always-confirm-extraction nil)

Explanation

This small library for calling external browsers combines some of
the functionality of `browse-url' and `thingatpt'.

Three interactive commands are provided:

    `browse-url-dwim'
    `browse-url-dwim-search'
    `browse-url-dwim-guess'

each of which tries to extract URLs or meaningful terms from
context in the current buffer, and prompts for input when unable
to do so.

The context-sensitive matching of `browse-url-dwim' tries to do
_less_ overall than the default behavior of `thingatpt', on the
theory that `thingatpt' matches too liberally.  However,
`browse-url-dwim' does recognize some URLs that the default
`browse-url' ignores, such as "www.yahoo.com" without the
leading "http://".

To use `browse-url-dwim', add the following to your ~/.emacs file

    (require 'browse-url-dwim)      ; load library
    (browse-url-dwim-mode 1)        ; install aliases and keybindings

Then place the cursor on a URL and press

    C-c b                           ; b for browse

or select some text and press

    C-c g                           ; g for Google

or (equivalently)

    M-x browse RET
    M-x google RET

Outside the USA

If you are outside the USA, you will want to customize
`browse-url-dwim-permitted-tlds' so that your favorite
top-level domains will be recognized in context.  You
may also wish to customize `browse-url-dwim-search-url'
to point at an appropriate search engine.

See Also

    M-x customize-group RET browse-url-dwim RET
    M-x customize-group RET browse-url RET

Notes

To control which browser is invoked, see the underlying library
`browse-url'.

By default, the minor mode binds and aliases `browse-url-dwim-guess'
for Internet search, but the user might prefer to bind
`browse-url-dwim-search', which has less DWIM:

    (define-key browse-url-dwim-map (kbd "C-c g") 'browse-url-dwim-search)

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    Uses if present: string-utils.el

Bugs

    `thing-at-point-short-url-regexp' requires at least two dots in the hostname,
    so "domain.com" cannot be detected at point, whereas the following will be:
    "www.domain.com" or "http://domain.com"

    `url-normalize-url' doesn't do much.  Multiple slashes should be removed
    for a start.

TODO

    Support thing-nearest-point, with fallback.

    Test various schemes, esp "file:", "mailto:", and "ssh:".

    Extract multiple URLs from region and browse to all.

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
