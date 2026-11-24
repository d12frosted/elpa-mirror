                              ━━━━━━━━━━━
                               AU-THEMES
                              ━━━━━━━━━━━


[https://elpa.nongnu.org/nongnu/au-themes.svg]
[https://github.com/szymonwilczek/au-themes/actions/workflows/test.yml/badge.svg]
[https://img.shields.io/badge/license-GPL–3.0–or–later-blue.svg]

Go to the [light] or the [dark] themes, [installation], [usage], the
[list of families] or the [community].

Calm, low-glare colour themes. Made first of all for autistic people,
and for anyone who finds most themes too loud to read for long.

The name comes from Au, the chemical symbol for gold. Many autistic
people use gold as the symbol of autism acceptance, in place of the blue
puzzle piece.


[https://elpa.nongnu.org/nongnu/au-themes.svg]
<https://elpa.nongnu.org/nongnu/au-themes.html>

[https://github.com/szymonwilczek/au-themes/actions/workflows/test.yml/badge.svg]
<https://github.com/szymonwilczek/au-themes/actions/workflows/test.yml>

[https://img.shields.io/badge/license-GPL–3.0–or–later-blue.svg]
<file:LICENSE>

[light] See section Light themes

[dark] See section Dark themes

[installation] See section Installation

[usage] See section Usage

[list of families] See section Themes

[community] See section Community


Screenshots
═══════════

  Click a picture to open it in full size, or a name to see that theme
  in code, Magit, Dired and Org on the blog.


Light themes
────────────


Dark themes
───────────


Emacs
═════

Requirements
────────────

  • Emacs 29.1 or newer
  • [modus-themes] 5.2.0 or newer

  The Emacs themes are built on top of modus-themes by [Protesilaos
  Stavrou], and their shared semantic mappings come from his
  ef-themes. His work gives us face coverage for hundreds of packages
  and a solid base to build palettes on. Thank you, Prot.


[modus-themes] <https://github.com/protesilaos/modus-themes>

[Protesilaos Stavrou] <https://protesilaos.com>


Installation
────────────

  `au-themes' is available on [NonGNU ELPA], which is enabled by default
  starting with Emacs 28.1.

  Install it with:

  ┌────
  │ M-x package-install RET au-themes RET
  └────

  Or in your configuration:

  ┌────
  │ (use-package au-themes
  │   :ensure t
  │   :config
  │   (load-theme 'au-salina-night t))
  └────


[NonGNU ELPA] <https://elpa.nongnu.org/nongnu/au-themes.html>

From source
╌╌╌╌╌╌╌╌╌╌╌

  You can also clone the repository manually:

  ┌────
  │ git clone https://github.com/szymonwilczek/au-themes.git ~/.emacs.d/au-themes
  └────

  ┌────
  │ (add-to-list 'load-path "~/.emacs.d/au-themes")
  │ (require 'au-themes)
  │ (load-theme 'au-salina-night t)
  └────

  Or with `package-vc-install' on Emacs 30 or newer:

  ┌────
  │ (use-package au-themes
  │   :vc (:url "https://github.com/szymonwilczek/au-themes" :rev :newest)
  │   :config
  │   (load-theme 'au-salina-night t))
  └────


Usage
─────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Command                   What it does                             
  ────────────────────────────────────────────────────────────────────
   `au-themes-select'        pick a theme with live preview           
   `au-themes-select-light'  pick from light themes only              
   `au-themes-select-dark'   pick from dark themes only               
   `au-themes-toggle'        switch between last light and dark theme 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  With [consult] installed, the preview goes through `consult-theme'.
  Without it, a theme is previewed once its full name is in the
  minibuffer. `C-g' always brings back the theme you had before.

  `au-themes-toggle' switches between `au-salina-day' and
  `au-salina-night' until you pick other themes. Change the default pair
  in `au-themes-toggle-themes'.


[consult] <https://github.com/minad/consult>


Why
═══

  I have a hard time reading code on most themes. Bright backgrounds
  tire me out quickly, strong colours stay in my eyes after I look away,
  and busy highlighting makes it hard to follow a line. Many autistic
  people describe the same thing, so we started making themes that are
  easier on the eyes.

  There are two of us. I write the code. My girlfriend has a good eye
  for colour and picks the palettes with me, so they look calm and
  belong together.


Who it is for
═════════════

  • autistic people, and anyone who gets overwhelmed by visual noise,
  • people with astigmatism,
  • people who are sensitive to light,
  • anyone who spends long hours reading text on a screen.


Themes
══════

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Family        Variants                   Mood                                                         
  ───────────────────────────────────────────────────────────────────────────────────────────────────────
   Whispergrove  `night', `morning', `day'  muted greens and earth tones of a quiet forest               
   Aurum         `night', `day'             warm amber and gold, with little blue light                  
   Parchment     `night', `day'             almost monochrome; italics and brightness instead of colour  
   Salina        `night', `day'             the coast: salt flats, sand, deep ocean, driftwood and coral 
   Herbarium     `night', `day'             pressed sage, dried lavender, oak-gall ink, chamomile        
   Perseida      `night', `day'             an August meteor night and its dawn, star-coloured syntax    
   Yerba         `night', `day'             a yerba mate gourd: dried leaf, Ilex berries and steam       
   Pluvia        `night', `day'             rain behind the window of a quiet home, by night and by day  
   Mysterium     one dark theme             Halloween: an old painted van outside a haunted mansion      
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Full names follow the pattern `au-<family>-<variant>', for example
  `au-salina-night'.  A seasonal theme with one polarity drops the
  variant: `au-mysterium'.

  Which one to try first:

  • `night' variants are for dark rooms and evenings. Of these,
    `aurum-night' gives off the least of the blue light that keeps you
    awake. `perseida-night' has the darkest background of the
    collection, almost black, so the frame blends into a dark bezel or
    notch.
  • `day' variants are for daylight. `whispergrove-morning' has a dimmer
    background than the other light themes, for early mornings or a room
    with little light.  `perseida-day' is the one light theme on a cool
    pearl background instead of warm paper; it gives off more blue light
    than the others, though still far below any safety limit.
  • `parchment' suits anyone who finds even calm syntax colours too
    busy.


How the colours are chosen
══════════════════════════

  We pick colours by hand and check each palette against these rules:

  • Text contrast is measured with APCA. Enough to read, not so much
    that it glares.
  • Main text colour has low saturation, so letters do not get coloured
    fringes.
  • Tokens that often sit next to each other (e.g. `static' and a type,
    or a return type and a function name) get clearly different colours.
  • Brackets and punctuation are a bit dimmer than names, so they do not
    crowd the words.
  • Neighbouring colours differ in brightness, not only in hue, so the
    line does not seem to shimmer.
  • Colours stay distinguishable under simulated colour blindness
    (Brettel et al. 1997): seven key pairs, such as keyword and type,
    stay at least 10 dE00 apart for every type of dichromacy, and no two
    token colours come closer than 3 dE00.

  The test suite checks every theme against these rules and many more;
  [tests/README.org] explains how it works and how to run it. The
  sources are listed in [REFERENCES.org].


[tests/README.org] <file:tests/README.org>

[REFERENCES.org] <file:REFERENCES.org>


Community
═════════

  New themes and fixes start from what people tell us in [Discussions]:

  • [Propose a theme] from a mood, a place or a season. You do not need
    to pick the colours; we work them out with you.
  • [Tell us] when a theme is hard to read or tiring, and where.
  • [Suggest a feature] for the package, or [ask a question].
  • Follow [What's cooking] to see what we are working on.

  Bugs go to the [issue tracker].

  If the themes help you, [sponsoring] gives us the time for new
  families.


[Discussions] <https://github.com/szymonwilczek/au-themes/discussions>

[Propose a theme]
<https://github.com/szymonwilczek/au-themes/discussions/categories/theme-proposals>

[Tell us]
<https://github.com/szymonwilczek/au-themes/discussions/categories/theme-feedback>

[Suggest a feature]
<https://github.com/szymonwilczek/au-themes/discussions/categories/ideas>

[ask a question]
<https://github.com/szymonwilczek/au-themes/discussions/categories/q-a>

[What's cooking]
<https://github.com/szymonwilczek/au-themes/discussions/7>

[issue tracker]
<https://github.com/szymonwilczek/au-themes/issues/new/choose>

[sponsoring] <https://github.com/sponsors/szymonwilczek>


License
═══════

  GPL-3.0-or-later. See [LICENSE].


[LICENSE] <file:LICENSE>


Credits
═══════

  • Protesilaos Stavrou, author of [modus-themes], which the Emacs
    themes are built on, and of [ef-themes], whose semantic mappings
    they share.


[modus-themes] <https://github.com/protesilaos/modus-themes>

[ef-themes] <https://github.com/protesilaos/ef-themes>


References
══════════

  The papers and standards behind the colour rules and the tests are
  listed in [REFERENCES.org].


[REFERENCES.org] <file:REFERENCES.org>
