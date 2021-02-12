
This extension works similar to http://orgmode.org/manual/Speed-keys.html,
while adding in a bit of vi flavor.

Representing the point with "|", pressing a-z, A-Z, or 0-9 while
the text is as below will call a command instead of inserting these
characters:

  |* foo
  *|* bar
  |#+ baz

As you see, the general theme is beginning of line + org markup.
Below, "#+..." will be referred to as markup.
Similar to vi, "hjkl" represent the arrow keys:

- "j" moves down across headings and markup, but does not switch
  between either: use "h"/"l" for that. The exception is the first
  markup in the file that does not belong to any heading.

- "k" moves up across headings and markup, with same rules as "j".

- "h" moves left, i.e. to the parent heading of current thing.
  You can use it e.g. to go from fifth level 3 heading to the
  parent level 2 heading, or from the second source block to the
  parent heading.

- "l" moves right (i.e. to the first child of current heading).
  You can use it to get to the first markup of current heading.

Worf borrows the idea of verbs and nouns from vi: the commands are
sentences, combinations of a verb and a noun used together.
Verb #1 is "goto", which is implicit and active by default.

5 nouns are available currently:
"h" - left
"j" - down
"k" - up
"l" - right
"a" - add heading
"p" - property

Verb #2 is `worf-change-mode', bound to "c". Verbs in worf are
sticky: once you press "c", change verb will be active until you
switch to a different verb. This is different from vi, where the
verb will deactivate itself after the first command.

Use the same letter to deactivate a verb as to activate it,
i.e. "c" will deactivate `worf-change-mode'.  "q" will universally
deactivate any verb and return you to "goto" implicit verb.

While `worf-change-mode' is active, "hjkl" move the current heading
in appropriate directions: it's the same as holding "M-" and using
arrow keys in the default org.
"p" will change the selected property.

Verb #3 is `worf-change-tree-mode', bound to "cf".  While
`worf-change-tree-mode' is active, "hjkl" move the current heading
tree in appropriate directions: it's the same as holding "S-M-" and
using arrow keys in the default org.

Verb #4 is `worf-change-shift-mode', bound to "cs".
It make "hjkl" act as "S-" and arrows in default org.

Verb #5 is `worf-keyword-mode', bound to "w". You select a keyword
e.g. TODO or NEXT and "j"/"k" move just by the selected keyword,
skipping all other headings. Additionally "a" will add a new
heading with the appropriate keyword, e.g. "wta" will add a new
TODO, and "wna" will add a new "NEXT".

Verb #6 is `worf-clock-mode', bound to "C". This one isn't sticky
and has only two nouns that work with it "i" (in) and "o" (out).

Verb #7 is `worf-delete-mode', bound to "d". This one isn't sticky
and changes the behavior of "j" to delete down, and "k" to delete
up. You can mix in numbers to delete many times, i.e. d3j will
delete 3 headings at once.
"p" will delete the selected property.

Verb #8 is `worf-yank-mode', bound to "y". It's similar to
`worf-delete-mode', but will copy the headings into the kill ring
instead of deleting.

Verb #9 is `worf-mark-mode', bound to "m". It's similar to
`worf-delete-mode', but will mark the headings instead.

Some other things included in worf, that don't fit into the
verb-noun structure, are:

 - "o" (`worf-ace-link'): open a link within current heading that's
   visible on screen. See https://github.com/abo-abo/ace-link for a
   package that uses this method in other modes.

 - "g" (`worf-goto'): select an outline in the current buffer, with
   completion.  It's very good when you want to search/navigate to
   a heading by word or level. See https://github.com/abo-abo/lispy
   for a package that uses this method to navigate Lisp code.

 - "L" (`worf-copy-heading-id'): copy the link to current heading
   to the kill ring. This may be useful when you want to create a
   lot of links.
