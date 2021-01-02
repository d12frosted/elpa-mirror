I keep a collection of quotations, mostly for use in mail
signatures. Naturally (for me :-), I keep them in XML. These
functions extract quotations from this file.

Prerequisites:

This file requires xml.el by Emmanuel Briot. Recent versions of
emacs (at least 21.1 and beyond) include xml.el.

You must have a quotations file. I keep mine in ~/.quotes.xml.

<?xml version="1.0" encoding="utf-8"?>
<quotations>
<quote>Everything should be made as simple as possible, but no
simpler.</quote>

<quote by="Robert Frost">We dance around in a ring and suppose,
but the Secret sits in the middle and knows.</quote>

<!-- ... -->

</quotations>

Usage:

(xml-quotes-quotation)

Returns the next quotation.

(xml-quotes-quotation n)

Returns the n'th quotation. This sets the next quotation to n+1.
