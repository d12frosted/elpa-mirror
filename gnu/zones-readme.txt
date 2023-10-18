    Zones of text - like multiple regions.

   Bug reports etc.: (concat "drew" ".adams" "@" "oracle" ".com")

   You can get `zones.el' from Emacs Wiki or GNU ELPA:

   * Emacs Wiki: https://www.emacswiki.org/emacs/download/zones.el
   * GNU ELPA:   https://elpa.gnu.org/packages/zones.html

   The instance on Emacs Wiki might sometimes be more recent, but
   major changes (named ''versions'') are posted to GNU ELPA.

   More description below.
 
(@> "Index")

 Index
 -----

 If you have library `linkd.el', load `linkd.el' and turn on
 `linkd-mode' now.  It lets you easily navigate around the sections
 of this doc.  Linkd mode will highlight this Index, as well as the
 cross-references and section headings throughout this file.  You
 can get `linkd.el' here:
 https://www.emacswiki.org/emacs/download/linkd.el.

 (@> "Things Defined Here")
 (@> "Documentation")
   (@> "Compatibility")
   (@> "Zones")
   (@> "Coalesced (United) Zones")
   (@> "Noncontiguous Region and Set of Zones")
   (@> "Zones and Overlays")
   (@> "Izone Commands")
   (@> "Izone List Variables")
   (@> "Keys")
   (@> "Command `zz-narrow-repeat'")
   (@> "Define Your Own Commands")
   (@> "Automatically Create Zones on Region Deactivation")
 (@> "Change Log")
 (@> "Compatibility Code for Older Emacs Versions")
 (@> "Variables and Faces")
 (@> "Advice for Standard Functions")
 (@> "General Commands")
 (@> "General Non-Interactive Functions")
 (@> "Key Bindings")
 
(@* "Things Defined Here")

 Things Defined Here
 -------------------

 Commands defined here:

   `zz-add-region-as-izone', `zz-add-zone',
   `zz-add-zone-and-coalesce', `zz-add-zone-and-unite',
   `zz-add-zones-from-highlighting',
   `zz-add-zones-matching-regexp',
   `zz-auto-add-region-as-izone-mode',
   `zz-clone-and-coalesce-zones', `zz-clone-and-unite-zones',
   `zz-clone-zones', `zz-coalesce-zones', `zz-delete-zone',
   `zz-narrow', `zz-narrow-repeat', `zz-query-replace-zones' (Emacs
   25+), `zz-query-replace-regexp-zones' (Emacs 25+),
   `zz-select-region', `zz-select-region-by-id-and-text',
   `zz-select-region-repeat', `zz-select-zone',
   `zz-select-zone-by-id-and-text', `zz-select-zone-repeat',
   `zz-set-izones-var', `zz-set-zones-from-face',
   `zz-set-zones-from-highlighting',
   `zz-set-zones-matching-regexp', `zz-unite-zones'.

 User options defined here:

   `zz-auto-remove-empty-izones-flag',
   `zz-narrowing-adds-zone-flag', `zz-narrowing-use-fringe-flag'
   (Emacs 23+).

 Faces defined here:

   `zz-fringe-for-narrowing'.

 Non-interactive functions defined here:

   `zz-add-key-bindings-to-narrow-map', `zz-basic-zones',
   `zz-basic-zones-in-bufs', `zz-buffer-narrowed-p' (Emacs 22-23),
   `zz-buffer-of-markers', `zz-car-<',
   `zz-choose-zone-by-id-and-text', `zz-do-izones',
   `zz-dotted-zones-from-izones', `zz-do-zones', `zz-dot-pairs',
   `zz-empty-zone-p', `zz-every', `zz-get-overlay-props',
   `zz-izone-has-other-buffer-marker-p',
   `zz-izones-from-noncontiguous-region' (Emacs 25+),
   `zz-izones-from-zones', `zz-izone-p', `zz-izones-p',
   `zz-izones-renumber', `zz-map-izones', `zz-map-zones',
   `zz-marker-from-object', `zz-markerize', `zz-max', `zz-min',
   `zz-narrow-advice', `zz-narrowing-lighter',
   `zz-noncontiguous-region-from-izones',
   `zz-noncontiguous-region-from-zones', `zz-numberize',
   `zz-number-or-marker-p', `zz-numeric-position',
   `zz-order-zones', `zz-overlays-to-zones', `zz-overlay-to-zone',
   `zz-overlay-union', `zz-position-from-object',
   `zz-rassoc-delete-all', `zz-readable-marker',
   `zz-readable-markerize', `zz-readable-marker-p',
   `zz-read-any-variable', `zz-read-bufs', `zz-regexp-car-member',
   `zz-remove-empty-izones', `zz-remove-if', `zz-remove-if-not',
   `zz-remove-izones-w-other-buffer-markers',
   `zz-remove-zones-w-other-buffer-markers', `zz-repeat-command',
   `zz-same-position-p', `zz-set-intersection', `zz-set-union',
   `zz-some', `zz-string-match-p', `zz-two-zone-intersection',
   `zz-two-zone-union', `zz-zone-abstract-function-default',
   `zz-zone-buffer-name', `zz-zone-has-other-buffer-marker-p',
   `zz-zone-intersection', `zz-zone-intersection-1',
   `zz-zone-ordered', `zz-zones-complement',
   `zz-zones-from-noncontiguous-region' (Emacs 25+),
   `zz-zones-overlap-p', `zz-zones-same-buffer-name-p',
   `zz-zones-to-overlays', `zz-zone-to-overlay', `zz-zone-union',
   `zz-zone-union-1'.

 Internal variables defined here:

   `zz--fringe-remapping', `zz-add-zone-anyway-p', `zz-izones',
   `zz-izones-var', `zz-lighter-narrowing-part',
   `zz-zone-abstract-function', `zz-zone-abstract-limit',
   `zz-toggles-map'.

 Macros defined here:

   `zz-user-error'.


 ***** NOTE: These EMACS PRIMITIVES have been ADVISED HERE:

   `narrow-to-defun', `narrow-to-page', `narrow-to-region'.
 
(@* "Documentation")

 Documentation
 -------------

 Library `zones.el' lets you easily define and subsequently act on
 multiple zones of buffer text.  You can think of this as enlarging
 the notion of "region".  In effect, it can remove the requirement
 of target text being a contiguous sequence of characters.  A set
 of buffer zones is, in effect, a (typically) noncontiguous
 "region" of text.


(@* "Compatibility")
 ** Compatibility **

 Some of the functions defined here are not available for Emacs
 versions prior to 23.  Still others are available only starting
 with Emacs 25.  This is mentioned where applicable.


(@* "Zones")
 ** Zones **

 A "zone" is a basic zone or an izone.  A zone represents the text
 between its two positions, just as an Emacs region is the text
 between point and mark.

 A "basic zone" is a list of two buffer positions followed by a
 possibly empty list of extra information: (POS1 POS2 . EXTRA).

 An "izone" is a list whose first element is an identifier, ID,
 which is a negative integer (-1, -2, -3,...), and whose cdr is a
 basic zone.  So an izone has the form (ID POS1 POS2 . EXTRA).

 The ID is negative just to distinguish a basic zone whose EXTRA
 list starts with an integer from an izone.  Interactively (e.g. in
 prompts), references to the ID typically leave off the minus sign.

 The positions of a zone can be positive integers (1, 2, 3,...),
 markers for the same buffer, or readable markers for the same
 buffer.  (Behavior is undefined if a single zone has markers for
 different buffers.)  Each position of a given zone can take any of
 these forms.

 A "readable marker" is a list (marker BUFFER POSITION), where
 BUFFER is a buffer name (string) and where POSITION is a buffer
 position (as an integer, not as a marker).

 The content of a zone is any contiguous stretch of buffer text.
 The positions of a zone can be in either numeric order.  The
 positions are also called the zone "limits".  The lower limit is
 called the zone "beginning"; the upper limit is called its "end".


(@* "Coalesced (United) Zones")
 ** Coalesced (United) Zones **

 A list of zones can include zones that overlap or are adjacent
 (the end of one is one less than the beginning of the other).

 Basic-zone union and intersection operations (`zz-zone-union',
 `zz-zone-intersection') each act on a list of zones, returning
 another such list, but with the recorded positions for each zone
 in (ascending) buffer order, and with the zones in ascending order
 of their cars.  For basic-zone union, the resulting zones are said
 to be "coalesced", or "united".

 The extra info in the zones that result from zone union or
 intersection is just the set union or set intersection of the
 extra info in the zones that are combined.

 After a list of zones has been altered by `zz-zone-union' or
 `zz-zone-intersection':

 * Each zone in the result list is ordered so that its first
   element is smaller than its second.

 * The zones in the result list have been sorted in ascending order
   by their first elements.

 * The zones in the result list are disjoint: they are not adjacent
   and do not overlap: there is some other buffer text (i.e., not
   in any zone) between any two zones in the result.


(@* "Noncontiguous Region and Set of Zones")
 ** Noncontiguous Region and Set of Zones **

 Starting with Emacs 25, Emacs can sometimes use a region that is
 made up of noncontiguous pieces of buffer content: a
 "noncontiguous region".  This is similar to a set of zones, but
 there are some differences.

 The zones in a set (or list) of zones can be adjacent or overlap,
 and their order in the set is typically not important.

 A noncontiguous region corresponds instead to what results from
 coalescing (uniting) a set of zones: a sequence of disjoint zones,
 in buffer order, that is, ordered by their cars.

 The Lisp representation of a zone also differs from that of a
 segment of a noncontiguous region.  Each records two buffer
 positions, but a zone can also include a list of additional
 information (whatever you like).

 A noncontiguous-region segment is a cons (BEGIN . END), with BEGIN
 <= END.  A zone is a list (LIMIT1 LIMIT2 . EXTRA) of two positions
 optionally followed by a list of extra stuff (any Lisp objects).
 And as stated above, the zone limits need not be in ascending
 order.

 The last difference is that each buffer position of a zone can be
 a marker, which means that a list of zones can specify zones in
 different buffers.  A zone position can also be a readable marker,
 which is a Lisp sexp that can be written to disk (e.g., as part of
 a bookmark or saved variable), and restored in a later Emacs
 session by reading the file where it is saved.


(@* "Zones and Overlays")
 ** Zones and Overlays **

 Zones have even more in common with Emacs overlays than they do
 with segments of a noncontiguous region.  An overlay has an
 associated buffer, two limits (start and end), and an optional
 list of properties.

 Zones differ from overlays in these ways:

 * A zone can have an identifier (izone).
 * A zone can have a readable Lisp form, by using numbers or
   readable markers.
 * A zone need not be specific to a particular buffer.  If a zone's
   positions are numbers instead of markers then you can use it in
   any buffer.
 * A set of zones can be persistent, by bookmarking it.

 You can create zones from overlays, and vice versa, using
 functions `zz-overlay-to-zone', `zz-zone-to-overlay',
 `zz-overlays-to-zones', and `zz-zones-to-overlays'.

 When creating zones from overlays you can specify how to represent
 the zone limits: using markers, readable markers, or positive
 integers.  And you can specify whether to create basic zones or
 izones.

 The resulting zone has ((:zz-overlay . PROPS)) as its list of
 extra information, where PROPS is the overlay's property list.  So
 the zone is (LIMIT1 LIMIT2 (:zz-overlay . PROPS)) (or the same
 with an identifier, if an izone).

 When creating overlays from zones, the presence of a list
 (:zz-overlay . PROPS) in the extra zone information results in the
 overlay having PROPS as its property list.  When creating a single
 such overlay you can optionally specify additional overlay
 properties, as well as arguments FRONT-ADVANCE and REAR-ADVANCE
 for function `make-overlay'.

 You can use function `zz-overlay-union' to coalesce overlays in a
 given buffer that overlap or are adjacent.


(@* "Izone Commands")
 ** Izone Commands **

 Commands that manipulate lists of zones generally use izones,
 because they make use of the zone identifiers.

 Things you can do with zones:

 * Sort them.

 * Unite (coalesce) adjacent or overlapping zones (which includes
   sorting them in ascending order of their cars).

 * Intersect them.

 * Narrow the buffer to any of them.  Cycle among narrowings.  If
   you use library `icicles.el' then you can also navigate among
   them in any order, and using completion against BEG-END range
   names.

 * Select any of them as the active region.  Cycle among them.

 * Search them (they are automatically coalesced first).  For this
   you need library `isearch-prop.el'.

 * Make a set of zones or its complement (the anti-zones)
   invisible.  For this you also need library `isearch-prop.el'.

 * Highlight and unhighlight them.  For this you need library
   `highlight.el' or library `facemenu+.el' (different kinds of
   highlighting).

 * Add zones of highlighted text (overlay or text-property
   highlighting).  For this you need library `highlight.el'.
   (You can highlight many ways, including dragging the mouse.)

 * Add the active region to a list of zones.

 * Add the active region to a list of zones, and then unite
   (coalesce) the zones.

 * Delete an izone from a list of zones.

 * Clone a zones variable to another one, so the clone has the same
   zones.

 * Clone a zones variable and then unite the zones of the clone.

 * Make an izone variable persistent, in a bookmark.  Use the
   bookmark to restore it in a subsequent Emacs session.  For this
   you need library `bookmark+.el'.

 * Query-replace over them (Emacs 25 and later).


(@* "Izone List Variables")
 ** Izone List Variables **

 Commands that use izones generally use a variable that holds a
 list of them.  By default, this is the buffer-local variable
 `zz-izones'.  But such a variable can be buffer-local or global.
 If it is global then it can use markers and readable markers for
 different buffers.

 The value of variable `zz-izones-var' is the variable currently
 being used by default for izone commands.  The default value is
 `zz-izones'.

 You can have any number of izones variables, and they can be
 buffer-local or global variables.

 You can use `C-x n v' (command `zz-set-izones-var') anytime to set
 `zz-izones-var' to a variable whose name you enter.  With a prefix
 argument, the variable is made automatically buffer-local.  Use
 `C-x n v' to switch among various zone variables for the current
 buffer (if buffer-local) or globally.

 Sometimes another zone command prompts you for the izones variable
 to use, if you give it a prefix argument.  The particular prefix
 arg determines whether the variable, if not yet bound, is made
 buffer-local, and whether `zz-izones-var' is set to the variable
 symbol:

  prefix arg         buffer-local   set `zz-izones-var'
  ----------         ------------   -------------------
  Plain `C-u'        yes            yes
  > 0 (e.g. `C-1')   yes            no
  = 0 (e.g. `C-0')   no             yes
  < 0 (e.g. `C--')   no             no

 For example, `C-u C-x n a' (`zz-add-zone') prompts you for a
 different variable to use, in place of the current value of
 `zz-izones-var'.  The variable you enter is made buffer-local and
 it becomes the new default izones variable for the buffer; that
 is, `zz-izones-var' is set to the variable symbol.

 As another example, suppose that `zz-izones-var' is `zz-izones',
 the default value and buffer-local by design.  If you then use
 `C-- C-x n a' and enter a variable name at the prompt, that
 variable is not made buffer-local, and `zz-izones-var' is not set
 to that variable.  The active region is pushed to the variable,
 but because `zz-izones-var' is unchanged, a subsequent `C-x n a'
 (no prefix arg) pushes to `zz-izones'.


(@* "Keys")
 ** Keys **

 Many of the commands that manipulate izones are bound on keymap
 `narrow-map'.  So they are available on prefix key `C-x n' (by
 default), along with the narrowing/widening keys `C-x n d', `C-x n
 n', `C-x n p', and `C-x n w'.  (If you use Emacs 22 then there is
 no `narrow-map', so the same `n ...' keys are bound on keymap
 `ctl-x-map'.)

 If you have already bound one of these keys then `zones.el' does
 not rebind that key; your bindings are respected.

 C-x n #   `zz-select-zone-by-id-and-text' - Select zone as region
 C-x n M-% `zz-query-replace-zones' - Query-replace within zones
 C-x n C-M-%                        - Regexp query-replace
 C-x n M-= ~ `isearchp-toggle-complementing-domain' -
             Toggle searching anti-zones
 C-x n M-= d `isearchp-toggle-dimming-outside-search-area' -
             Toggle dimming text that is outside the search area
 C-x n M-= v `isearchp-toggle-anti-zones-invisible' - Toggle
             visibility of the complement of (the union of) zones
 C-x n M-= V `isearchp-toggle-zones-invisible' - Toggle visibility
             of zones
 C-x n a   `zz-add-zone' - Add to current izones set (variable)
 C-x n A   `zz-add-zone-and-unite' - Add zone, then unite zones
 C-x n c   `zz-clone-zones' - Clone zones from one var to another
 C-x n C   `zz-clone-and-unite-zones' - Clone then unite zones
 C-x n d   `narrow-to-defun'
 C-x n D   `isearchp-remove-dimming' - Remove text dimming
 C-x n C-d `zz-delete-zone' - Delete an izone from current var
 C-x n f   `zz-set-zones-from-face' - Set zone set to face areas
 C-x n h   `hlt-highlight-regions' - Ad hoc zone highlighting
 C-x n H   `hlt-highlight-regions-in-buffers' - in multiple buffers
 C-x n l   `zz-add-zones-from-highlighting' - Add from highlighted
 C-x n L   `zz-set-zones-from-highlighting' - Set to highlighted
 C-x n n   `narrow-to-region'
 C-x n p   `narrow-to-page'
 C-x n P   `isearchp-put-prop-on-zones' - Add text property
 C-x n r   `zz-add-zones-matching-regexp' - Add regexp-match zones
 C-x n R   `zz-set-zones-matching-regexp' - Set zone set to matches
 C-x n C-r `isearchp-zones-backward' - Search backward within zones
 C-x n C-M-r                         - Regexp-search backward
 C-x n s   `zz-select-zone-repeat' - Cycle zones as active region
                                     (negative arg removes zone)
 C-x n C-s `isearchp-zones-forward' - Search forward within zones
 C-x n C-M-s                        - Regexp-search forward
 C-x n u   `zz-unite-zones' - Unite (coalesce) zones
 C-x n v   `zz-set-izones-var' - Set current zones-set variable
 C-x n w   `widen'
 C-x n x   `zz-narrow-repeat' - Cycle or pop zones as narrowings

 For the `hlt*' commands you need library `highlight.el': `C-x n
 h', `C-x n H'.  For the `isearchp-' commands you need library
 `isearch-prop.el': `C-x n M-= ~', `C-x n M-= d', `C-x n M-= v',
 `C-x n M-= V', `C-x n D', `C-x n P', `C-x n C-r', `C-x n C-M-r',
 `C-x n C-s', 'C-x n C-M-s`.


(@* "Command `zz-narrow-repeat'")
 ** Command `zz-narrow-repeat' **

 Library `zones.el' modifies commands `narrow-to-region',
 `narrow-to-defun', and `narrow-to-page' (`C-x n n', `C-x n d', and
 `C-x n p') so that the current buffer restriction (narrowing) is
 added to the izone list of the current buffer (by default,
 buffer-local variable `zz-izones').

 You can then use `C-x n x' to cycle or pop previous narrowings.
 Repeating `x' repeats the action: `C-x n x x x x' etc.  Each time
 you hit `x' a different narrowing is made current.  This gives you
 an easy way to browse your past narrowings.

 If the izone variable is not buffer-local then `zz-narrow-repeat'
 can cycle among the narrowings in different buffers, switching the
 buffer accordingly.

 Invoking `C-x n x' with a prefix argument changes the behavior
 as follows:

 * A plain prefix arg (`C-u') widens the buffer completely.

 * A zero numeric prefix arg (e.g `C-0') widens completely and
   resets (empties) the current izone variable.

 * A numeric prefix arg N takes you directly to the abs(N)th
   previous buffer narrowing.  That is, it acts abs(N) times.

 A negative arg work like a positive one, except that it also pops
 entries off the ring: it removes entries from the most recent back
 through the (-)Nth one.  For example, `C-- C-x n x x x' pops the
 last added narrowing each time you hit `x'.  You can thus use the
 list of recorded zones as a narrowing stack: narrow commands push
 to the stack, and `C-- C-x n x' pops it.

 By default, `C-x n x' is bound to command `zz-narrow-repeat'.
 (For Emacs versions prior to 22 it is bound by default to
 `zz-narrow', which is a non-repeatable version.  Repeatability is
 not available before Emacs 22.)

 The mode-line lighter `Narrow' is still used for the ordinary
 Emacs narrowing commands.  But for `zz-narrow-repeat' (`C-x n x')
 the current narrowing is indicated in the lighter by an
 identifying number: `Narrow-1', `Narrow-2', and so on.  `mouse-2'
 on the `Narrow' part still widens completely, but `mouse-2' on the
 `-NUM' part uses `zz-narrow-repeat' to cycle to the next
 narrowing.

 If option `zz-narrowing-use-fringe-flag' is non-nil then the face
 of the selected frame's fringe is set to `zz-fringe-for-narrowing'
 whenever the buffer is narrowed.  This shows you that the current
 buffer is narrowed even if the mode-line does not.


(@* "Define Your Own Commands")
 ** Define Your Own Commands **

 Pretty much anything you can do with the Emacs region you can do
 with a set of zones (i.e., with a non-contiguous "region").  But
 existing Emacs commands that act on the region do not know about
 non-contiguous regions.  What you will need to do is define new
 commands that take these into account.

 You can define your own commands that iterate over a list of
 izones in a given buffer, or over such lists in a set of buffers.
 Utility functions `zz-basic-zones', `zz-basic-zones-in-bufs', and
 `zz-read-bufs', `zz-do-zones', `zz-do-izones', `zz-map-zones', and
 `zz-map-izones' can help with this.

 As examples of such commands, if you use library `highlight.el'
 then you can use `C-x n h' (command `hlt-highlight-regions') to
 highlight the izones recorded for the current buffer.  You can use
 `C-x n H' (command `hlt-highlight-regions-in-buffers') to do the
 same across a set of buffers that you specify (or across all
 visible buffers).  If option `hlt-auto-faces-flag' is non-nil then
 each zone gets a different face.  Otherwise, all of the zones are
 highlighted with the same face.  Complementary (unbound) commands
 `hlt-unhighlight-regions' and `hlt-unhighlight-regions-in-buffers'
 unhighlight.

 Defining your own command can be simple or somewhat complex,
 depending on how the region is used in the code for the
 corresponding region-action Emacs command.  The definition of
 `hlt-highlight-regions' just calls existing function
 `hlt-highlight-region' once for each recorded zone:

(defun hlt-highlight-regions (&optional regions face msgp mousep
                                        buffers)
  "Apply `hlt-highlight-region' to regions in `zz-izones'."
  (interactive (list (zz-basic-zones zz-izones)
                     nil
                     t
                     current-prefix-arg))
  (dolist (start+end  regions)
    (hlt-highlight-region (nth 0 start+end) (nth 1 start+end)
                          face msgp mousep buffers)))

 That's it - just iterate over `zz-izones' with a function that
 takes a zone as an argument.  What `zones.el' offers in this
 regard is a way to easily define a set of buffer zones.


(@* "Automatically Create Zones on Region Deactivation")
 ** Automatically Create Zones on Region Deactivation **

 Minor mode `zz-auto-add-region-as-izone-mode' automatically adds
 the nonempty region as an izone upon its deactivation.  The zone
 is added to the current value of `zz-izones-var'.