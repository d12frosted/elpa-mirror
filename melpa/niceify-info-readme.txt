Emacs' Info manuals are extremely rich in content, but the user
experience isn't all that it could be; an Emacs process contains a
lot of information about the same things that Info manuals
describe, but vanilla Info mode doesn't really do much to take
advantage of that.  Niceify-info remedies this.

To improve a single Info page, do M-x niceify-info in that page's
buffer.  If you decide you like the effect so much that you want it
applied to all Info pages you visit, add the `niceify-info'
function to `Info-selection-hook' in your init file.  For example:

    (add-hook 'Info-selection-hook #'niceify-info)

This function applies a set of changes I call "niceification",
because I have a longstanding fondness for terrible names.  This
process does the following things:

- Applies customizable faces to text surrounded by emphasis
  characters * and _.  The default faces for these are bold and
  italic, respectively, because that's what the GNU-hosted HTML
  versions of the Emacs manuals use, but they can be customized to
  suit your taste.

- Identifies Emacs Lisp code samples and fontifies them
  accordingly.

- Identifies references in `ticks', and where they refer to
  function or variable bindings, applies the necessary text
  properties to link them to the relevant documentation.  References
  without a corresponding function or variable binding will be
  fontified as Emacs Lisp, by the same method used for code
  samples.

- Identifies headers for longer-form documentation of several types
  of objects, such as: "-- Function: find-file filename &optional
  wildcards" and applies text properties making them easier to
  identify and parse.  Names for documented things are linked to
  their documentation in the same way as for references in
  `ticks'.  Functions' argument lists are additionally fontified
  with a customizable face, which defaults to italic.

Each kind of niceification has a corresponding customization option
to enable or disable it.  You can easily access these via M-x
customize-group RET niceify-info RET, or as a subgroup of the Info
customization group.  The faces used for emphases, and for function
argument lists in headers, can also be customized.
