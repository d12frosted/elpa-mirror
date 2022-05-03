GNU Global integration with xref, project, completion-at-point
(capf) and imenu.

There are many other packages with their own approach and set of
more complete/complex features, maps and functionalities; like
ggtags, gtags.el, gxref, agtags and some others referenced in:
https://www.gnu.org/software/global/links.html

This package let all the work to the EMACS tools available for such
functions and avoids external dependencies.  Unlike the other
packages; this module does not create extra special maps, bindings
or menus, but just adds support to the mentioned features to use
gtags/global as a backend when possible.  We do special emphasis on
minimalism, simplicity, efficiency and tramp support.

This package may be extended in the future with new features and to
support other tools, but only if they are required and included in
an EMACS distribution and don't need external dependencies.