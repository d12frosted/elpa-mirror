
Quickstart

    (require 'flyspell-lazy)

    (flyspell-lazy-mode 1)

    (flyspell-mode 1)      ; or (flyspell-prog-mode)

Explanation

Emacs' built-in `flyspell-mode' has performance issues on some
platforms.  Specifically, keyboard responsiveness may be
significantly degraded on OS X.  See this bug:

    http://debbugs.gnu.org/cgi/bugreport.cgi?bug=2056

This package reduces the amount of work done by flyspell.  Instead
of checking *instantly* as you type, spelling will be checked when
Emacs has been idle for a short time.  (Vanilla `flyspell-mode'
does not use idle timers but a subtle combination of hooks and
`sit-for'.)

This package also forces `flyspell-mode' off completely for certain
buffers.

To use this library, add the following to your ~/.emacs

    (require 'flyspell-lazy)
    (flyspell-lazy-mode 1)

Then use `flyspell-mode' as you normally would.  This package does
not load flyspell for you.

`flyspell-lazy-mode' will invoke spellcheck less frequently than
vanilla `flyspell-mode', though this can be changed somewhat via
`customize'.

See Also

    M-x customize-group RET flyspell-lazy RET
    M-x customize-group RET flyspell RET
    M-x customize-group RET ispell RET

Notes

    If you are using "aspell" instead of "ispell" on the backend,
    the following setting may improve performance:

        (add-to-list 'ispell-extra-args "--sug-mode=ultra")

    If you see the cursor flicker over the region during spellcheck,
    make sure that `flyspell-large-region' is set to 1 (this library
    tries to do that for you), and try adding the following to your
    ~/.emacs

        (defadvice flyspell-small-region (around flyspell-small-region-no-sit-for activate)
          (flyspell-lazy--with-mocked-function 'sit-for t
            ad-do-it))

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

    The longer the delay before checking, the more inaccurate the
    coordinates in `flyspell-changes'.  These are static integers;
    they don't move with updates in the buffer.  To mitigate this
    effect, a second idle timer checks all visible text (at a much
    longer interval).

    Flyspell-lazy-matches-last-text is not reliable - in debug mode
    it can be seen that it sometimes toggles between two states at
    every press of spacebar.  This may be related to generating the
    additional span around the point.

    Flyspell-lazy-refine-changes is sometimes mistakenly scrubbing
    all pending spans.  Check the case where one char is deleted
    inside a word.

TODO

    Let flyspell-issue-message-flag and flyspell-issue-welcome-flag
    to nil wherever needed to improve performance.

    Consider using while-no-input macro.

    Figure out if flyspell-lazy affects suggestions -- must an
    update be forced on the word before running suggestions?

    Force re-check of text after removing comments renders the
    text code again under flyspell-prog-mode.

    Optionally add aspell extra args noted in doc.

    Make flyspell-lazy-single-ispell actually work.  Currently, see
    a new "starting ispell" message for every buffer opened, in
    spite of flyspell-lazy-single-ispell setting.  This comes from
    flyspell-mode calling flyspell-mode-on.

    What would be the ramifications of using a single ispell
    process?  Only loss of per-buffer dictionaries?

    Enforce using a single ispell process on regions larger than
    flyspell-large-region.

    Strip symbols from text - see flyspell-lazy-strip-symbols.

    Heuristic to detect regular expressions and avoid checking
    them as strings.

    Use buffer-undo-list instead of flyspell-changes, then can
    also remove flyspell's after-change hook.

    Use the hints set in prog-mode to avoid checks in the per-word
    and refine stages.

    Hints for commented-out code to avoid checking.

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
