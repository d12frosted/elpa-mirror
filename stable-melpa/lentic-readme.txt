`lentic' enables /lenticular text/: simultaneous editing and viewing of the
same (or closely related) text in two or more buffers, potentially in
different modes. Lenticular text is named after lenticular printing, which
produce images which change depending on the angle at which they are
viewed.

Sometimes, it would be nice to edit a file in two ways at once. For
instance, you might have a source file in a computational language with
richly marked documentation. As Emacs is a modal editor, it would be nice
to edit this file both in a mode for the computational language and for the
marked up documentation.

One solution to this is to use a single-mode which supports both types of
editing. The problem with this is that it is fundamentally difficult to
support two types of editing at the same time; more over, you need a new
mode for each combination. Another solution is to use one of the
multiple-mode tools which are available. The problem with this is that they
generally need some support from the modes in question. And, again, the
difficulty is supporting both forms of editing in the same environment. A
final problem is that it is not just the editing environment that needs to
be adapted; the programmatic environment needs to be untroubled by the
documentation, and the documentation environment untroubled by the program
code.

Lenticular text provides an alternative solution. Two lentic buffers, by
default, the share content but are otherwise independent. Therefore,
you can have two buffers open, each showing the content in different modes;
to switch modes, you simply switch buffers. The content, location of point,
and view are shared.

Moreover, lentic buffers can also perform a bi-directional transformation
between the two. If this is done, then the two can have different but
related text. This also solves the problem of integration with a
tool-chain; each lentic buffer can be associated with a different file and
a different syntax. For example, this file is, itself, lenticular text. It
can be viewed either as Emacs-Lisp or in Org-Mode. In Emacs-Lisp mode, this
text is commented out, in org-mode it is not.

In fact, although the default behaviour of lentic appears to keep the same
text in each buffer, even it uses this bi-directional transformation
capability; while the text is shared, the text properties are not. This is
a behaviour which differs between lentic buffers and indirect buffers. The
lentic buffers can therefore be in different modes without fighting each
other to set the text properties.

It is possible to configure the transformation for any two buffers in a
extensible way. Mostly I have concentrated on mode-specific operation,
but, for instance, I have also used this ability on a per-project basis
controlling, for instance, the location of the lentic-file.
