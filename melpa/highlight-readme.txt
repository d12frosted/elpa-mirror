
   Highlighting commands.

   More description below.

(@> "Index")

 Index
 -----

 If you have library `linkd.el' and Emacs 22 or later, load
 `linkd.el' and turn on `linkd-mode' now.  It lets you easily
 navigate around the sections of this doc.  Linkd mode will
 highlight this Index, as well as the cross-references and section
 headings throughout this file.  You can get `linkd.el' here:
 https://www.emacswiki.org/emacs/download/linkd.el.

 (@> "Things Defined Here")
 (@> "Documentation")
   (@> "Libraries `facemenu+.el' and `mouse3.el' put Highlight on the Menu")
   (@> "User Options `hlt-use-overlays-flag' and `hlt-overlays-priority'")
   (@> "Temporary or Permanent Highlighting")
   (@> "Commands")
   (@> "Copy and Yank (Paste) Text Properties")
   (@> "User Option `hlt-act-on-any-face-flag'")
   (@> "Hiding and Showing Text")
     (@> "Hiding and Showing Text - Icicles Multi-Commands")
   (@> "What Gets Highlighted: Region, Buffer, New Text You Type")
   (@> "Interaction with Font Lock")
   (@> "Suggested Bindings")
   (@> "See Also")
   (@> "Commands That Won't Work in Emacs 20")
   (@> "To Do")
 (@> "Change log")
 (@> "Macros")
 (@> "Key Bindings")
 (@> "Menus")
 (@> "Variables and Faces")
 (@> "Misc Functions - Emacs 20+")
 (@> "Misc Functions - Emacs 21+")
 (@> "Functions for Highlighting Propertized Text - Emacs 21+")
 (@> "Functions for Highlighting Isearch Matches - Emacs 23+")
 (@> "General and Utility Functions")

(@* "Things Defined Here")

 Things Defined Here
 -------------------

 Macros defined here:

   `hlt-user-error'.

 Commands defined here:

   `hlt-choose-default-face', `hlt-copy-props', `hlt-eraser',
   `hlt-eraser-mouse', `hlt-hide-default-face', `hlt-highlight',
   `hlt-highlight-all-prop', `hlt-highlight-enclosing-list',
   `hlt-highlighter', `hlt-highlighter-mouse',
   `hlt-highlight-isearch-matches',
   `hlt-highlight-line-dups-region', `hlt-highlight-lines',
   `hlt-highlight-property-with-value',
   `hlt-highlight-regexp-groups-region',
   `hlt-highlight-regexp-region',
   `hlt-highlight-regexp-region-in-buffers',
   `hlt-highlight-regexp-to-end', `hlt-highlight-region',
   `hlt-highlight-region-in-buffers', `hlt-highlight-regions',
   `hlt-highlight-regions-in-buffers',
   `hlt-highlight-single-quotations', `hlt-highlight-symbol',
   `hlt-mouse-copy-props', `hlt-mouse-face-each-line',
   `hlt-next-face', `hlt-next-highlight', `hlt-paste-props',
   `hlt-previous-face', `hlt-previous-highlight',
   `hlt-replace-highlight-face',
   `hlt-replace-highlight-face-in-buffers',
   `hlt-show-default-face', `hlt-toggle-act-on-any-face-flag',
   `hlt-toggle-link-highlighting',
   `hlt-toggle-property-highlighting',
   `hlt-toggle-use-overlays-flag', `hlt-unhighlight-all-prop',
   `hlt-unhighlight-isearch-matches',
   `hlt-unhighlight-regexp-groups-region',
   `hlt-unhighlight-regexp-region',
   `hlt-unhighlight-regexp-region-in-buffers',
   `hlt-unhighlight-regexp-to-end', `hlt-unhighlight-region',
   `hlt-unhighlight-region-for-face',
   `hlt-unhighlight-region-for-face-in-buffers',
   `hlt-unhighlight-region-in-buffers', `hlt-unhighlight-regions',
   `hlt-unhighlight-regions-in-buffers',`hlt-unhighlight-symbol',
   `hlt-yank-props'.

 User options (variables) defined here:

   `hlt-act-on-any-face-flag', `hlt-auto-face-backgrounds',
   `hlt-auto-face-foreground', `hlt-auto-faces-flag',
   `hlt-default-copy/yank-props', `hlt-face-prop',
   `hlt-line-dups-ignore-regexp', `hlt-max-region-no-warning',
   `hlt-overlays-priority', `hlt-use-overlays-flag'.

 Faces defined here:

   `hlt-property-highlight', `hlt-regexp-level-1',
   `hlt-regexp-level-2', `hlt-regexp-level-3',
   `hlt-regexp-level-4', `hlt-regexp-level-5',
   `hlt-regexp-level-6', `hlt-regexp-level-7',
   `hlt-regexp-level-8', `minibuffer-prompt' (for Emacs 20).

 Non-interactive functions defined here:

   `hlt-+/--highlight-regexp-read-args',
   `hlt-+/--highlight-regexp-region', `hlt-+/--read-regexp',
   `hlt-+/--read-bufs', `hlt-add-listifying',
   `hlt-add-to-invisibility-spec', `hlt-delete-highlight-overlay',
   `hlt-highlight-faces-in-buffer', `hlt-flat-list',
   `hlt-highlight-faces-in-buffer', `hlt-highlight-regexp-groups',
   `hlt-listify-invisibility-spec',
   `hlt-mouse-toggle-link-highlighting',
   `hlt-mouse-toggle-property-highlighting',
   `hlt-nonempty-region-p', `hlt-props-to-copy/yank',
   `hlt-read-bg/face-name', `hlt-read-props-completing',
   `hlt-region-or-buffer-limits', `hlt-remove-if-not',
   `hlt-set-intersection', `hlt-set-union', `hlt-string-match-p',
   `hlt-subplist', `hlt-tty-colors', `hlt-unhighlight-for-overlay'.

 Internal variables defined here:

   `hlt-copied-props', `hlt-face-nb', `hlt-last-face',
   `hlt-last-regexp', `hlt-map',
   `hlt-previous-use-overlays-flag-value',
   `hlt-prop-highlighting-state'.

(@* "Documentation")

 Documentation
 -------------

(@* "Libraries `facemenu+.el' and `mouse3.el' put Highlight on the Menu")
 ** Libraries `facemenu+.el' and `mouse3.el' put Highlight on the Menu **

 If you load library `facemenu+.el' after you load library
 `highlight.el' then commands defined here are also available on a
 `Highlight' submenu in the Text Properties menus.

 If you load library `mouse3.el' after you load library
 `highlight.el' then:

   * Commands defined here are also available on a `Highlight'
     submenu of the `Region' right-click popup menu.

   * Commands `hlt-highlight-symbol' and `hlt-unhighlight-symbol'
     are available on the `Thing at Pointer' submenu of the `No
     Region' right-click popup menu.

(@* "User Options `hlt-use-overlays-flag' and `hlt-overlays-priority'")
 ** User Options `hlt-use-overlays-flag' and `hlt-overlays-priority'

 You can highlight text in two ways using this library, depending
 on the value of user option `hlt-use-overlays-flag':

  - non-nil means to highlight using overlays
  - nil means to highlight using text properties

 Overlays are independent from the text itself.  They are not
 picked up when you copy and paste text.  By default, highlighting
 uses overlays.

 Although highlighting recognizes only nil and non-nil values for
 `hlt-use-overlays-flag', other actions can have different
 behavior, depending on the non-nil value.  If it is `only' (the
 default value), then only overlay highlighting is affected.  If it
 is any other non-nil value, then both overlay highlighting and
 text-property highlighting are effected.  This is the case, for
 instance, for unhighlighting and for navigating among highlights.

 For example, for unhighlighting, if `hlt-use-overlays-flag' is
 non-nil, then overlay highlighting is removed.  If it is not
 `only', then text-property highlighting is removed.  A value of
 nil thus removes both overlays and text properties.

 Keep this sensitivity to the value of `hlt-use-overlays-flag' in
 mind.  For example, if you change the value after adding some
 highlighting, then that highlighting might not be removed by
 unhighlighting, unless you change the value back again.

 You can toggle the value of `hlt-use-overlays-flag' at any time
 between nil and its previous non-nil value, using command
 `hlt-toggle-use-overlays-flag'.

 Option `hlt-overlays-priority' is the priority assigned to
 overlays created by `hlt-* functions.  A higher priority makes an
 overlay seem to be "on top of" lower priority overlays.  The
 default value is a zero priority.

(@* "Temporary or Permanent Highlighting")
** "Temporary or Permanent Highlighting" **

 Generally, highlighting you add is temporary: it is not saved when
 you write your buffer to disk.  However, Emacs has a curious and
 unfamiliar feature called "formatted" or "enriched" text mode,
 which does record highlighting permanently.  See the Emacs manual,
 node `Requesting Formatted Text'.

 To save highlighting permanently, do the following:

 1. `M-x enriched-mode', to put your file buffer in minor mode
    `enriched-mode'.  You see `Enriched' in the mode line.

 2. Choose text-property highlighting, not overlay highlighting, by
    setting option `hlt-use-overlays-flag' to `nil'.  To do this
    using Customize, choose menu item `Highlight using text
    properties, not overlays'.

 3. Choose the highlight face to use:
    `M-x hlt-choose-default-face'.

 4. Highlight in any way provided by library `highlight.el'.  For
    example, use `hlt-highlighter' (personally, I bind it to `C-x
    mouse-2') to drag-highlight as if using a marker pen.

 5. Save your file.

    Note that, although highlighting in enriched-text mode modifies
    the buffer, it does not appear modified (check the beginning of
    the mode line), so if you make no other changes then using `C-x
    C-s' does not save your highlighting changes.  To remedy this,
    just do something besides highlighting - e.g., add a space and
    delete it - so that `C-x C-s' saves to disk.

 When you reopen your file later, it is automatically in enriched
 mode, and your highlighting shows.  However, be aware that
 font-locking can interfere with enriched mode, so you might want
 to use it on files where you don't use font-locking.  But see also
 (@> "Interaction with Font Lock").

(@* "Commands")
 ** Commands **

 You can use any face to highlight, and you can apply a mouse face
 instead of a face, if you like.  A mouse face shows up only when
 the mouse pointer is over it.

 The main command to choose a face to use for highlighting (or for
 unhighlighting) is `hlt-choose-default-face'.  It reads a face
 name, with completion.

 But you can alternatively choose a color name instead of a face
 name.  The completion candidates are annotated in buffer
 `*Completions*' with `Face' or `Color', to help you identify them.

 If you use library Icicles and option
 `icicle-WYSIWYG-Completions-flag' is non-nil, then candidate faces
 and colors are WYSIWYG: What You See Is What You Get.

 If you choose a color instead of a face then an unnamed pseudo
 face is created and used.  It has the chosen color as background,
 and its foreground color is determined by the value of user option
 `hlt-auto-face-foreground'.  If that option is nil then
 highlighting does not change the existing foreground color.
 Otherwise, the option value is the foreground color used for
 highlighting.

 Another way to choose the highlighting face is to use command
 `hlt-next-face' or `hlt-previous-face'.  These cycle among a
 smaller set of faces and background colors, the elements in the
 list value of option `hlt-auto-face-backgrounds'.  You can use a
 numeric prefix argument with these commands to choose any of the
 elements by its absolute position in the list.

 Choosing the default highlighting face using
 `hlt-choose-default-face', `hlt-next-face', or `hlt-previous-face'
 affects the next highlighting or unhighlighting operation.  You
 can also choose to automatically cycle among the faces defined by
 `hlt-auto-face-backgrounds', with each (un)highlighting command
 using the next face in the list.  To choose this behavior,
 customize option `hlt-auto-faces-flag' to non-nil.

 The commands with `region' in their name act on the text in the
 active region.  If the region is not active then they act on the
 text in the whole buffer.  The commands with `to-end' in their
 name act on the text from point to the end of the buffer.  See
 also (@> "What Gets Highlighted: Region, Buffer, New Text You Type").

 The commands you will use the most often are perhaps
 `hlt-highlight', `hlt-highlighter', `hlt-highlight-symbol',
 `hlt-next-highlight', and `hlt-previous-highlight', as well as
 unhighlighting commands.  You might also often use the various
 commands to hide and show highlighted text.

 You can use command `hlt-highlight' to highlight or unhighlight
 the region, or to highlight or unhighlight a regexp throughout the
 region, depending on the prefix argument.  It combines the
 behaviors of commands `hlt-highlight-region',
 `hlt-unhighlight-region', `hlt-highlight-regexp-region', and
 `hlt-highlight-regexp-region'.  I suggest that you bind
 `hlt-highlight' to a key - I use `C-x C-y'.

 Commands `hlt-highlight-regexp-to-end' and
 `hlt-unhighlight-regexp-to-end' highlight and unhighlight a regexp
 from point to the end of the buffer, respectively.

 Command `hlt-highlighter' lets you highlight text by simply
 dragging the mouse, just as you would use a highlighter (marker).
 You can thus highlight text the same way that you drag the mouse
 to define the region.

 Command `hlt-eraser' lets you delete highlighting by dragging the
 mouse.  However, its behavior is different for overlays and text
 properties, and it is perhaps different from you expect.  If
 option `hlt-use-overlays-flag' is not `only' then it removes
 text-property highlighting for *ALL* faces (not just highlighting
 faces).

 A prefix arg for `hlt-highlighter' and `hlt-eraser' acts the same
 as for `hlt-next-face': it lets you choose the face to use.  It
 has no effect for `hlt-eraser' unless `hlt-use-overlays-flag' is
 `only', in which case it erases the Nth face in
 `hlt-auto-face-backgrounds', where N is the prefix arg.

 Command `hlt-highlight-regexp-groups-region', like command
 `hlt-highlight-regexp-region', highlights regexp matches.  But
 unlike the latter, it highlights the regexp groups (up to 8
 levels) using different faces - faces `hlt-regexp-level-1' through
 `hlt-regexp-level-8'.  Use it, for example, when you are trying
 out a complex regexp, to see what it is actually matching.
 Command `hlt-unhighlight-regexp-groups-region' unhighlights such
 highlighting.

 Command `hlt-highlight-line-dups-region' highlights the sets of
 duplicate lines in the region (or the buffer, if the region is not
 active).  By default, leading and trailing whitespace are ignored
 when checking for duplicates, but this is controlled by option
 `hlt-line-dups-ignore-regexp'.  And with a prefix arg the behavior
 effectively acts opposite to the value of that option.  So if the
 option says not to ignore whitespace and you use a prefix arg then
 whitespace is ignored, and vice versa.

 If you use Emacs 21 or later, you can use various commands that
 highlight and unhighlight text that has certain text properties
 with given values.  You can use them to highlight all text in the
 region or buffer that has a given property value.  An example is
 highlighting all links (text with property `mouse-face').  These
 commands are:

 `hlt-highlight-all-prop' - Highlight text that has a given
                            property with any (non-nil) value.

 `hlt-highlight-property-with-value' - Highlight text that has a
                            given property with certain values.

 `hlt-unhighlight-all-prop' - Unhighlight highlighted propertized
                            text.

 `hlt-mouse-toggle-link-highlighting' - Alternately highlight and
                            unhighlight links on a mouse click.

 `hlt-toggle-link-highlighting' - Alternately highlight and
                            unhighlight links.

 `hlt-mouse-toggle-property-highlighting' - Alternately highlight
                            and unhighlight propertized text on a
                            mouse click.

 `hlt-toggle-property-highlighting' - Alternately highlight and
                            unhighlight propertized text.

 As always for library `highlight.el', this "highlighting" can use
 property `mouse-face' instead of `face'.  You could, for example,
 highlight, using `mouse-face', all text that has property `foo' -
 or that has property `face', for that matter.

 If you use Emacs 21 or later, you can use commands
 `hlt-next-highlight' and `hlt-previous-highlight' to navigate
 among highlights of a given face.

 You can unhighlight the region/buffer or a regexp in the
 region/buffer using command `hlt-unhighlight-region' or
 `hlt-unhighlight-regexp-region'.  If you use overlay highlighting
 then you can use command `hlt-unhighlight-region-for-face' to
 unhighlight the region/buffer for an individual highlighting face
 - other highlighting faces remain.

 You can replace a highlighting face in the region/buffer by
 another, using command `hlt-replace-highlight-face'.  With a
 prefix argument, property `mouse-face' is used, not property
 `face'.

 Command `hlt-highlight-single-quotations' highlights single-quoted
 text in the region.  For example, Emacs commands and keys between
 ` and ': `foobar'.

 Command `hlt-mouse-face-each-line' puts a `mouse-face' property on
 each line of the region.

 Command `hlt-highlight-lines' highlights all lines touched by the
 region, extending the highlighting to the window edges.

 You can highlight and unhighlight multiple buffers at the same
 time.  Just as for a single buffer, there are commands for regexp
 (un)highlighting, and all of the multiple-buffer commands, whose
 names end in `-in-buffers', are sensitive to the region in each
 buffer, when active.  These are the multiple-buffer commands:

 `hlt-highlight-region-in-buffers'
 `hlt-unhighlight-region-in-buffers'
 `hlt-highlight-regexp-region-in-buffers'
 `hlt-unhighlight-regexp-region-in-buffers'
 `hlt-unhighlight-region-for-face-in-buffers'
 `hlt-replace-highlight-face-in-buffers'

 Normally, you are prompted for the names of the buffers, one at a
 time.  Use `C-g' when you are done entering buffer names.  But a
 non-positive prefix arg means act on all visible or iconified
 buffers.  (A non-negative prefix arg means use property
 `mouse-face', not `face'.)

 If you also use library `zones.el' then narrowing and other
 operations record buffer zones (including narrowings) in (by
 default) buffer-local variable `zz-izones'.  Besides narrowing,
 you can use `C-x n a' (command `zz-add-zone') to add the current
 region to the same variable.

 You can use command `hlt-highlight-regions' to highlight buffer
 zones, as defined by their limits (interactively, `zz-izones'),
 and you can use command `hlt-highlight-regions-in-buffers' to
 highlight all zones recorded for a given set of buffers.  You can
 use commands `hlt-unhighlight-regions' and
 `hlt-unhighlight-regions-in-buffers' to unhighlight them.  If
 option `hlt-auto-faces-flag' is non-nil then each zone gets a
 different face.  Otherwise, all of them are highlighted with the
 same face.

 From Isearch you can highlight the search-pattern matches.  You
 can do this across multiple buffers being searched together.
 These keys are bound on the Isearch keymap for this:

  `M-s h h' - `hlt-highlight-isearch-matches'
  `M-s h u' - `hlt-unhighlight-isearch-matches'

(@* "Copy and Yank (Paste) Text Properties")
 ** Copy and Yank (Paste) Text Properties **

 You can highlight or unhighlight text by simply copying existing
 highlighting (or lack of any highlighting) from anywhere in Emacs
 and yanking (pasting) it anywhere else.

 Put differently, you can copy and yank a set of text properties.
 You can use these commands to copy and yank any text properties,
 not just `face' or `mouse-face'.

 To copy the text properties at a given position, use command
 `hlt-copy-props'.  You can then use command `hlt-yank-props' to
 yank those properties to the active region anywhere.  If the set
 of properties that you copy is empty, then yanking means
 effectively removing all text properties.

 User option `hlt-default-copy/yank-props' controls which text
 properties to copy and yank, by default.  The default value of the
 option includes only `face', which means that only property `face'
 is copied and pasted.  That is typically what you want, for
 highlighting purposes.  A value of `t' for
 `hlt-default-copy/yank-props' means use all properties.

 You can further control which text properties are copied or yanked
 when you use the commands, by using a prefix argument.  A plain or
 non-negative prefix arg means copy or yank all available text
 properties.  A negative prefix arg (e.g. `C--') means you are
 prompted for which text properties to use, among those available.

 For copying, the available properties are those among
 `hlt-default-copy/yank-props' that are also present at the copy
 position.  For yanking, the available properties are those among
 `hlt-default-copy/yank-props' that have previously (last) been
 copied.

(@* "User Option `hlt-act-on-any-face-flag'")
 ** User Option `hlt-act-on-any-face-flag' **

 Library `highlight' generally acts only on faces that it controls,
 that is, faces that you have explicitly asked it to use for
 highlighting.  It sets the text property or overlay property
 `hlt-highlight' on such highlighted text, so that it can recognize
 which faces it has responsibility for.

 Sometimes, you might want to hide and show text other than that
 controlled by library `highlight'.  Similarly, you might sometimes
 want to navigate among faces other than those used for
 highlighting.  You can control this using option
 `hlt-act-on-any-face-flag', which you can toggle at any time using
 command `hlt-toggle-act-on-any-face-flag'.

(@* "Hiding and Showing Text")
 ** Hiding and Showing Text **

 You can hide and show text that you have highlighted.  You will
 want to read the Emacs-Lisp manual (Elisp), section Invisible
 Text, to understand better what this entails.  In particular, you
 should understand that for library `highlight.el', hiding text
 means adding the symbol naming the face to be hidden to both:

 1. a text or overlay `invisible' property, making the text or
    overlay susceptible to being hidden by buffer-local variable
    `buffer-invisibility-spec', and

 2. the buffer's `buffer-invisibility-spec', so that it in fact
    becomes hidden.

 After text has been hidden this way, and unless the highlighting
 has been removed completely by unhighlighting the text, the
 `invisible' property of that text keeps the names of the faces
 that have been applied to that text and hidden previously, even
 after you show that text again.  Showing a hidden face simply
 removes it from the `buffer-invisibility-spec'; it does not change
 any `invisible' properties.

 For example, if you hide face `foo' at some buffer position:

 1. The `invisible' property of the text or overlay at that
    position is updated to include `foo'.  If there are no other
    faces that have been applied to this text and then hidden, the
    `invisible' property is just `(foo)'.

 2. `buffer-invisibility-spec' is also updated to include `foo'.
    This hides all text properties and overlay properties with
    `invisible' property `foo', throughout the buffer.  If there
    are no other invisible faces in the buffer, then
    `buffer-invisibility-spec' has value (foo).

 If you then show face `foo' at that same buffer position, there is
 no change to the `invisible' property.  `buffer-invisibility-spec'
 is updated, by removing `foo': if it was (foo), it becomes ().

 There are several commands for hiding and showing highlighted
 text.  The basic commands for hiding and showing are
 `hlt-hide-default-face' and `hlt-show-default-face', which you can
 use to hide and show the face last used for highlighting.  With a
 prefix argument, you are prompted for a different face to hide or
 show; it then becomes the default face for highlighting.  You can
 also change the default highlighting face at any time using
 command `hlt-choose-default-face'.

(@* "Hiding and Showing Text - Icicles Multi-Commands")
 *** Hiding and Showing Text - Icicles Multi-Commands ***

 The other hide and show commands depend on your also using
 Icicles, which is a set of libraries that offer enhanced
 completion.  Complete information about Icicles is here:
 `https://www.emacswiki.org/emacs/Icicles'.  You can obtain Icicles
 here: `https://www.emacswiki.org/emacs/Icicles_-_Libraries'.

 The Icicles commands defined for `highlight.el' are the following:

 `icicle-choose-faces', `icicle-choose-invisible-faces',
 `icicle-choose-visible-faces', `icicle-hide-faces',
 `icicle-hide-only-faces', `icicle-show-faces',
 `icicle-show-only-faces'.

 These are all Icicles multi-commands, which means that they each
 let you choose multiple completion candidates or all candidates
 that match your current input (a regexp).  To use them you must
 also use Icicles.  You can use command `icicle-hide-faces' to hide
 any number of visible faces.  Any text is hidden that has that
 face as a text property or an overlay property, depending on the
 value of `hlt-use-overlays-flag'.

 Command `icicle-show-faces' is the opposite of
 `icicle-hide-faces': it shows invisible text that has the faces
 you choose.  Neither `icicle-hide-faces' nor `icicle-show-faces'
 has any effect on other faces, besides those you choose to hide or
 show, respectively; they each do only one thing, hide or show.

 Command `icicle-hide-only-faces' hides the faces you choose, and
 shows all other faces, and command `icicle-show-only-faces' does
 the opposite.  You can thus use these commands to specify exactly
 what faces should be invisible and visible.  Empty input means
 none: If you choose no faces to hide (that is, hit `RET' with an
 empty minibuffer), then all faces are made visible; if you choose
 no faces to show, then all are hidden.

 Currently, face attributes for highlighting are combined when
 overlays overlap, but the same is not true for text properties.
 For example, if you highlight a word with face `foo', and then you
 highlight it with face `bar', only `bar' remains as the face for
 that word.  With overlays, the attributes of the two faces are
 composed.  When you hide or show faces, this behavior difference
 has an effect.

 You can hide text using the commands in this library for any of
 the purposes that you might use invisible text in Emacs.  This
 gives you an easy, interactive way to control which sections of
 text are seen by search and other Emacs tools.  Use the regexp
 highlighting commands, for instance, to highlight text
 syntactically, and then hide that highlighted text.  Or use
 `hlt-highlighter' to sweep over text that you want to hide with
 the mouse.

 Hiding and showing faces also provides a "conditional text"
 feature similar to that available in desktop publishing
 applications such as Adobe Framemaker.  Publishers often use such
 a feature to produce different output documents from the same
 source document ("single sourcing").  You can use this feature
 similarly, if you have an application (printing is one example)
 that is sensitive to whether text is visible or invisible.  One
 caveat: Emacs faces are not saved when you save your file.

(@* "What Gets Highlighted: Region, Buffer, New Text You Type")
 ** What Gets Highlighted: Region, Buffer, New Text You Type **

 Most mention of the "region" in this commentary should really say
 "active region or buffer".  If the region is active and non-empty,
 then only the text in the region is targeted by the commands in
 this library.  This lets you easily control the scope of
 operations.

 If the region is not active or it is empty, then:

 - If `hlt-use-overlays-flag' is nil and there is no prefix arg,
   then the face is applied to the next characters that you type.

 - Otherwise, the face is applied to the entire buffer (or the
   current restriction, if the buffer is narrowed).

(@* "Interaction with Font Lock")
 ** Interaction with Font Lock **

 Any highlighting that uses text property `face' is overruled by
 font-lock highlighting - font-lock wants to win.  (This does not
 apply to highlighting that uses overlays - font-lock has no effect
 on overlays.)  In many cases you can still highlight text, but
 sooner or later font-lock erases that highlighting when it
 refontifies the buffer.

 To prevent this interference of font-lock with other highlighting,
 the typical Emacs approach is to fool font-lock into thinking that
 it is font-lock highlighting, even when it does not involve
 `font-lock-keywords'.

 But this has the effect that such highlighting is turned off when
 `font-lock-mode' is turned off.  Whether this is a good thing or
 bad depends on your use case.

 In vanilla Emacs you have no choice about this.  Either the
 highlighting is not recognized by font-lock, which overrules it,
 or it is recognized as "one of its own", in which case it is
 turned off when font-lock highlighting is turned off.  With
 library `highlight.el' things are more flexible.

 First, there is option `hlt-face-prop', whose value determines the
 highlighting property: Value `font-lock-face' means that the
 highlighting is controlled by font-lock.  Value `face' means that
 `font-lock' does not recognize the highlighting.

 Second, for the case where the option value is `face', if you also
 use library `font-lock+.el' then there is no interference by
 font-lock - the highlighting is independent of font-lock.  Library
 `font-lock+.el' is loaded automatically by `highlight.el', if it
 is in your `load-path'.  It prevents font-locking from removing
 any highlighting face properties that you apply using the commands
 defined here.

 Then font-lock does not override this highlighting with its own,
 and it does not turn this highlighting on and off.  Depending on
 your application, this can be quite important.

 The default value of option `hlt-face-prop' is `font-lock-face'.
 If you want text-property highlighting that you add to be able to
 persist and be independent of font-locking, then change the value
 to `face' and put library `font-lock+.el' in your `load-path'.

 [If you also load library `facemenu+.el', then the same applies to
 highlighting that you apply using the face menu: `font-lock+.el'
 also protects that highlighting from interference by font-lock.]

(@* "Suggested Bindings")
 ** Suggested Bindings **

 Library `highlight.el' binds many of its commands to keys on the
 prefix key `C-x X'.  It also adds menu items to the `Region'
 submenu of the `Edit' menu-bar menu, if you have a `Region'
 submenu.  To obtain this menu, load library `menu-bar+.el'.

 Here are some additional, suggested key bindings (`C-x C-y', `C-x
 mouse-2', `C-x S-mouse-2', `C-S-p', and `C-S-n', respectively):

  (define-key ctl-x-map [(control ?y)]     'hlt-highlight)
  (define-key ctl-x-map [(down-mouse-2)]   'hlt-highlighter)
  (define-key ctl-x-map [(S-down-mouse-2)] 'hlt-eraser)
  (global-set-key [(shift control ?p)]     'hlt-previous-highlight)
  (global-set-key [(shift control ?n)]     'hlt-next-highlight)
  (global-set-key [(control meta shift ?s)]
                  'hlt-highlight-enclosing-list)

(@* "See Also")
 ** See Also **

 * `highlight-chars.el' - Provides ways to highlight different sets
   of characters, including whitespace and Unicode characters.  It
   is available here:
   https://www.emacswiki.org/emacs/download/highlight-chars.el (code)
   https://www.emacswiki.org/emacs/ShowWhiteSpace#HighlightChars (doc)

 * `hi-lock.el' - The features of `highlight.el' are complementary
   to those of vanilla Emacs library `hi-lock.el', so you can use
   the two libraries together.  See this page for a comparison:
   https://www.emacswiki.org/emacs/HighlightTemporarily.

(@* "Commands That Won't Work in Emacs 20")
 ** Commands That Won't Work in Emacs 20 **

 The following commands and options work only for Emacs versions
 more recent than Emacs 20:

 `hlt-act-on-any-face-flag', `hlt-hide-default-face',
 `hlt-highlight-line-dups-region',
 `hlt-highlight-property-with-value', `hlt-next-highlight',
 `hlt-previous-highlight', `hlt-show-default-face',
 `hlt-toggle-act-on-any-face-flag'.

(@* "To Do")
 ** To Do **

 1. Add commands to show and hide boolean combinations of faces.

 2. Faces are not accumulated as text properties.
    Highlighting with one face completely replaces the previous
    highlight.  Overlays don't have this limitation.  Text
    properties need not have it either, but they do, for now.

(@* "Acknowledgement")
 **  Acknowledgement **

 Some parts of this library were originally based on a library of
 the same name written and copyrighted by Dave Brennan,
 brennan@hal.com, in 1992.  I haven't been able to locate that
 file, so my change log is the only record I have of what our
 relative contributions are.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
