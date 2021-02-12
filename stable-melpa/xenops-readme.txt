The main user actions in Xenops are:

xenops-render
xenops-reveal
xenops-regenerate
xenops-execute

Those four verbs are examples of *operations*. The `xenops-ops' data structure defines the set
of Xenops operations.

Operations are done on *elements*. An element is a special substring of the buffer such as a
math block, a table, a minted code block, a footnote, an \includegraphics link, etc. The set of
Xenops element types is defined by the `xenops-elements' data structure. An element string is
parsed into a plist data structure, that we also refer to as an element. The :type key of the
plist holds the type of the element (`'block-math`, `'table`, `'minted`, `footnote`, `'image`,
etc).

The organizing principle of Xenops is that a user action consists of applying an operation to a
set of elements. The set of elements is determined by the context under which the action was
invoked: either a single element at point, or all elements in the active region, or all elements
in the buffer.

Xenops carries out such a user action as follows:

1. Identify the set of *handlers* corresponding to the operation. A handler is a function that
   takes an element plist as its first argument. The mapping from operations to handlers is
   defined in the `xenops-ops' data structure.

2. Visit each element in sequence:

   2.1 At an element, select a single handler which is valid for that element type. (There will
       usually be only one choice.) The mapping from element types to valid handlers is defined
       in the `xenops-elements' data structure.

   2.2 Call the selected handler on the element.

This traversal and dispatch-to-handler logic is implemented in xenops-apply.el.

The handler for the `render` operation on elements of type `block-math`, `inline-math`, and
`table` involves calling external latex and dvisvgm processes to generate an SVG image. This is
done asynchronously, using emacs-aio.
