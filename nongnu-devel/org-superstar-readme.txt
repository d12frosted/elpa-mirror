                          ━━━━━━━━━━━━━━━━━━━━
                           ORG-SUPERSTAR-MODE
                          ━━━━━━━━━━━━━━━━━━━━


[https://elpa.nongnu.org/nongnu/org-superstar.svg]
[file:https://melpa.org/packages/org-superstar-badge.svg]
[file:https://stable.melpa.org/packages/org-superstar-badge.svg]

<file:sample_image.png>


[https://elpa.nongnu.org/nongnu/org-superstar.svg]
<https://elpa.nongnu.org/nongnu/org-superstar.html>

[file:https://melpa.org/packages/org-superstar-badge.svg]
<https://melpa.org/#/org-superstar>

[file:https://stable.melpa.org/packages/org-superstar-badge.svg]
<https://stable.melpa.org/#/org-superstar>


1 About
═══════

  Prettify headings and plain lists in Org mode.  This package is a
  direct descendant of ‘[org-bullets]’, with most of the code base
  completely rewritten.  Currently, this package supports:

  ‣ Prettifying Org heading lines by:
    ⁃ replacing trailing bullets by UTF-8 bullets^{a)}
    ⁃ hiding leading stars^{b)}, customizing their look^{(new!)} or
      removing them from vision^{(new!)}
    ⁃ applying a custom face to the header bullet^{d)}
    ⁃ applying a custom face to the leading bullets^{(new!)}
    ⁃ making inline tasks (see `org-inlinetask.el') more fancy by:
      • using double-bullets for inline tasks
      • applying a custom face to the marker star of inline
        tasks^{(new!)}
      • using a special bullet for the marker star^{(new!)}
      • introducing an independent face for marker stars^{(new!)}
    ⁃ (optional) using special bullets for `TODO' keywords^{(new!)}
  ‣ Prettifying Org plain list bullets^{(new!)} by:
    ⁃ replacing each bullet type (`*', `+' and `-') with UTF-8
      bullets^{c)}
    ⁃ applying a custom face to item bullets
  ‣ Gracefully degrading features when viewed from terminal

  a) These features are mostly the same as in `org-bullets-mode'.

  b) Plain hiding is now left to Org mode and the associated variable
  `org-hide-leading-stars' as well as `org-hide', as suggested by
  [Kaligule].

  c) `org-superstar-mode' tries to prettify in a context-sensitive
  fashion: It strives to only recognize item bullets which are really
  *meant* to be item bullets.  Your `SRC' blocks are safe!

  d) Instead of providing the symbol of an existing face in a variable
  to replace Org's usual title face(s) for the UTF-8 character,
  superstar merges a custom face with the face that would have been
  used, allowing the user to inherit the level-dependent default look.


[org-bullets] <https://github.com/sabof/org-bullets>

[Kaligule] <https://github.com/Kaligule>

1.1 Planned features
────────────────────

  There are currently no new features planned. For the time being only
  one historically planned feature remains listed, which is supposed to
  develop into a sister project.  See below.

  +hiding leading commas of quoted stars+
        +unhiding commas whilst editing+
              I have realized that this feature exceeds the scope of the
              package, being too interactive.  This would require a lot
              of font-lock related boilerplate which I am currently in
              the process of dedicating its own package to.
              Update
                    The package in question has matured, but suffers
                    from intricate timing errors which will require
                    looking into.  Especially since they are so far
                    impossible to test reliably due to their nature.


1.2 Demos
─────────

  You can find a small demo reel with a variety of configurations
  [here].


[here] <file:DEMO.org>


2 Installation
══════════════

  The package is available on [NonGNU ELPA] and [MELPA]!

  Furthermore, it ships with [Spacemacs].

  If you prefer a manual installation, just plug `org-superstar.el' into
  your load path and add the following to your `.emacs':
  ┌────
  │ (add-hook 'org-mode-hook (lambda () (org-superstar-mode 1)))
  └────


[NonGNU ELPA] <https://elpa.nongnu.org/nongnu/org-superstar.html>

[MELPA] <https://melpa.org/#/org-superstar>

[Spacemacs] <https://github.com/syl20bnr/spacemacs>


3 Customization
═══════════════

  A variety of customization features has been added to allow further
  tweaking.  Suggestions are always welcome!

  *NOTE:* Many of the variables listed below require you to restart
  `org-superstar-mode' to take effect.  See the corresponding variable's
  documentation.


3.1 "Can you make it more like `org-bullets'?"
──────────────────────────────────────────────

  Naturally!  In fact, I made the answer to this its own function:


3.1.1 `org-superstar-configure-like-org-bullets'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This function configures `superstar-mode' to be as similar to
  `org-bullets' as possible.  Since this function automatically sets
  various custom variables, it should only be called *once* per session,
  before any other (manual) customization of this package.

  `org-superstar-configure-like-org-bullets' is only meant as a small
  convenience for people who just want minor departures from
  `org-bullets-mode'.  For a more fine-grained customization, it's
  better to just set the variables you want.


3.2 "Where do I find UTF8-bullets to use?"
──────────────────────────────────────────

  While it strongly depends on the font(s) you are using which
  characters are going to be supported, here are some nifty Unicode
  blocks to consider.  I sorted them by the respective Unicode plane.

  Basic Multilingual Plane (U+0000-U+FFFF)
        As the name suggests, the Unicode plane containing most
        languages, and hence the most commonly encoded.  I recommend the
        following blocks:
        [General Punctuation] (U+2000-U+206F)
              Bullets, leaders, asterisms.
        [Dingbats] (U+2700-U+27BF)
              Common typesetting ornaments.
        [Geometric Shapes] (U+25A0-U+25FF)
              Circles, shapes within shapes, etc.
        [Miscellaneous Symbols] (U+2600–U+26FF)
              Smileys and card suits.
        [Miscellaneous Symbols and Arrows] (U+2B00-U+2BFF)
              Further stars and arrowheads, polygons, etc.
  Supplementary Multilingual Plane (U+10000-U+1FFFF)
        This one contains (among other things) Emoji and plenty of
        symbols.
        [Ornamental Dingbats] (U+1F650-U+1F67F)
              A few more ornaments, some quotation marks and fancy
              ampersands.
        [Geometric Shapes Extended] (U+1F780-U+1F7FF)
              Even more geometric shapes and shapes within shapes, but
              also asterisk variations.
        [Supplemental Arrows-C] (U+1F800-U+1F8FF)
              A collection of chunky arrows.


[General Punctuation]
<https://en.wikipedia.org/wiki/General_Punctuation>

[Dingbats] <https://en.wikipedia.org/wiki/Dingbat#Unicode>

[Geometric Shapes]
<https://en.wikipedia.org/wiki/Geometric_Shapes_(Unicode_block)>

[Miscellaneous Symbols]
<https://en.wikipedia.org/wiki/Miscellaneous_Symbols>

[Miscellaneous Symbols and Arrows]
<https://en.wikipedia.org/wiki/Miscellaneous_Symbols_and_Arrows>

[Ornamental Dingbats]
<https://en.wikipedia.org/wiki/Ornamental_Dingbats>

[Geometric Shapes Extended]
<https://en.wikipedia.org/wiki/Geometric_Shapes_Extended>

[Supplemental Arrows-C]
<https://en.wikipedia.org/wiki/Supplemental_Arrows-C>


3.3 Custom UTF8-bullets for heading lines
─────────────────────────────────────────

  Here's how you change which bullets are used for which level.


3.3.1 `org-superstar-headline-bullets-list'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Those of you familiar with `org-bullets' will recognize this list:
  It's a list of single-character strings where the /Nth/ entry is used
  to determine the bullet used for heading level /N/.  By default, this
  list is cycled through for /N/ greater than the length of the list.
  Strings are not the only valid way to provide headline bullets,
  however.  Since version *1.3.0*, this variable also recognizes
  characters as well as specific lists, with characters being the new
  default way of providing bullets.  Lists on the other hand provide the
  user with the means to access advanced composition features and
  fallback options for terminal users.  Since version *1.5.0*, a value
  of `nil' is also recognized, causing the headline bullet to be hidden
  from view the same way leading stars are when setting
  `org-superstar-remove-leading-stars'.


3.3.2 `org-superstar-cycle-headline-bullets'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This variable gives you more control over how `superstar-mode' picks
  headline bullets.  The default, `t', cycles through the list as
  explained above.  Other values are:

  `nil'
        Go through the list, then repeat the last entry indefinitely.
  any positive integer /k/
        Cycle through the first /k/ elements of the list.
  any negative integer /k/
        Cycle through the last -/k/ elements of the list.


3.3.3 `org-superstar-leading-bullet'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Maybe you actually /like/ that Org's heading lines are connected to
  the left margin, but you find a line of stars too visually busy?
  Enter `org-superstar-leading-bullet'.  Provide a character of your
  choice to be displayed instead.  Strings are superimposed according to
  the rules of `compose-region'.  `org-superstar' ships with a subtle
  [leader] as the default.

  *Note for terminal users:* You can apply a simplified composition to
  leading stars for terminal sessions.  See
  `org-superstar-leading-fallback' for details.


[leader] <https://en.wikipedia.org/wiki/Leader_(typography)>


3.3.4 `org-superstar-first-inlinetask-bullet'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This bullet replaces the red star inline tasks use when
  `org-inlinetask-show-first-star' is non-nil.  Strings are superimposed
  according to the rules of `compose-region', characters render as
  expected.

  *Note for terminal users:* You can apply a simplified composition for
  terminal sessions.  See `org-superstar-first-inlinetask-fallback' for
  details.


3.3.5 Hide leading stars
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Since `org-mode' already takes care of hiding leading stars by
  providing the dedicated variable `org-hide-leading-stars' and its
  associated face `org-hide', there is no extra option for /hiding/
  leading stars like that.  Instead, `org-hide-leading-stars' implicitly
  disables further fontification.

  While there is no explicit feature for hiding leading stars, you can
  also use `org-superstar-leading-bullet' to hide leading stars
  independently of `org-hide': Simply choose a space character as your
  leading bullet.

  ┌────
  │ ;; This is usually the default, but keep in mind it must be nil
  │ (setq org-hide-leading-stars nil)
  │ ;; This line is necessary.
  │ (setq org-superstar-leading-bullet ?\s)
  │ ;; If you use Org Indent you also need to add this, otherwise the
  │ ;; above has no effect while Indent is enabled.
  │ (setq org-indent-mode-turns-on-hiding-stars nil)
  └────

  If you want to get rid of the indentation caused by leading stars
  entirely, set `org-superstar-remove-leading-stars' to `t'.


3.3.6 Fancy `TODO' items
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can substitute standard headline bullets with specialized ones
  fitting the current `TODO' keyword!  To enable this feature, set
  `org-superstar-special-todo-items' to `t'.  To set which `TODO'
  keywords you want to have displayed differently, see
  `org-superstar-todo-bullet-alist'.


3.3.7 No `TODO' bullets
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you prefer a more minimal look for `TODO' items, try setting
  `org-superstar-special-todo-items' to the symbol `hide'.  This causes
  the heading bullet to disappear entirely for `TODO' items.


3.4 Custom UTF8-Bullets for plain lists
───────────────────────────────────────

  Why stop at heading lines?  Customize the look of your list bullets to
  make plain lists a little less so.


3.4.1 `org-superstar-item-bullet-alist'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Since the concept of "levels" does not really apply to lists, this
  association list simply assigns a UTF-8 character to each of the three
  possible bullet characters for plain Org lists.


3.4.2 `org-superstar-prettify-item-bullets'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Exactly as it says on the tin.  Set this variable to `nil' to stop
  `org-superstar-mode' from prettifying lists.  If set to the symbol
  `only', this disables prettifying Org headings entirely.  As of
  version *1.6.0*, ordered list bullets can be customized with an
  independent face, but are not otherwise prettified.


3.4.3 Fast plain list items
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The default syntax-checking done to ensure only actual plain list
  items are prettified is rather expensive, but usually not expensive
  enough to cause significant slowdown.  This can change when dealing
  with Org files containing hundreds or even thousands of plain list
  items.  The command `org-superstar-toggle-lightweight-lists' allows
  the user to disable syntax checking for plain lists both interactively
  and in code.  For example, if you experience issues for files with
  more than 100 list items, you could simply add the following to
  `org-mode-hook' instead of a direct call to `org-superstar-mode':

  ┌────
  │ (defun my-auto-lightweight-mode ()
  │   "Start Org Superstar differently depending on the number of lists items."
  │   (let ((list-items
  │ 	 (count-matches "^[ \t]*?\\([+-]\\|[ \t]\\*\\)"
  │ 			(point-min) (point-max))))
  │     (unless (< list-items 100)
  │       (org-superstar-toggle-lightweight-lists)))
  │   (org-superstar))
  │ 
  │ (add-hook 'org-mode-hook #'my-auto-lightweight-mode)
  └────


3.5 Custom faces
────────────────

  These faces allow you to further manipulate the look and feel of
  prettified bullets.


3.5.1 `org-superstar-header-bullet': "Use `org-level-N', but…"
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  A face containing essentially the /difference/ between the default
  heading face for the given level (like `org-level-1') and the bullet.
  This face is completely unspecified by default.  Any property set will
  override the corresponding face property of `org-level-N'.


3.5.2 `org-superstar-leading'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  A face used to display leading stars if
  `org-superstar-prettify-leading-stars' is enabled.


3.5.3 `org-superstar-item'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  A face used to display prettified plain list bullets if
  `org-superstar-prettify-item-bullets' is enabled.


3.5.4 `org-superstar-ordered-item'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  A face used to display prettified ordered list bullets if
  `org-superstar-prettify-item-bullets' is enabled.


3.5.5 `org-superstar-first'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  A face used for the marker star of inline tasks (see the package
  `org-inlinetask', in particular `org-inlinetask-show-first-star'
  instead of the default `org-warning', which it inherits from by
  default.


3.6 Hacking
───────────

  As of version *1.7.0*, Org Superstar exposes a handful of previously
  internal functions as well as dedicated hooks to allow full,
  fine-grained control over the style of headlines.


3.6.1 `org-superstar-prettify-headline-hook'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This hook is run each time Superstar prettifies a headline, not
  counting inline tasks.  Hook functions have access to the same match
  data (see the documentation string) that Superstar functions use,
  allowing the user to manually set text properties as they see fit.


3.6.2 `org-superstar-prettify-inlinetask-hook'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This hook is run each time Superstar prettifies an inline task.  Hook
  functions have access to the same match data (see the documentation
  string of `org-superstar-prettify-headline-hook') that Superstar
  functions use, allowing the user to manually set text properties as
  they see fit.


3.6.3 Accessor functions
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Various functions which used to be internals not meant to be accessed
  by users are now exposed to the user.  These functions rely on the
  match data available to functions in the above hooks.

  `org-superstar-heading-level'
        Simple function computing the level of the heading.
  `org-superstar-hbullet'
        Returns the heading bullet Superstar would use at the current
        heading, taking into account the variety of implemented features
        and settings, including returning fallback options for
        non-graphical displays.
  `org-superstar-lbullet'
        Display-aware accessor for leading bullet character.
  `org-superstar-fbullet'
        Display-aware accessor for the first inline task star.


4 FAQ / Troubleshooting
═══════════════════════

4.1 "Question marks everywhere!  Help!"
───────────────────────────────────────

  Did you enable this mode for example in a terminal session and have
  been greeted by wonky replacement characters like ‘�’ or plain
  question marks in headlines or items?  Try turning
  `org-superstar-mode' off to see what its /supposed/ to be if it is too
  visually broken to recognize.  The fix depends on whether you are
  experiencing this on a graphical or terminal display.


4.1.1 Question mark salad on terminal
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This usually happens because the font of your terminal does not have a
  glyph for a bullet character you are using.  There are two plausible
  fixes:

  1) *Change your terminal font:* Emacs has no control over the font of
     your terminal display.  As a consequence, if you want to keep these
     particular bullets, your best bet is to change the font.  For
     example, the default settings should work out of the box for the
     excellent *DejaVu Sans Mono*.
  2) *Utilize terminal fallback options:* Org Superstar is written with
     terminal users in mind.  Hence you can roll an entirely different
     set of bullets for terminal sessions without much effort.  Leading
     stars have `org-superstar-leading-fallback'.  Headline bullets
     themselves can be declared independently for graphical and terminal
     displays in `org-superstar-headline-bullets-list'.  For example,
     replacing an entry `?◉' with the entry `("◉" ?*)' will make the
     headline bullet that would normally display as ‘◉’ a plain asterisk
     on terminal displays.
  3) *Replace the bullet character altogether:* A valid option, but
     likely not the most desirable.  Check out the documentation for
     more info on how to customize this package.


4.1.2 Borked even in graphical sessions
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  In this case it is all up to your Emacs configuration.  The problem
  remains the fonts available, this time to Emacs.  You can either
  [change your Emacs font] or specify specific fonts for specific
  Unicode character ranges, which is part of Emacs' intricate face
  system.


[change your Emacs font] <https://www.emacswiki.org/emacs/SetFonts>


4.2 "This mode causes significant slowdown!"
────────────────────────────────────────────

  I have looked into the matter [in the past], and from what I
  understand the usual cause of this is relates to a deeper rooted issue
  involving [fonts] and font-lock reliant packages.  I recommend adding
  the following to your `.emacs':
  ┌────
  │ (setq inhibit-compacting-font-caches t)
  └────
  or any more fancy variation thereof.  This variable also holds further
  information regarding what I believe is the cause of the problem.  If
  this should not fix the problem, please consider opening an issue or
  sending me a mail!


[in the past]
<https://github.com/integral-dw/org-superstar-mode/issues/3>

[fonts] <https://github.com/integral-dw/org-superstar-mode/issues/27>

4.2.1 "I experience lag when working with long plain lists!"
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  By default, Org Superstar does expensive syntax checking to ensure
  plain lists are actual plain lists.  This is usually not an issue for
  small files.  However, this may pose a problem when your file contains
  hundreds or thousands of items!  You can deal with this interactively
  using the command `org-superstar-toggle-lightweight-lists'.  See also
  the subsection "*Fast Plain List Items*" above.


4.3 "I get an error when trying to use it."
───────────────────────────────────────────

  This of course should not happen.  If your problem is not listed
  below, please file a bug report!


4.3.1 Unknown function: `org-element-lineage'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This is one of the functions my package relies on missing in older
  versions of Org.  The following hack should circumvent the issue, at
  the cost of the package treating some comments in code blocks as
  lists.  Just put it in your `.emacs' before loading up the package.
  If I messed up and this does not fix the problem, be sure to open an
  Issue!
  ┌────
  │ (setq-default org-superstar-lightweight-lists t)
  │ (defun org-element-lineage (x)
  │   "Mock function for future Org feature."
  │   nil)
  └────


4.4 "What are these weird points in front of heading bullets?"
──────────────────────────────────────────────────────────────

  While Org Bullet mode ships only with a feature to hide leading stars,
  Org Superstar allows you to customize leading stars to still provide
  some visual guidance without causing too much visual noise.  For more
  information on this topic, see the Section *Customization* above, in
  particular the subsections `org-superstar-leading-bullet' and *Hide
  leading stars*.


5 NEWS
══════

5.1 `2025-09-13'
────────────────

  Version *1.7.0* is now available, significantly enhancing
  customization options by providing hooks and exposing previously
  internal functions to the user.  The new version also comes with a
  small number of assorted bug fixes related to the removal of leading
  stars.


5.2 `2025-08-31'
────────────────

  *1.6.0* has been released, adding minor support for numbered lists.
  Many years have passed since my last update, and we have even
  surpassed the 262144 (2^18) downloads milestone.. I hope that you,
  dear reader, find continued enjoyment in this little aesthetics tweak
  to Org.  While I doubt that I will be as active as I was back in 2020,
  Superstar is far from dead! I will continue to support it and am
  slowly working on reducing the amount of open issues.  Thank you all
  so much for your patience.


5.3 `2021-02-16'
────────────────

  *1.5.0* has been released, adding support for hiding TODO item bullets
  as well as specifying a default bullet.  As for the plans for *2.0.0*:
  after lots of deliberation I have come to the conclusion that there is
  no currently scheduled change that would justify a major version
  number change.


6 Announcement Log
══════════════════

6.1 `2021-02-11'
────────────────

  Since I have been asked whether there is a way to extend Superstar to
  other minor modes.  The bad news is: no, not feasibly.  The good news
  is: I have created a comparably simple template for this exact purpose
  for other people to bring a Superstar-like mode to your favorite
  Outline-type of mode: [Superstar Kit]!

  Also: Earlier this month, Superstar has reached over 65536 (2^{16})
  downloads!  Again, thank you!


[Superstar Kit] <https://github.com/integral-dw/superstar-kit>


6.2 `2020-02-02'
────────────────

  *Good news!* The project is reaching an /acceptable/ first draft
  state.  This means I am now preparing getting this package properly
  wrapped up and published on MELPA, with a side goal of trying to also
  be available on ELPA.  My conservative estimate for at least being
  available on MELPA is roughly by the end of this month.


6.3 `2020-02-03'
────────────────

  Everything went better than expected!  The tests seem to cover most
  use cases now, and it seems I have added proper terminal support.


6.4 `2020-02-04'
────────────────

  I set up a pull request, we will see how this goes.


6.5 `2020-02-15'
────────────────

  Version *0.3.0* is out and tagged for your convenience.  I am now
  content enough with the package to "freeze" elements of the API for
  good and move to version *1.0.0* once the pull request is closed.  I
  will keep the "under construction" tags around for the time being,
  however.


6.6 `2020-02-16'
────────────────

  Version *0.4.0* has been released!  You can now associate `TODO'
  keywords with special headline bullets.


6.7 `2020-02-17'
────────────────

  Version *0.5.0* now supports a new kind of way to hide leading
  bullets: Instead of using `org-hide', setting
  `org-superstar-remove-leading-stars' allows you hide them akin to
  emphasis markers (see `org-hide-emphasis-markers').


6.8 `2020-02-26'
────────────────

  Version *1.0.0* has been released!  With this I consider the package
  as ready for use as it gets.  The change primarily means that:
  ‣ I will try my best not to break backwards compatibility.
  ‣ If I conclude that I have to, I will not do it silently.  Instead,
    you can rely on appropriate warnings.
  ‣ Even then, a backwards incompatible change will result it a major
    version number change.


6.9 `2020-03-08'
────────────────

  The package is now available on MELPA!  My sincerest thanks to all the
  people on GitHub and the Org mailing list that helped me along!  I
  would not have managed without you! :)


6.10 `2020-04-01'
─────────────────

  A minor status update.  [We cracked the 500 downloads mark on MELPA!]
  Unbelievable! Thank you all for your support!  Should we reach the
  1-2000 downloads mark by the end of the year, I will consider
  contacting major Emacs releases shipping with org-bullets, such as
  Spacemacs or Doom.

  In other news, version *1.1.0* is now available, providing a few minor
  fixes, as well as a new feature to disable expensive syntax checks for
  plain list items. See the FAQ for more info.


[We cracked the 500 downloads mark on MELPA!]
<https://melpa.org/#/org-superstar>


6.11 `2020-04-14'
─────────────────

  Version *1.2.0* is now available.  This version adds support for using
  advanced features of `compose-region' for TODO item bullets.

  Also, the package's downloads doubled in less than two weeks, meaning
  Org Superstar now has [over 1000 downloads on MELPA]!  I have given
  the whole situation some more thought, and decided that I will contact
  the Spacemacs team should we reach 2000 downloads this year, which I
  would consider enough proof of the package's popularity.


[over 1000 downloads on MELPA] <https://melpa.org/#/org-superstar>


6.12 `2020-08-08'
─────────────────

  Version *1.3.0* is here!  This version adds support for using advanced
  features of `compose-region' for headline bullets, thus continuing
  efforts to make the package more visually coherent for general setups
  while remaining terminal friendly.

  In other news, Org Superstar reached [over 16000 downloads on MELPA]!
  This is absolutely insane, and already surpasses my hopes for this
  year by more than a factor of 8!  I am speechless.  And, as promised,
  +I will contact the Spacemacs team sometimes this year.+ Turns out,
  Org Superstar [replaced Org Bullets] as of the 7th of June on
  Spacemacs' `develop' branch!  And it also ships with [Doom Emacs]!
  With that, I have essentially reached every goal I had for this
  package.  However, I will naturally continue maintenance and remain
  open towards feature suggestions.


[over 16000 downloads on MELPA] <https://melpa.org/#/org-superstar>

[replaced Org Bullets]
<https://github.com/syl20bnr/spacemacs/issues/13831>

[Doom Emacs] <https://github.com/hlissner/doom-emacs>


6.13 `2020-08-29'
─────────────────

  org-superstar has reached over 32768 (2^{15}) downloads this week!
  This is absolutely amazing.  If there is any room for improvement, I'm
  very open to suggestions from the community!


6.14 `2020-08-18'
─────────────────

  We have reached version *1.4.0*, which concludes the series of feature
  updates I have planned out.  In other words, this package has reached
  a point of maturity where I would consider it complete.  This does
  /not/ mean that no new features will be added/accepted, but it does
  mean that I will from now on rely on feature suggestions from the
  community, and focus on maintenance rather than innovation.  The next
  scheduled update (*2.0.0*) will likely involve a subtle revamp of the
  default values.  I will keep you posted.
