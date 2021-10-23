			     ━━━━━━━━━━━━━
			      SKETCH MODE
			     ━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Prepreliminary comment
2. Preliminary comment
.. 1. Included features
.. 2. Incomplete features (merged into main)
.. 3. Delicious low hanging fruit
.. 4. Less low hanging fruit
3. Requirements
4. Installation
.. 1. Spacemacs
5. Usage
6. Bugs
7. Alternatives
8. Sponsor the project


*Please read the [requirements] section below before trying this
 package*


[requirements] See section 3


1 Prepreliminary comment
════════════════════════

  The initial version with the transient can be found in the
  'transient-version' branch. A second version using a hydra can be
  found in the 'hydra version'.  This version has a toolbar which made
  the transient unnecessary. Which makes the transient unnecessary,
  while removing the transient frees up drawing space. Initially this
  version used a hydra. But using a hydra just complicates things if its
  purpose is to show keybindings only. So finally this version simply
  uses a side buffer to show keybindings.

  Also an earlier version showed the mouse coordinates in the mode-line.
  However, this functionality hinders the 'interactive' drawing (which
  might be due to an emacs 'bug'). Anyway, you can toggle showing the
  coordinates by pressing `t c' (maybe it works more fluently on your
  system).


2 Preliminary comment
═════════════════════

  This is a new package that is still in development. It has been on
  ELPA-devel for a while now, but it did not yet attract any code
  contributors. However, despite that the code and docs are far from
  polished/finished, its main functionality is very usable already, so
  that it is probably a good time to publish it on ELPA. On the other
  hand, several (or most) features are not implemented completely,
  simply because implementing these things take time, and I should first
  focus on keeping myself alive 😐. But if you know some elisp, than it
  should be quite straightforward to complete the implementation of
  those features (and create a PR). The idea is that elisp users can add
  functionalities easily so that the package becomes ever more
  versatile. Users can also contribute by creating SVG snippets (in a
  separate repo, or create a PR). Any feedback, for example suggestions
  for enhancing the interface/usability (and of course bug reports), is
  very welcome (probably best by opening an issue). Also, any
  contributions are very welcome. The code of the package is very
  accessible (especially if you quickly read how to use [edebug]).

  A list of ideas for implementation can be found in the preliminary
  comment in the `sketch.el' file and additionally in the [wiki]
  section.


[edebug]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Edebug.html>

[wiki] <https://github.com/dalanicolai/sketch-mode/wiki/vision>

2.1 Included features
─────────────────────

  • mnemonic shortcuts
  • toolbar
  • quickly insert image definition into new type (image) org-block with
    the image rendered as overlay (no external file required)
  • snap to grid (on minor-grid, however major and minor grid are fully
    configurable)
  • draw text
  • crop final image
  • set stroke, fill, width etc.
  • show dom (lisp) in other window
  • draw angle arcs (between lines, available soon, I hope. See
    `implement-angle-arc' branch)


2.2 Incomplete features (merged into main)
──────────────────────────────────────────

  • Draw labels (not implemented for all type of objects. Easy to
    implement)

    It would be handy to have a 'transform group' option also. [SVG
    groups allow for easy transformations]. Then it would probably be
    handy to wrap all objects in group tags.


[SVG groups allow for easy transformations]
<https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/transform>


2.3 Delicious low hanging fruit
───────────────────────────────

  • use svg snippets (i.e. design object in external programs like
    inkscape, geogebra etc., end quickly insert them in your sketches)


2.4 Less low hanging fruit
──────────────────────────

  • draw directly in you literate org file, with the dom updated in your
    source block
  • export to tikz, asymptote, other image extensions etc. (probably
    requires to implement 'nodes')

  The `sketch-mode.el' file starts with listing TODO items describing
  features that are missing from the package.

  <file:./happy-sketching.gif> *THIS SCREENCAST STILL SHOWS THE
  SKETCH-MODE TRANSIENT VERSION. AN UPDATED SCREENSHOT WILL HOPEFULLY
  ARRIVE TOMORROW*


3 Requirements
══════════════

  This package requires Emacs to have been build with SVG support (I
  guess that, in other words, this means it must have been build with
  cairo support, but I still have to find out)


4 Installation
══════════════

  The package is available from [GNU ELPA], so it can simply get
  installed as usual. However, the publishing 'cycle' on ELPA is
  somewhat slow, while development on this package is 'less slow'. So
  you might prefer to install from github directly as follows:

  Either `git clone' the package and load `sketch-mode.el' using `load
  file' either manually or from `.emacs.d'.

  When installing the package it probably still shows some warnings, you
  can safely ignore them.

  Alternatively you could use with the following recipe:
  ┌────
  │ (quelpa '(sketch-mode :repo "dalanicolai/sketch-mode" :fetcher github))
  └────
  then subsequently load the package with
  ┌────
  │ (use-package sketch-mode
  │   :defer t)
  └────


[GNU ELPA] <https://elpa.gnu.org/packages/sketch-mode.html>

4.1 Spacemacs
─────────────

  The package is available from [GNU ELPA], so it can simply get
  installed by simply adding `sketch-mode' to
  `dotspacemacs-additional-packages'. However, the publishing 'cycle' on
  ELPA is somewhat slow, while development on this package is 'less
  slow'. So you might prefer to install from github directly as follows:

  ┌────
  │ (sketch-mode :location (recipe
  │ 		   :fetcher github
  │ 		   :repo "dalanicolai/sketch-mode"
  │ 		   :files ("*.el" "snippet-files")))
  └────

  Subsequently load the packages by adding the following line to
  `dotspacemacs/user-config'

  ┌────
  │ (use-package sketch-mode
  │   :defer t)
  └────


[GNU ELPA] <https://elpa.gnu.org/packages/sketch-mode.html>


5 Usage
═══════

  Start a sketch with `M-x sketch' and enter values at the prompts (or
  prefix with `C-u' to use default values). Although, thanks to the key
  help buffer, the usage is more or less self explanatory, it is wise to
  take note of the following comments:

  • use `C-c C-c' to quickly insert the xml-definition into the
    (org-mode) buffer from which sketch-mode was called and create the
    image as an overlay.  The image will get inserted within a new
    `image' org block type. SVG/XML is suitable for inserting directly
    in an org file so that you do not need to store the image separately
    on disk (which is nice feature when sharing files). The new block
    type is not yet 'officially supported' by org-mode, so that it will
    not yet get exported as an image (HELP WANTED :nerd:), but the image
    in the code block can be toggle with `C-c C-c'.
  • Alternatively you can write the image to a file by pressing `S'
    (S-ave).
  • Before you insert the image you can use `C-S mouse-drag' to crop the
    image.
  • You can move an object by pressing `m' to open the 'modify-object'
    state.  This will select the object and activate the `translate'
    mouse action so that you can drag the object using the mouse.
  • to remove an object (without using undo), you should press `d', and
    then the label of the object you want removed.
  • You can also modify the drawing by changing the object definition
    (i.e.  elisp). For that press `D' to open the definition in a
    side-window, then press `.' to toggle the key help buffer. Now
    modify the code and press `C-c C=c', to load it and update the
    `\*sketch\*' buffer.


6 Bugs
══════

  Currently when undoing all (drawing of) objects, sketch-mode gets
  confused and further drawing is not possible anymore (although redoing
  is). This is probably a very easy to solve bug, but has not been a
  priority yet.


7 Alternatives
══════════════

  [canvas-mode]: An even newer package is being created which provides
  some additional features (although `sketch-mode' is still in
  development and most probably will get most of these features
  too). Unfortunately, the package is not (yet?) very compatible with
  `sketch-mode'.


[canvas-mode]
<https://lifeofpenguin.blogspot.com/2021/08/scribble-notes-in-gnu-emacs.html>


8 Sponsor the project
═════════════════════

  It takes me a lot of time to develop (this) package(s), while, as we
  would say in the Netherlands, I have no penny to scratch my
  butt. Therefore, although I am also really happy to offer it for free,
  if you find [my package(s)] (real projects page in the making) useful
  (e.g. for you work), and if you can afford it, then I would be very
  happy with any donation (of course that would also enable me to work
  on your feature requests). As soon as I have the
  opportunity/possibility to find a stable job, I will happily suggest
  you to transfer or donate to other projects/charity instead.

  If you would like to `boost' development of any of my projects, then
  contribute (code or documentation), or consider more sustainable
  financial support (i.e. sponsor).

  Accepted donation methods [liberapay] [PayPal donate]


[my package(s)] <https://github.com/dalanicolai>

[liberapay] <https://en.liberapay.com/dalanicolai/>

[PayPal donate]
<https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6BHLS7H9ARJXE&source=url>
