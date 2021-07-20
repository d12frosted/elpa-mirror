This directory contains add-ons to Org-mode which are not part of Org.

These files used to live in the Org repository but have been filtered
out of the Org 9.5 release. They are stored here for archival purpose.
The =contrib/= directory used to contain a =scripts/= directory that now
lives on [[https://code.orgmode.org/bzg/worg/src/master/code][the Worg repository]].

*This repository receives no maintainance.*

** Please help with maintaining these files

Especially, there is no guaranty that it is compatible with the latest
Org stable version.  Would you would like to volunteer maintaining it?
If so, please send me an email at =bzg@gnu.org=.

If you want to maintain only one or some of these add-ons please send
me an email and consider hosting the add-ons on a separate repository.

Files which are already maintained outside of the repository and will
be removed from the next release of =org-contrib=.

** License

All files in this repository are licensed under the GNU General Public
License, either version 3 of the License, or (at your option) any
later version.  See [[file:COPYING][COPYING]].
  
** Files to remove from the next release

These files are maintained in a separate repository, which you can
find after the "Homepage:" keyword in the files themselves:

- ob-mathematica.el :: org-babel functions for Mathematica evaluation
- org-link-edit.el :: Slurp and barf with Org links
- ol-notmuch.el :: Links to notmuch messages

** Other files
*** Org utils

- org-annotate-file.el :: Annotate a file with org syntax
- org-attach-embedded-images.el :: Transmute images to attachments
- org-bibtex-extras.el :: Extras for working with org-bibtex entries
- org-checklist.el :: org functions for checklist handling
- org-choose.el :: Use TODO keywords to mark decision states
- org-collector.el :: Collect properties into tables
- org-contacts.el :: Contacts management
- org-contribdir.el :: Dummy file to mark the org contrib Lisp directory
- org-depend.el :: TODO dependencies for Org-mode
- org-effectiveness.el :: Measuring your personal effectiveness
- org-eldoc.el :: Eldoc documentation for SRC blocks
- org-eval-light.el :: Evaluate in-buffer code on demand
- org-eval.el :: The <lisp> tag, adapted from Muse
- org-expiry.el :: Expiry mechanism for Org entries
- org-git-link.el :: Provide org links to specific file version
- org-interactive-query.el :: Interactive modification of tags query
- org-invoice.el :: Help manage client invoices in OrgMode
- org-learn.el :: SuperMemo's incremental learning algorithm
- org-license.el :: Insert free licenses to your org documents
- org-link-edit.el :: Slurp and barf with Org links
- org-mac-iCal.el :: Imports events from iCal.app to the Emacs diary
- org-mac-link.el :: Grab links and URLs from various Mac applications
- org-mairix.el :: Hook mairix search into Org for different MUAs
- org-notify.el :: Notifications for Org-mode
- org-panel.el :: Simple routines for us with bad memory
- org-passwords.el :: Org derived mode for managing passwords
- org-registry.el :: A registry for Org links
- org-screen.el :: Visit screen sessions through Org-mode links
- org-screenshot.el :: Take and manage screenshots in Org-mode files
- org-secretary.el :: Team management with org-mode
- org-static-mathjax.el :: Muse-like tags in Org-mode
- org-sudoku.el :: Create and solve SUDOKU puzzles in Org tables
- org-toc.el :: Table of contents for Org-mode buffer
- org-track.el :: Keep up with Org development
- org-velocity.el :: something like Notational Velocity for Org
- org-wikinodes.el :: CamelCase wiki-like links for Org

*** Org exporters

- ox-bibtex.el :: Export bibtex fragments
- ox-confluence.el :: Confluence Wiki exporter
- ox-deck.el :: deck.js presentations exporter
- ox-extra.el :: Convenience functions for org export
- ox-freemind.el :: Freemind exporter
- ox-groff.el :: Groff exporter
- ox-koma-letter.el :: KOMA Scrlttr2 exporter
- ox-rss.el :: RSS 2.0 exporter
- ox-s5.el :: S5 presentations exporter
- ox-taskjuggler.el :: TaskJuggler exporter

*** Org link

- ol-bookmark.el :: Links to bookmarks
- ol-elisp-symbol.el :: Links to Emacs-lisp symbols
- ol-git-link.el :: Links to specific file version
- ol-man.el :: Links to man pages
- ol-mew.el :: Links to Mew messages
- ol-notmuch.el :: Links to notmuch messages
- ol-vm.el :: Support for links to VM messages
- ol-wl.el :: Support for links to Wanderlust messages

*** Org Babel languages

- ob-arduino.el :: Org-mode Babel support for Arduino
- ob-clojure-literate.el :: Clojure's Org-mode Literate Programming
- ob-csharp.el :: org-babel functions for csharp evaluation
- ob-eukleides.el :: Org-babel functions for eukleides evaluation
- ob-fomus.el :: Org-babel functions for fomus evaluation
- ob-julia.el :: Org-babel functions for julia evaluation
- ob-mathematica.el :: org-babel functions for Mathematica evaluation
- ob-mathomatic.el :: Org-babel functions for mathomatic evaluation
- ob-oz.el :: Org-babel functions for Oz evaluation
- ob-php.el :: Execute PHP within org-mode blocks
- ob-redis.el :: Execute Redis queries within org-mode blocks
- ob-sclang.el :: SCLang support for Org-mode Babel
- ob-smiles.el :: Org-mode Babel support for SMILES
- ob-spice.el :: org-babel functions for spice evaluation
- ob-stata.el :: Org-babel functions for Stata evaluation
- ob-tcl.el :: Org-babel functions for tcl evaluation
- ob-vbnet.el :: org-babel functions for VB.Net evaluation

