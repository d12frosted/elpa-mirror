This package converts the buffer text and the associated
decorations to HTML.  Mail to <hniksic@gmail.com> to discuss
features and additions.  All suggestions are more than welcome.

To use it, just switch to the buffer you want HTML-ized and type
`M-x htmlize-buffer'.  You will be switched to a new buffer that
contains the resulting HTML code.  You can edit and inspect this
buffer, or you can just save it with C-x C-w.  `M-x htmlize-file'
will find a file, fontify it, and save the HTML version in
FILE.html, without any additional intervention.  `M-x
htmlize-many-files' allows you to htmlize any number of files in
the same manner.  `M-x htmlize-many-files-dired' does the same for
files marked in a dired buffer.

htmlize supports three types of HTML output, selected by setting
`htmlize-output-type': `css', `inline-css', and `font'.  In `css'
mode, htmlize uses cascading style sheets to specify colors; it
generates classes that correspond to Emacs faces and uses <span
class=FACE>...</span> to color parts of text.  In this mode, the
produced HTML is valid under the 4.01 strict DTD, as confirmed by
the W3C validator.  `inline-css' is like `css', except the CSS is
put directly in the STYLE attribute of the SPAN element, making it
possible to paste the generated HTML into existing HTML documents.
In `font' mode, htmlize uses <font color="...">...</font> to
colorize HTML, which is not standard-compliant, but works better in
older browsers.  `css' mode is the default.

You can also use htmlize from your Emacs Lisp code.  When called
non-interactively, `htmlize-buffer' and `htmlize-region' will
return the resulting HTML buffer, but will not change current
buffer or move the point.  htmlize will do its best to work on
non-windowing Emacs sessions but the result will be limited to
colors supported by the terminal.

htmlize aims for compatibility with older Emacs versions.  Please
let me know if it doesn't work on the version of GNU Emacs that you
are using.  The package relies on the presence of CL extensions;
please don't try to remove that dependency.  I see no practical
problems with using the full power of the CL extensions, except
that one might learn to like them too much.

The latest version is available at:

       <https://github.com/hniksic/emacs-htmlize>
       <https://code.orgmode.org/mirrors/emacs-htmlize>


Thanks go to the many people who have sent reports and contributed
comments, suggestions, and fixes.  They include Ron Gut, Bob
Weiner, Toni Drabik, Peter Breton, Ville Skytta, Thomas Vogels,
Juri Linkov, Maciek Pasternacki, and many others.

User quotes: "You sir, are a sick, sick, _sick_ person. :)"
                 -- Bill Perry, author of Emacs/W3
