
;;;;;;;;;;;;;;;;;

Table of Contents

[[Quickstart]]
[[Explanation]]
[[Example usage]]
[[See Also]]
[[Prior Art]]
[[Notes]]
[[Bugs]]
[[Compatibility and Requirements]]
[[Todo]]
[[License]]
[[Code]]

;;;;;;;;;;;;;;;;;

[[<Quickstart]]

    (require 'wiki-nav)

    (global-wiki-nav-mode 1)

    Sprinkle double-bracketed [[links]] in your code comments

[[<Explanation]]

Wiki-nav.el is a minor mode which recognizes [[wiki-style]]
double-bracketed navigation links in any type of file, providing
the ability to jump between sections, between files, or open
external links.

Wiki-nav.el requires button-lock.el, which in turn requires
font-lock.el.  Font-lock.el is provided with Emacs.
Button-lock.el is available here

    http://github.com/rolandwalker/button-lock

[[<Example usage]]

    Add the following to your ~/.emacs

        (require 'wiki-nav)
        (global-wiki-nav-mode 1)

    and sprinkle

        [[links]]

    throughout your files.  That's it.  There's more functionality,
    but simple [[links]] may be all you need.

    Clicking a [[link]] will invoke a text search for the next
    matching link.  Double-clicking a link will search for matching
    links in all open buffers.

    Text-matching between links is always case-insensitive.

    To navigate upward to a previous matching link, add a '<'
    symbol before the search text

        [[<links]]

    You can insert the '>' symbol, too, but that simply indicates
    the default forward-search navigation.

    Both forward and backward navigation will wrap around the ends
    of the file without prompting.

    Leading and trailing space inside a link is ignored.

    From the keyboard:

        control-c control-w

                      skip forward in the buffer to the next link

        control-c control-W

                      skip backward in the buffer to the previous link

        return        if positioned on a link, activate it

        tab           if positioned on a link, skip forward in the
                      buffer to the next link of any kind (need not
                      match the current link)

        S-tab         if positioned on a link, skip backward in the
                      buffer to the previous link of any kind (need not
                      not match the current link)

Advanced usage:

    Bracketed links may contain external URLs

        [[http://google.com]]

    Or they may use various internally-recognized URI schemes:

    visit: navigates to another file

        [[visit:/etc/hosts]]

        [[visit:/path/to/another/file:NameOfLink]]

    func: navigates to the definition of a function

        [[func:main]]

    line: navigates to a line number

        [[line:12]]

    visit: may be combined with other schemes:

        [[visit:/path/to/another/file:func:main]]

        [[visit:/etc/hosts:line:5]]

    Path names and similar strings are subjected to URI-style
    unescaping before lookup.  To link a filename which contains a
    colon, substitute "%3A" for the colon character.

    See the documentation for the function wiki-nav for more
    information.

[[<See Also]]

    M-x customize-group RET wiki-nav RET
    M-x customize-group RET nav-flash RET

[[<Prior Art]]

    linkd.el
    David O'Toole <dto@gnu.org>

    org-mode
    Carsten Dominik <carsten at orgmode dot org>

[[<Notes]]

    wiki-nav uses industry-standard left-clicks rather than
    Emacs-traditional middle clicks.

    It is difficult to edit the text inside a link using the
    mouse.  To make a link inactive, position the point after the
    link and backspace into it.  Once the trailing delimiters have
    been modified, the link reverts to ordinary text.

[[<Bugs]]

    Only highlights first match on each comment line.

    Double-square-brackets represent a valid construct in some
    programming languages (especially shell), and may be mistakenly
    linked.  Workaround: don't click.  Second workaround: add mode to
    wiki-nav-comment-only-modes via customize.  Third workaround:
    change delimiters triple-square-brackets via customize.

    Newlines are not escaped in regexp fields in customize.

    Case-sensitivity on matching the delimiters is unknown because
    it depends on how font-lock-defaults was called for the current
    mode.  However, this is not an issue unless the default delimiters
    are changed to use alphabetical characters.

    Auto-complete interacts and causes keyboard interaction
    problems.  Auto-complete should be suppressed if the point is
    on a link?

    Difficult to reproduce: keystrokes sometimes leaking through to
    the editor during keyboard navigation.  Tends to happen on first
    navigation, when key is pressed quickly?

    The global minor mode causes button-lock to be turned off/back
    on for every buffer.

    This package is generally incompatible with interactive modes
    such as `comint-mode' and derivatives, due conflicting uses
    of the rear-nonsticky text property.  To change this, set
    customizable variable wiki-nav-rear-nonsticky.

[[<Compatibility and Requirements]]

    GNU Emacs version 24.5-devel     : not tested
    GNU Emacs version 24.4           : yes
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    Requires button-lock.el

    Uses if present: nav-flash.el, back-button.el

[[<Todo]]

    ido support - document and provide default bindings

    instead of comment-only modes, check if comment syntax is present
    in buffer as is done in fixmee-mode, and use syntax-ppss rather
    than regexp to detect comment context

    support kbd-help property

    follow the doc for defgroup to find link functions which are
    built-in to Emacs

    these and other widgets are used in customize/help
    wiki-nav should reuse the widget functions (wid-edit.el and others)
        emacs-commentary-link
        emacs-library-link
    and the xref functions in help-mode.el

    use a function matcher in font-lock keywords instead of regexp to
    get comment-only matches to work perfectly.  fixmee.el has correct
    code to match in comment

    wiki-nav-external-link-pattern might be replaced with functions
    from url-util

    visit:-1 counts from end of file

    keyboard analog for double-click

    right-click context menu

    link any string <<<text>>> together within a file
    like org-mode radio links

    patch font-lock to support keyword searching in comment only,
    like 'keep, only different - maybe not needed if using a func
    instead of a regexp in keyword

    raised button style option

    break down monolithic dispatch function wiki-nav-action-1

    schemes to add
        search:
        regexp:
        elisp:

    wiki-nav-links can be optimized by tracking which buffers are
    completely fontified - doesn't font-lock do that?

    similarly, speed up wiki-nav-find-any-link by remembering if
    the buffer is fontified, or switch to searching by regexp

    version of wiki-nav-find-any-link that does not wrap

    wiki-nav-ido can only go to one occurrence of a duplicate -
    may not always be first

    toggle key for switching to all buffers within wiki-nav-ido
    prompt

    sort recently-used items first in wiki-nav-ido - see
    yas/insert-snippet for example

[[<License]]

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

[[<Code]]
