If you are working with XML documents, the parsed data structure
returned by the XML parser (xml.el) may be enough for you: Lists of
lists, symbols, strings, plus a number of accessor functions.

If you want a more elaborate data structure to work with your XML
document, you can create a document object model (DOM) from the XML
data structure using doom.el.

You can create a DOM from XML using `doom-make-document-from-xml'
with the input from `libxml-parse-xml-region'. See function documentation
below for an example

This library is called doom instead of dom because Emacs now comes
with its own library called dom which does something slightly
different.

; On Interfaces and Classes

The elisp DOM implementation uses the doom-node structure to store all
attributes.  The various interfaces consist of sets of functions to
manipulate these doom-nodes.  The functions of a certain interface
share the same prefix.
