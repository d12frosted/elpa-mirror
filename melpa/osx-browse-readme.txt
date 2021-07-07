
Quickstart

    (require 'osx-browse)

    (osx-browse-mode 1)

    ⌘-b      ; browse to URL in foreground
    C-- ⌘-b  ; browse to URL in background

    ⌘-i      ; search Google in foreground
    C-- ⌘-i  ; search Google in background

    ;; position cursor on a URL
    ⌘-b

    ;; select a region
    ⌘-i

    ;; to turn off confirmations
    (setq browse-url-dwim-always-confirm-extraction nil)

Explanation

This package helps Emacs run Safari, Google Chrome, and Firefox
on OS X.  It is similar to the built-in `browse-url', but is
somewhat more friendly and configurable.

The foreground/background behavior of the external browser can
be controlled via customizable variables and prefix arguments.
A positive prefix argument forces foreground; a negative prefix
argument forces background.  With no prefix argument, the
customizable variable setting is respected.

Default values for URLs or search text are deduced from the region
or from context around the point, according to the heuristics in
browse-url-dwim.el.

To use osx-browse, place the osx-browse.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'osx-browse)
    (osx-browse-mode 1)

The following interactive commands are provided:

    `osx-browse-mode'
    `osx-browse-url'
    `osx-browse-search'
    `osx-browse-guess'
    `osx-browse-url-safari'
    `osx-browse-url-chrome'
    `osx-browse-url-firefox'

When `osx-browse-install-aliases' is set (the default) and
`osx-browse-mode' is turned on, aliases are added for the commands

    `browse'
    `google'
    `browse-url-chromium'

See Also

    M-x customize-group RET osx-browse RET
    M-x customize-group RET browse-url-dwim RET
    M-x customize-group RET browse-url RET

Notes

    This library uses browse-url-dwim.el, but does not require that
    `browse-url-dwim-mode' be turned on.  If both modes are turned
    on, keybindings from both modes will be active.

    When `osx-browse-mode' is turned on, `browse-url-browser-function'
    is set to `osx-browse-url', meaning that your default browsing
    facilities will be provided by this library.  `osx-browse-url-safari'
    and friends are provided in the event that you wish to set
    `browse-url-browser-function' by hand.

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    Requires: browse-url-dwim.el

    Uses if present: string-utils.el

Bugs

    `osx-browse-prefer-background' is only respected on
    interactive calls.

    Keybindings don't work out of the box with Aquamacs, which
    does not think that ⌘ is the Super modifier.

    OS X makes an iconified application visible, even when opening
    a URL in the background.

    New-window parameter is not respected, just as in browse-url.el
    Could use AppleScript as follows

        osascript -e 'tell application id "com.apple.Safari" to make new document with properties {URL:"%s"}'

        osascript -e 'tell application id "com.google.Chrome"' -e 'set win to make new window' -e 'set URL of active tab of win to "%s"' -e 'end tell'

        there should be a similar AppleScript solution for Firefox

TODO

    Respect new-window parameter.

    If new-window worked, could make two universal prefix args
    mean: foreground + new window.

    Examine the process object returned by start-process.

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
