This library contains the `org-translate-mode' minor mode to be
used on top of Org, providing translation-related functionality.
It is not a full-fledged CAT tool.  It essentially does two things:
manages segmentation correspondences between the source text and
the translation, and manages a glossary which can be used for
automatic term translation, displaying previous usages, etc.

Buffer setup:

The mode currently assumes a single file holding a single
translation project, with three separate top-level headings for
source text, translation, and glossary (other headings will be
ignored).  The three customization options
`ogt-default-source-locator', `ogt-default-translation-locator' and
`ogt-default-glossary-locator' can be used to tell the mode which
heading is which; by default it expects a buffer that looks like
this:

* Le Rouge et le Noir                                     :source:
  La petite ville de Verrières peut passer pour...

* The Red and the Black                              :translation:
  The small town of Verrieres may be regarded...

* Glossary
** ville de Verrières

In other words, tags are used to find the source and translation
texts, while the glossary heading is just called "Glossary".  This
is also configurable on a per-project basis, using the
`ogt-translation-projects' option.

Segmentation

The first time you start this mode in a new translation project
buffer (after first setting up the three headings appropriately),
the mode will detect that the project has not yet been segmented,
and will offer to do so.  Segmentation involves inserting the value
of `ogt-segmentation-character' at intervals in the source text.
As you progress through the translation, you'll insert that same
character at corresponding places in the translation text, allowing
the minor mode to keep track of which segment corresponds to which,
and to keep the display of source and translation synchronized.

The option `ogt-segmentation-strategy' determines how the source
text is segmented.  Currently the options are to segment by
sentence, by paragraph, or by regular expression.  Note that, after
initial segmentation, the minor mode will leave the segmentation
characters alone, and you're free to insert, delete or move them as
needed.

As you reach the end of each translation segment, use "C-M-n"
(`ogt-new-segment') to insert a segmentation character and start a
new segment.  The character should be inserted at the _beginning_
of the new segment, not at the end of the last -- eg at the start
of a paragraph or sentence.

Use "C-M-f" and "C-M-b" to move forward and backward in the
translation text by segment.  This will allow the minor mode to
keep the corresponding source segment in view.  Alternately, move
point however you like in the translation text, then use "C-M-t" to
update the source view.

The glossary

This mode also maintains a glossary of translation terms for the
current project.  Currently it does this by keeping each term as a
subheading under the top-level glossary heading.  Each subheading
has an ID property, and this property is used to create links in
the source and translation text, pointing to the glossary item in
question.  The mode keeps tracks of the various ways you've
translated a term previously, and offers these for completion on
inserting a new translation.

To create a new glossary term, use "C-M-y".  If you've marked text
in the source buffer, this will become the new term, otherwise
you'll be prompted to enter the string.  This command will attempt
to turn all instances of this term in the source text into a link.

In the translation text, use "C-M-;"
(`ogt-insert-glossary-translation') to add a translation.  The mode
will attempt to guess which term you're adding, and suggest
previous translations for that term.  If you don't want it to
guess, use a prefix argument to be prompted.

Bookmarks

The functions `ogt-start-translating' and `ogt-stop-translating'
can be used to start and stop a translation session.  The first use
of the latter command will save the project in your bookmarks file,
after which `ogt-start-translating' will offer the project to work
on.

TODO:

- Generalize the code to work in text-mode as well as Org,
  using 2C-mode instead of Org subtrees.
- Support multi-file translation projects.
- Import/export TMX translation databases.
- Provide for other glossary backends: eieio-persistent, xml,
  sqlite, etc.
- Do this by allowing the glossary locator to point at a named Org
  table, or at a babel source block, allowing users to maintain
  the glossary outside of Org altogether.
- Provide integration with `org-clock': set a custom property on a
  TODO heading indicating that it represents a translation project.
  Clocking in both starts the clock, and sets up the translation
  buffers.  Something like that.