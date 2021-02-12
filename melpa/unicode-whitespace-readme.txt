
Quickstart

    (require 'unicode-whitespace)

    (unicode-whitespace-setup 'subdued-faces)

    M-x whitespace-mode RET

Explanation

Unicode-whitespace makes the built-in `whitespace-mode' Unicode-aware
in two different ways:

    1. Recognizing Unicode whitespace characters in your buffer,
       such as "No-Break Space" or "Hair Space".

    2. Displaying Unicode characters such as "Paragraph Sign"
       (pilcrow) in place of whitespace.

This library also makes some minor adjustments to the default
settings of `whitespace-mode', and exposes character-by-character
display substitution mappings in customize.

To use unicode-whitespace, place the unicode-whitespace.el library
somewhere Emacs can find it, and add the following to your ~/.emacs
file:

    (require 'unicode-whitespace)
    (unicode-whitespace-setup 'subdued-faces)  ; 'subdued-faces is optional

Then invoke `whitespace-mode' as usual.

The display of newlines is changed from the default.  Newlines are
not displayed unless one of the following conditions is met:

    1. `truncate-lines' is non-nil

    2. `word-wrap' is non-nil

    3. The major mode of the buffer is listed in
       `unicode-whitespace-newline-mark-modes'.

A new `whitespace-style' is provided: 'echo causes the name of the
whitespace character under the point to be displayed in the echo
area.  This is not enabled by default.

Two interactive commands are provided to manipulate these settings
when `whitespace-mode' is active:

    `unicode-whitespace-toggle-newlines'
    `unicode-whitespace-toggle-echo'

See Also

    M-x customize-group RET unicode-whitespace RET
    M-x customize-group RET whitespace RET

Notes

    If the extended characters used to represent whitespace do
    not display correctly on your system, install unicode-fonts.el
    and/or read the setup tips therein.

    Be aware when setting customizable variables for `whitespace-mode'
    that unicode-whitespace works by overwriting those same variables.

    Unicode-whitespace causes alternative line terminators such as
    "Line Separator" to visually break lines so long as
    `whitespace-mode' is on.  Extra newline characters are not
    inserted.  This is a visual effect only, which ceases when
    `whitespace-mode' is turned off.

    Unicode-whitespace turns off the long-line indicators built
    into whitespace-mode because of a font-lock bug.  To reverse
    this, do

        (add-to-list 'whitespace-styles 'lines)

    or use a separate long-lines detection package.

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.3 and lower : no

    Requires ucs-utils.el

    Uses if present: unicode-fonts.el

Bugs

    Gray faces won't look good on a gray background such as that
    used by Zenburn color theme.  Does Zenburn set background to
    light or dark?  Provide a way to force faces?

    The face for alternative line terminators is often incorrect;
    font-lock overrides the settings from unicode-whitespace.  This
    is because `whitespace-display-char-on' hardcodes \n as the
    line terminator.

    Calling alternative line terminators 'space-mark is a hack to
    make it possible to toggle display of standard newlines
    without affecting the alternates.  They really should all be
    called newline-mark.  whitespace.el could be updated to
    allow this.

    Trailing space that ends with \r or \f sometimes does not get
    fontified -- though it usually get picked up after some
    typing.  This could be because of some assumptions in the
    post-command-hook of whitespace.el.


TODO

    There should be separate faces for each of these classes, would
    need to patch or override whitespace.el

        unicode-whitespace-tab-names
        unicode-whitespace-tab-set-names
        unicode-whitespace-soft-space-names
        unicode-whitespace-hard-space-names
        unicode-whitespace-pseudo-space-names
        unicode-whitespace-standard-line-terminator-names
        unicode-whitespace-alternative-line-terminator-names
        form feed

    There are probably more nonprinting characters to include as
    pseudo-spaces by default.  A list of glyphless chars could be
    gotten from variable `glyphless-char-display'.

    Regexps should probably be redone with only \t for certain
    things.

    A whitespace-cycle command could turn on the mode and cycle
    through a few levels of visibility.

    Add a test function that dumps an extended example to scratch
    buffer.

    Consistent marker symbol for thin spaces, and a way to see the
    intersection between thin and nonbreaking - maybe nonbreaking
    should be a consistent face and thin a consistent symbol.

    The tab-visibility bug in whitespace.el could probably be fixed
    with an overlay.  Also, stipple can show tabs as arrows without
    changing display, seen here (http://emacswiki.org/emacs/BlankMode).
    However, the stipple face is dependent on frame-char-width/height.

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
